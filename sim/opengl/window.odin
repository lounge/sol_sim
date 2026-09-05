package main

import sim "../core"

import "core:fmt"
import "core:math"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"

SCR_WIDTH :: 800
SCR_HEIGHT :: 600

RES_DIR :: #directory + "res/"


Renderer :: struct {
	body_program:       Body_Program,
	trail_program:      Trail_Program,
	composite_program:  Composite_Program,
	brightness_program: Brightness_Program,
	blur_program:       Blur_Program,
	sphere_mesh:        Mesh,
	trail_mesh:         Mesh,
	textures:           Textures,
	empty_vao:          u32,
	target_scene:       Render_Target,
	target_brightness:  Render_Target,
	target_blur:        [2]Render_Target, // ping-pong guarantees source != dest
	fb_width:           i32,
	fb_height:          i32,
}

window_create :: proc(state: ^State) -> glfw.WindowHandle {
	glfw.Init()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, TITLE, nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		glfw.Terminate()
		os.exit(-1)
	}

	glfw.SetWindowUserPointer(window, state)

	glfw.SetFramebufferSizeCallback(window, callback_framebuffer_size)
	glfw.SetScrollCallback(window, callback_scroll)
	glfw.SetMouseButtonCallback(window, callback_click)
	glfw.SetKeyCallback(window, callback_key)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	gl.Enable(gl.DEPTH_TEST)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	gl.ClearColor(0.0, 0.0, 0.0, 0.0)

	return window
}

state_get :: proc "contextless" (window: glfw.WindowHandle) -> ^State {
	return (^State)(glfw.GetWindowUserPointer(window))
}

renderer_create :: proc(fb_width, fb_height: i32) -> Renderer {
	r := Renderer {
		body_program       = body_program_load(
			shader_build("body", "body.vert.glsl", "body.frag.glsl"),
		),
		trail_program      = trail_program_load(
			shader_build("trail", "trail.vert.glsl", "trail.frag.glsl"),
		),
		composite_program  = composite_program_load(
			shader_build("composite", "fullscreen.vert.glsl", "composite.frag.glsl"),
		),
		brightness_program = brightness_program_load(
			shader_build("brightness", "fullscreen.vert.glsl", "brightness.frag.glsl"),
		),
		blur_program       = blur_program_load(
			shader_build("blur", "fullscreen.vert.glsl", "blur.frag.glsl"),
		),
		sphere_mesh        = sphere_mesh_create(16, 32),
		trail_mesh         = trail_mesh_create(),
		textures           = texture_create(),
	}

	gl.GenVertexArrays(1, &r.empty_vao)

	half_width, half_height := renderer_half(fb_width, fb_height)
	r.target_scene = render_target_create(fb_width, fb_height, true)
	r.target_brightness = render_target_create(half_width, half_height, false)
	r.target_blur[0] = render_target_create(half_width, half_height, false)
	r.target_blur[1] = render_target_create(half_width, half_height, false)
	r.fb_width, r.fb_height = fb_width, fb_height

	gl.Viewport(0, 0, fb_width, fb_height)

	return r
}

renderer_begin_frame :: proc(r: ^Renderer, fb_width, fb_height: i32) {
	half_width, half_height := renderer_half(fb_width, fb_height)
	render_target_resize(&r.target_scene, fb_width, fb_height)
	render_target_resize(&r.target_brightness, half_width, half_height)
	render_target_resize(&r.target_blur[0], half_width, half_height)
	render_target_resize(&r.target_blur[1], half_width, half_height)
	r.fb_width, r.fb_height = fb_width, fb_height

	gl.BindFramebuffer(gl.FRAMEBUFFER, r.target_scene.fbo)
	gl.Viewport(0, 0, fb_width, fb_height)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

renderer_draw_scene :: proc(
	r: ^Renderer,
	state: ^State,
	bodies: []sim.Body,
	trails: []sim.Trail,
	camera_frame: Camera_Frame,
	alpha: f64,
	render_time: f64,
	measure: ^Measure,
) {
	when sim.MEASURE {
		t0 := glfw.GetTime()
	}

	if state.input.wireframe_mode do gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	bodies_draw(
		bodies,
		r.sphere_mesh,
		&r.textures,
		r.body_program,
		camera_frame,
		r.fb_height,
		alpha,
		render_time,
	)

	if state.input.wireframe_mode do gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

	when sim.MEASURE {
		measure.bodies_seconds += glfw.GetTime() - t0
	}

	if !state.input.hide_trails {
		when sim.MEASURE {
			t1 := glfw.GetTime()
		}

		trails_draw(trails, bodies, r.trail_mesh, r.trail_program, camera_frame, alpha)

		when sim.MEASURE {
			measure.trails_seconds += glfw.GetTime() - t1
		}
	}
}

renderer_end_frame :: proc(r: ^Renderer) {
	brightness_draw(&r.target_scene, &r.target_brightness, &r.brightness_program, r.empty_vao)
	bloom := bloom_blur(
		&r.target_brightness,
		&r.target_blur,
		&r.blur_program,
		r.empty_vao,
		BLOOM_ITERATIONS,
	)

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Viewport(0, 0, r.fb_width, r.fb_height)

	composite_draw(&r.target_scene, bloom, &r.composite_program, r.empty_vao)
}

@(private = "file")
renderer_half :: proc(width, height: i32) -> (i32, i32) {
	return math.max(1, width / 2), math.max(1, height / 2)
}

@(private = "file")
shader_build :: proc(name, vert, frag: string) -> u32 {
	program, ok := gl.load_shaders_file(
		fmt.tprintf("%s%s", RES_DIR, vert),
		fmt.tprintf("%s%s", RES_DIR, frag),
	)
	if !ok {
		fmt.printfln("Failed to load and build %s shaders", name)
		os.exit(-1)
	}

	return program
}

@(private = "file")
callback_framebuffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
