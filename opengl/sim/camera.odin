package main

import "core:math"

VIEW_SCALE :: 60
PICK_RADIUS_PX :: 8

Camera :: struct {
	center: [2]f64,
	half_extent: f64,
	tracked_body: int,
}

camera_zoom :: proc "contextless" (camera_state: ^Camera, yOffset: f64) {
	camera_state.half_extent *= math.pow(0.9, yOffset)
}

camera_update :: proc(state: ^State,  bodies: []Body, width, height: i32, alpha: f64) {
	if state.camera.tracked_body >= 0 {
		world := render_pos(bodies[state.camera.tracked_body], alpha)
		state.camera.center = world
	}

	if click, ok := state.input.pending_click.?; ok {
		state.input.pending_click = nil

		best := -1
		best_dist := math.INF_F64
		for body, i in bodies {
			// Forward transform chain -> World -> Screen
			world := render_pos(body, alpha)
			screen := calc_screen_pos(World_Pos(world), &state.camera, width, height)
			diff := screen - click
			dist := math.sqrt(diff.x * diff.x + diff.y * diff.y)

			marker_px := calc_ndc_scale(body.radius, height, &state.camera) * f64(height) / 2
			if dist < max(marker_px, PICK_RADIUS_PX) && dist < best_dist {
				best = i
				best_dist = dist
			}
		}

		if best >= 0 {
			camera_track(&state.camera, best, bodies[best])
		} else {
			state.camera.tracked_body = -1 // empty space -> free cam
		}
	}
}

camera_track :: proc(camera_state: ^Camera, index: int, body: Body) {
	if index == camera_state.tracked_body do return
	camera_state.tracked_body = index
	camera_state.half_extent = body.radius * VIEW_SCALE
}
