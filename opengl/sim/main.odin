package main

import gl "vendor:OpenGL"

import "core:c"
import "core:fmt"
import "core:os"
import "core:math"
import "vendor:glfw"

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}

DT :: 0.0001
SCR_WIDTH :: 800
SCR_HEIGHT :: 600

main :: proc() {
	bodies: [dynamic]Body

	sun := Body {
		{0.0, 0.0},
		{0.0, 0.0},
		1.0,
		0.15
	}

	earth_orbit_r: f64 = 1
	earth_init_vel := math.sqrt(G * sun.mass / earth_orbit_r)
	earth := Body {
		{earth_orbit_r, 0.0},
		{0.0, earth_init_vel},
		3.003 * math.pow10(f64(-6.0)),
		0.05
	}

	moon_orbit_r: f64 =  2.570 * math.pow10(f64(-3))
	moon_init_vel := math.sqrt(G * earth.mass / moon_orbit_r)
	moon := Body {
		earth.pos + {moon_orbit_r, 0.0},
		earth.vel + {0.0, moon_init_vel},
		3.69 * math.pow10(f64(-8.0)),
		0.02
	}

	sun.vel = -(earth.vel * earth.mass + moon.vel * moon.mass) / sun.mass

	append(&bodies, sun, earth, moon)

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

	glfw.MakeContextCurrent(window)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, fb_width, fb_height)

	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	shader_program, loaded_ok := gl.load_shaders_file(#directory + "res/vertex.vert.glsl", #directory + "res/fragment.frag.glsl")
	if !loaded_ok {
		os.exit(-1)
	}

	circle_mesh := create_circle_mesh(32)

	for !glfw.WindowShouldClose(window) {
		process_input(window)

		fb_width, fb_height := glfw.GetFramebufferSize(window)

		gl.ClearColor(0.0, 0.0, 0.0, 0.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)

		// Physics step
		STEPS_PER_FRAME :: 10
		for _ in 0..< STEPS_PER_FRAME {
			physics_step(bodies[:], DT)
		}

		// Draw bodies
		draw_bodies(bodies[:], circle_mesh, shader_program, fb_width, fb_height)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	glfw.Terminate()
}
