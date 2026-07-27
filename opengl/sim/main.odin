package main

import gl "vendor:OpenGL"

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:os"
import "vendor:glfw"

SCR_WIDTH :: 800
SCR_HEIGHT :: 600
SECONDS_IN_DAY :: 86400
SECONDS_IN_YEAR :: 3.156e7
T_UNIT_SECONDS :: SECONDS_IN_YEAR / (2 * math.PI) // ≈5.023e6, the G=1/AU/solar-mass time unit
MAX_SIM_SPEED :: #config(MAX_SIM_SPEED, int(15 * SECONDS_IN_YEAR))

palette := realistic.body

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

	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	glfw.SetScrollCallback(window, scroll_callback)
	glfw.SetMouseButtonCallback(window, click_callback)
	glfw.SetKeyCallback(window, key_callback)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, fb_width, fb_height)

	body_program, body_loaded_ok := gl.load_shaders_file(#directory + "res/body.vert.glsl", #directory + "res/body.frag.glsl")
	if !body_loaded_ok {
		os.exit(-1)
	}

	trail_program, trail_loaded_ok := gl.load_shaders_file(#directory + "res/trail.vert.glsl", #directory + "res/trail.frag.glsl")
	if !trail_loaded_ok {
		os.exit(-1)
	}

	circle_mesh := create_circle_mesh(32)
	trail_mesh := create_trail_mesh()

	accumulator: f64
	last_time := glfw.GetTime()
	for !glfw.WindowShouldClose(window) {
		fb_width, fb_height := glfw.GetFramebufferSize(window)
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
		apply_pending_delete(&state, &bodies, &trails)
		apply_pending_edits(&state, bodies[:])
		apply_pending_spawn(&state, &bodies, &trails,  window_width, window_height)

		// Drain loop
		for accumulator >= DT {
			physics_step(bodies[:], DT)
			record_trail(bodies[:], trails[:])
			accumulator -= DT
		}

		alpha := accumulator / DT

		camera_update(&state, bodies[:], window_width, window_height, alpha)

		draw_bodies(bodies[:], circle_mesh, body_program, &state.camera, fb_width, fb_height, alpha)
		draw_trails(trails[:], bodies[:], trail_mesh, trail_program, &state.camera, fb_width, fb_height, alpha)

		if drag, ok := state.input.drag_start.?; ok {
			start_pos := drag
			end_x, end_y := glfw.GetCursorPos(window)
			end_world := draw_drag_preview(start_pos, {end_x, end_y}, trail_mesh, trail_program, &state.camera, window_width, window_height)

			_, radius := spawn_mass_radius(state.input.spawn_mass_exp);

			draw_mass_preview(end_world, radius, palette.Spawn, circle_mesh, body_program, &state.camera, fb_width, fb_height)
		}

		update_window_title(window, &state, bodies[:])

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		free_all(context.temp_allocator)
	}

	glfw.Terminate()
}

update_window_title :: proc (window: glfw.WindowHandle, state: ^State, bodies: []Body) {
	@(static) prev_tracked_body := -2
	@(static) prev_sim_speed := -1
	title: cstring

	if drag, ok := state.input.drag_start.?; ok {
		end_x, end_y := glfw.GetCursorPos(window)
		width, height := glfw.GetWindowSize(window)
		start_world := calc_world_pos(drag, &state.camera, width, height)
		end_world := calc_world_pos({end_x, end_y}, &state.camera, width, height)

		speed := linalg.length(end_world - start_world) / DRAG_TIME
		mass, _ := spawn_mass_radius(state.input.spawn_mass_exp)

		title = fmt.ctprintf("%s - Spawn %e sol (x%.0f Moon) - %.1f km/s", "Sol_Sim", mass, math.pow(2, state.input.spawn_mass_exp), speed * 29.78)
		glfw.SetWindowTitle(window, title)

		prev_sim_speed = -1
		return
	}

	if state.camera.tracked_body == prev_tracked_body && state.sim_speed == prev_sim_speed do return
	if state.camera.tracked_body >= 0 {
		tracked_body_name := bodies[state.camera.tracked_body].name
		title = fmt.ctprintf("%s - %s - %d days/sec - %f years/sec - sim_speed %d", "Sol_Sim", tracked_body_name, state.sim_speed / SECONDS_IN_DAY, f64(state.sim_speed) / SECONDS_IN_YEAR, state.sim_speed)
	} else {
		title = fmt.ctprintf("%s - %d days/sec - %f years/sec - sim_speed %d", "Sol_Sim", state.sim_speed / SECONDS_IN_DAY, f64(state.sim_speed) / SECONDS_IN_YEAR, state.sim_speed)
	}

	glfw.SetWindowTitle(window, title)

	prev_tracked_body = state.camera.tracked_body
	prev_sim_speed = state.sim_speed
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

get_state :: proc "contextless" (window: glfw.WindowHandle) -> ^State {
	state := (^State)(glfw.GetWindowUserPointer(window))
	return state
}
