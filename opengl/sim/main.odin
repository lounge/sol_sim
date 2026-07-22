package main

import gl "vendor:OpenGL"

import "core:c"
import "core:fmt"
import "core:os"
import "vendor:glfw"

DT :: 0.0001
SCR_WIDTH :: 800
SCR_HEIGHT :: 600
VIEW_SCALE :: 60
MIN_MARKER_PX :: 4
TRAIL_CAP :: 12800
TRAIL_FRACTION :: 0.95
STEPS_PER_FRAME :: 10


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
		process_input(window, bodies[:])

		fb_width, fb_height := glfw.GetFramebufferSize(window)

		gl.ClearColor(0.0, 0.0, 0.0, 0.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)

		// Physics step
		for _ in 0..< STEPS_PER_FRAME {
			physics_step(bodies[:], DT)
		}

		camera_update(bodies[:])
		draw_bodies(bodies[:], circle_mesh, shader_program, camera, fb_width, fb_height)

		record_trail(bodies[:], trails[:])
		draw_trails(trails[:], bodies[:], trail_mesh, shader_program, camera, fb_width, fb_height)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	glfw.Terminate()
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xOffset, yOffset: f64) {
	camera_zoom(yOffset)
}

process_input :: proc(window: glfw.WindowHandle, bodies: []Body) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}

	for &body, i in bodies {
		if glfw.GetKey(window, i32(glfw.KEY_1 + i)) == glfw.PRESS {
			camera_track(i, body)
		}
	}
}
