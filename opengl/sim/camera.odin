package main

import "core:math"

VIEW_SCALE :: 60
PICK_RADIUS_PX :: 8

Camera :: struct {
	center:       [2]f64,
	half_extent:  f64,
	tracked_body: int,
}

camera_zoom :: proc "contextless" (camera_state: ^Camera, yOffset: f64) {
	camera_state.half_extent *= math.pow(0.9, yOffset)
}

camera_update :: proc(state: ^State, bodies: []Body, width, height: i32, alpha: f64) {
	if state.camera.tracked_body >= 0 {
		world := pos_render(bodies[state.camera.tracked_body], alpha)
		state.camera.center = world
	}

	if click, ok := state.input.pending_click.?; ok {
		state.input.pending_click = nil

		best := -1
		best_dist := math.INF_F64
		for body, i in bodies {
			// Forward transform chain -> World -> Screen
			world := pos_render(body, alpha)
			screen := screen_pos_calc(World_Pos(world), &state.camera, width, height)
			diff := screen - click
			dist := math.sqrt(diff.x * diff.x + diff.y * diff.y)

			marker_px := ndc_scale_calc(body.radius, height, &state.camera) * f64(height) / 2
			if dist < max(marker_px, PICK_RADIUS_PX) && dist < best_dist {
				best = i
				best_dist = dist
			}
		}

		if best >= 0 {
			camera_track(state, best, bodies[best])
		} else {
			state.camera.tracked_body = -1 // empty space -> free cam
			state.title_stale = true
		}
	}
}

camera_track :: proc(state: ^State, index: int, body: Body) {
	if index == state.camera.tracked_body do return
	state.camera.tracked_body = index
	state.camera.half_extent = body.radius * VIEW_SCALE
	state.title_stale = true
}
