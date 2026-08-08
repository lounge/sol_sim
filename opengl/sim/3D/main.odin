package main

import sim "../core"

import "core:math"
import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"

#assert(sim.DIM == 3)

TITLE :: "Sol_Sim 3D"
SCR_WIDTH :: 800
SCR_HEIGHT :: 600
SECONDS_IN_DAY :: 86400
SECONDS_IN_YEAR :: 3.156e7
T_UNIT_SECONDS :: SECONDS_IN_YEAR / (2 * math.PI) // ≈5.023e6, the G=1/AU/solar-mass time unit

TOTAL_STEPS :: #config(TOTAL_STEPS, 0) // > 0 = headless runner, no window
MAX_SIM_SPEED :: #config(MAX_SIM_SPEED, int(50 * SECONDS_IN_YEAR))
PHYSICS_BUDGET :: #config(PHYSICS_BUDGET, 0.005) // Seconds of wall clock per frame
GOVERNOR_FRAMES :: #config(GOVERNOR_FRAMES, 30) // COnsecutive overloaded frames before halving

main :: proc() {
	gravity_tree: sim.Gravity_Tree
	bodies, trails := sim.create_system(&gravity_tree)

	when sim.DETERMINISM_STEPS > 0 {
		sim.determinism_dump(&bodies, &trails, &gravity_tree)
		return
	}

	when sim.MEASURE {
		measure: sim.Measure
		sim.measure_spawn(&bodies, &trails, &gravity_tree)
	}

	when TOTAL_STEPS > 0 {
		run_headless_sim(&bodies, &trails, &gravity_tree)
		return
	}

	glfw.Init()
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, TITLE, nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		glfw.Terminate()
		os.exit(-1)
	}

	state := state_init()
	glfw.SetWindowUserPointer(window, &state)

	// TODO: Set other callbacks
	glfw.SetMouseButtonCallback(window, callback_click)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	gl.Enable(gl.DEPTH_TEST)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, fb_width, fb_height)

	body_prg, body_loaded_ok := gl.load_shaders_file(
		#directory + "res/body.vert.glsl",
		#directory + "res/body.frag.glsl",
	)
	if !body_loaded_ok {
		fmt.println("Failed to load and build body shaders")
		os.exit(-1)
	}

	trail_prg, trail_loaded_ok := gl.load_shaders_file(
		#directory + "res/trail.vert.glsl",
		#directory + "res/trail.frag.glsl",
	)
	if !trail_loaded_ok {
		fmt.println("Failed to load and build trail shaders")
		os.exit(-1)
	}

	body_program := body_program_load(body_prg)
	trail_program := trail_program_load(trail_prg)

	// TODO: Create meshs?

	accumulator: f64
	overload_frames: int
	last_time := glfw.GetTime()

	gl.ClearColor(0.0, 0.0, 0.0, 0.0)

	for !glfw.WindowShouldClose(window) {
		fb_width, fb_height = glfw.GetFramebufferSize(window)
		window_width, window_height := glfw.GetWindowSize(window)

		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		now := glfw.GetTime()
		frame_time := now - last_time
		frame_time = min(frame_time, 0.1)
		last_time = now
		accumulator += frame_time * f64(state.sim_speed) / T_UNIT_SECONDS

		// TODO: Apply interactions

		when sim.MEASURE {
			measure_t0 := glfw.GetTime()
		}

		when sim.BH_DEBUG {
			sim.gravity_tree_debug(&gravity_tree, bodies[:], now)
		}

		// Physics step
		deadline := glfw.GetTime() + PHYSICS_BUDGET
		steps: int
		for accumulator >= sim.DT {
			// Drain loop
			when sim.MEASURE {
				measure_c0 := glfw.GetTime()
			}
			for {
				pair, collision := sim.collision_compute(bodies[:], &gravity_tree)
				if !collision do break
				sim.collision_merge(pair, &bodies, &trails, &state.tracked_body, &gravity_tree)
				state.title_stale = true
			}
			when sim.MEASURE {
				measure.collision_seconds += glfw.GetTime() - measure_c0
			}

			sim.physics_step(bodies[:], sim.DT, &gravity_tree)
			sim.trail_record(bodies[:], trails[:])

			accumulator -= sim.DT
			steps += 1
			if glfw.GetTime() >= deadline do break
		}

		when sim.MEASURE {
			measure.physics_seconds += glfw.GetTime() - measure_t0
			measure.steps += steps
		}

		overloaded := accumulator >= sim.DT
		if overloaded {
			accumulator = math.mod(accumulator, sim.DT)
			overload_frames += 1
		} else {
			overload_frames = 0
		}

		if overload_frames >= GOVERNOR_FRAMES {
			state.sim_speed = math.max(1, state.sim_speed / 2)
			state.title_stale = true
			overload_frames = 0
		}

		alpha := accumulator / sim.DT

		// TODO: Camera update

		// TODO: Draw tree cells

		when sim.MEASURE {
			measure_t0 = glfw.GetTime()
		}

		// TODO: bodies_draw()

		when sim.MEASURE {
			measure.bodies_seconds += glfw.GetTime() - measure_t0
		}

		when sim.MEASURE {
			measure_t0 = glfw.GetTime()
		}

		// TODO:  trails_draw()

		when sim.MEASURE {
			measure.trails_seconds += glfw.GetTime() - measure_t0
			sim.measure_frame_report(&measure, trails[:], glfw.GetTime())
		}

		// TODO: Drag preview draw

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		gl_check_error()

		free_all(context.temp_allocator)
	}

	return
}


callback_framebuffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

state_get :: proc "contextless" (window: glfw.WindowHandle) -> ^State {
	state := (^State)(glfw.GetWindowUserPointer(window))
	return state
}
