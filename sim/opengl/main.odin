package main

import sim "../core"

import "core:math"
import "vendor:glfw"

TOTAL_STEPS :: #config(TOTAL_STEPS, 0) // > 0 = headless runner, no window

main :: proc() {
	start_jd := start_jd_resolve()

	gravity_tree: sim.Gravity_Tree
	bodies, trails := sim.create_system(&gravity_tree, min(clock_delta_t(start_jd), 0))
	clock := clock_start(start_jd, &bodies, &trails, &gravity_tree)

	measure: Measure
	when sim.MEASURE {
		sim.measure_spawn(&bodies, &trails, &gravity_tree)
	}

	when sim.DETERMINISM_STEPS > 0 {
		sim.determinism_dump(&bodies, &trails, &gravity_tree)
		return
	}

	when TOTAL_STEPS > 0 {
		run_headless_sim(&bodies, &trails, &gravity_tree)
		return
	}

	state := state_init()
	window := window_create(&state)
	defer glfw.Terminate()

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	renderer := renderer_create(fb_width, fb_height)

	prev_cursor: [2]f64
	last_time := glfw.GetTime()
	last_shown_minute: int

	for !glfw.WindowShouldClose(window) {
		fb_width, fb_height = glfw.GetFramebufferSize(window)
		window_width, window_height := glfw.GetWindowSize(window)
		renderer_begin_frame(&renderer, fb_width, fb_height)

		now := glfw.GetTime()
		frame_time := min(now - last_time, 0.1)
		last_time = now
		clock_advance(&clock, frame_time, state.sim_speed)

		when sim.BH_DEBUG {
			sim.gravity_tree_debug(&gravity_tree, bodies[:], now)
		}

		_, merged := clock_drain(
			&clock,
			&bodies,
			&trails,
			&state.tracked_body,
			&gravity_tree,
			state.time_reversed,
			&measure,
		)
		if merged do state.title_stale = true

		current_jd := clock_jd(clock)
		if clock_settle(&clock) {
			state.sim_speed = math.max(1, state.sim_speed / 2)
			state.title_stale = true
		}

		alpha := clock_alpha(clock)
		render_time := clock_render_time(clock, state.time_reversed)

		cx, cy := glfw.GetCursorPos(window)
		camera_update(&state, {cx, cy}, &prev_cursor, bodies[:], alpha)

		camera_frame := Camera_Frame {
			eye  = camera_eye(state.camera),
			view = camera_view(state.camera),
			proj = camera_projection(state.camera, f64(fb_width) / f64(fb_height)),
		}

		pending_delete_apply(&state, &bodies, &trails, &gravity_tree)
		pending_spawn_apply(&state, &bodies, &trails, window_width, window_height, &gravity_tree)
		pending_edits_apply(&state, bodies[:], &gravity_tree)
		pending_click_apply(&state, bodies[:], alpha, camera_frame, window_width, window_height)

		renderer_draw_scene(
			&renderer,
			&state,
			bodies[:],
			trails[:],
			camera_frame,
			alpha,
			render_time,
			&measure,
		)

		when sim.MEASURE {
			sim.measure_frame_report(&measure, trails[:], glfw.GetTime())
		}

		when sim.BH_DEBUG_DRAW {
			gravity_tree_cells_draw(
				&gravity_tree,
				renderer.trail_mesh,
				renderer.trail_program,
				camera_frame,
			)
		}


		// Title
		shown_minute := int(math.floor((current_jd + 0.5) * 1440))
		if shown_minute != last_shown_minute {
			last_shown_minute = shown_minute
			state.title_stale = true
		}

		if drag, ok := state.input.drag_start.?; ok {
			cursor: Pixel_Pos = {cx, cy}

			a, b, preview_ok := drag_preview_pass(
				&state,
				cursor,
				drag,
				renderer.trail_mesh,
				renderer.sphere_mesh,
				renderer.trail_program,
				renderer.body_program,
				camera_frame,
				window_width,
				window_height,
				fb_height,
				renderer.textures.fallback,
			)

			if preview_ok {
				window_title_drag_update(window, &state, a, b)
			}
		} else {
			window_title_update(window, &state, bodies[:], sim.date_from_jd(current_jd))
		}

		// post chain
		renderer_end_frame(&renderer)

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		gl_check_error()

		free_all(context.temp_allocator)
	}
}
