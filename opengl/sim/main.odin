package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"

SCR_WIDTH :: 800
SCR_HEIGHT :: 600
SECONDS_IN_DAY :: 86400
SECONDS_IN_YEAR :: 3.156e7
T_UNIT_SECONDS :: SECONDS_IN_YEAR / (2 * math.PI) // ≈5.023e6, the G=1/AU/solar-mass time unit
MAX_SIM_SPEED :: #config(MAX_SIM_SPEED, int(15 * SECONDS_IN_YEAR))

PALETTE :: REALISTIC.body

main :: proc() {
	bodies, trails := create_system()

	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, "Sol_Sim", nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		glfw.Terminate()
		os.exit(-1)
	}

	state := state_init()
	glfw.SetWindowUserPointer(window, &state)

	glfw.SetFramebufferSizeCallback(window, callback_framebuffer_size)
	glfw.SetScrollCallback(window, callback_scroll)
	glfw.SetMouseButtonCallback(window, callback_click)
	glfw.SetKeyCallback(window, callback_key)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, fb_width, fb_height)

	body_program, body_loaded_ok := gl.load_shaders_file(
		#directory + "res/body.vert.glsl",
		#directory + "res/body.frag.glsl",
	)
	if !body_loaded_ok {
		fmt.println("Failed to load and build body shaders")
		os.exit(-1)
	}

	trail_program, trail_loaded_ok := gl.load_shaders_file(
		#directory + "res/trail.vert.glsl",
		#directory + "res/trail.frag.glsl",
	)
	if !trail_loaded_ok {
		fmt.println("Failed to load and build trail shaders")
		os.exit(-1)
	}

	circle_mesh := circle_mesh_create(32)
	trail_mesh := trail_mesh_create()

	accumulator: f64
	last_time := glfw.GetTime()
	for !glfw.WindowShouldClose(window) {
		fb_width, fb_height = glfw.GetFramebufferSize(window)
		window_width, window_height := glfw.GetWindowSize(window)

		gl.ClearColor(0.0, 0.0, 0.0, 0.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Physics step
		now := glfw.GetTime()
		frame_time := now - last_time
		frame_time = min(frame_time, 0.1)
		last_time = now
		accumulator += frame_time * f64(state.sim_speed) / T_UNIT_SECONDS

		// Apply interaction
		pending_delete_apply(&state, &bodies, &trails)
		pending_edits_apply(&state, bodies[:])
		pending_spawn_apply(&state, &bodies, &trails, window_width, window_height)

		// Drain loop
		for accumulator >= DT {
			physics_step(bodies[:], DT)
			trail_record(bodies[:], trails[:])
			accumulator -= DT
		}

		alpha := accumulator / DT

		camera_update(&state, bodies[:], window_width, window_height, alpha)

		bodies_draw(
			bodies[:],
			circle_mesh,
			body_program,
			&state.camera,
			fb_width,
			fb_height,
			alpha,
		)
		trails_draw(
			trails[:],
			bodies[:],
			trail_mesh,
			trail_program,
			&state.camera,
			fb_width,
			fb_height,
			alpha,
		)

		if drag, ok := state.input.drag_start.?; ok {
			start_pos := drag
			end_x, end_y := glfw.GetCursorPos(window)
			end_world := drag_preview_draw(
				start_pos,
				{end_x, end_y},
				trail_mesh,
				trail_program,
				&state.camera,
				window_width,
				window_height,
			)

			_, radius := mass_radius_get(state.input.spawn_mass_exp)

			mass_preview_draw(
				end_world,
				radius,
				PALETTE[.Spawn],
				circle_mesh,
				body_program,
				&state.camera,
				fb_width,
				fb_height,
			)
		}

		window_title_update(window, &state, bodies[:])

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		free_all(context.temp_allocator)
	}

	glfw.Terminate()
}

window_title_update :: proc(window: glfw.WindowHandle, state: ^State, bodies: []Body) {
	title: cstring

	if drag, ok := state.input.drag_start.?; ok {
		end_x, end_y := glfw.GetCursorPos(window)
		width, height := glfw.GetWindowSize(window)
		start_world := world_pos_calc(drag, &state.camera, width, height)
		end_world := world_pos_calc({end_x, end_y}, &state.camera, width, height)

		speed := linalg.length(end_world - start_world) / DRAG_TIME
		mass, _ := mass_radius_get(state.input.spawn_mass_exp)

		title = fmt.ctprintf(
			"%s - Spawn %e sol (x%.0f Moon) - %.1f km/s",
			"Sol_Sim",
			mass,
			math.pow(2, state.input.spawn_mass_exp),
			speed * 29.78,
		)
		glfw.SetWindowTitle(window, title)

		state.title_stale = true
		return
	}

	if state.title_stale == false do return
	if state.camera.tracked_body >= 0 {
		tracked_body_name := bodies[state.camera.tracked_body].name
		title = fmt.ctprintf(
			"%s - %s - %d days/sec - %f years/sec - sim_speed %d",
			"Sol_Sim",
			tracked_body_name,
			state.sim_speed / SECONDS_IN_DAY,
			f64(state.sim_speed) / SECONDS_IN_YEAR,
			state.sim_speed,
		)
	} else {
		title = fmt.ctprintf(
			"%s - %d days/sec - %f years/sec - sim_speed %d",
			"Sol_Sim",
			state.sim_speed / SECONDS_IN_DAY,
			f64(state.sim_speed) / SECONDS_IN_YEAR,
			state.sim_speed,
		)
	}

	glfw.SetWindowTitle(window, title)
	state.title_stale = false
}

callback_framebuffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

state_get :: proc "contextless" (window: glfw.WindowHandle) -> ^State {
	state := (^State)(glfw.GetWindowUserPointer(window))
	return state
}
