package main

import gl "vendor:OpenGL"

import "core:c"
import "core:fmt"
import "core:math"
import "core:os"
import "vendor:glfw"

DT :: 0.0001
SCR_WIDTH :: 800
SCR_HEIGHT :: 600
VIEW_SCALE :: 60
MIN_MARKER_PX :: 4
TRAIL_CAP :: 12800
TRAIL_FRACTION :: 0.95
PICK_RADIUS_PX :: 8

sim_speed: int =  10

main :: proc() {
	bodies, trails := create_system()

	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "Sol_Sim", nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		glfw.Terminate()
		os.exit(-1)
	}

	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	glfw.SetScrollCallback(window, scroll_callback)
	glfw.SetMouseButtonCallback(window, click_callback)
	glfw.SetKeyCallback(window, key_callback)

	glfw.MakeContextCurrent(window)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, fb_width, fb_height)

	shader_program, loaded_ok := gl.load_shaders_file(#directory + "res/vertex.vert.glsl", #directory + "res/fragment.frag.glsl")
	if !loaded_ok {
		os.exit(-1)
	}

	circle_mesh := create_circle_mesh(32)
	trail_mesh := create_trail_mesh()


	for !glfw.WindowShouldClose(window) {
		fb_width, fb_height := glfw.GetFramebufferSize(window)
		window_width, window_height := glfw.GetWindowSize(window)

		gl.ClearColor(0.0, 0.0, 0.0, 0.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)

		// Physics step
		for _ in 0..< sim_speed {
			physics_step(bodies[:], DT)
			record_trail(bodies[:], trails[:])
		}

		camera_update(bodies[:], window_width, window_height)
		draw_bodies(bodies[:], circle_mesh, shader_program, camera, fb_width, fb_height)
		draw_trails(trails[:], bodies[:], trail_mesh, shader_program, camera, fb_width, fb_height)
		update_window_title(window, bodies[:])

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		free_all(context.temp_allocator)
	}

	glfw.Terminate()
}

update_window_title :: proc (window: glfw.WindowHandle, bodies: []Body) {
	@(static) prev_tracked_body := -2
	@(static) prev_sim_speed := -1
	title: cstring

	if camera.tracked_body == prev_tracked_body && sim_speed == prev_sim_speed do return
	if camera.tracked_body >= 0 {
		tracked_body_name := bodies[camera.tracked_body].name
		title = fmt.ctprintf("%s - %s - %dx", "Sol_Sim", tracked_body_name, sim_speed)
	} else {
		title = fmt.ctprintf("%s - %dx", "Sol_Sim", sim_speed)
	}

	glfw.SetWindowTitle(window, title)

	prev_tracked_body = camera.tracked_body
	prev_sim_speed = sim_speed
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xOffset, yOffset: f64) {
	camera_zoom(yOffset)
}

click_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
    if button == glfw.MOUSE_BUTTON_LEFT && action == glfw.RELEASE {
    	posX, posY := glfw.GetCursorPos(window)
     	camera.pending_click = [2]f64{posX, posY}
    }
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if action == glfw.PRESS || action == glfw.REPEAT {
		if key == glfw.KEY_ESCAPE {
			glfw.SetWindowShouldClose(window, true)
		}

		if key ==  glfw.KEY_LEFT {
			sim_speed = math.max(1, sim_speed / 2)
		}

		if key == glfw.KEY_RIGHT {
			sim_speed *= 2
		}
	}
}
