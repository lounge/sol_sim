package main

import "core:math"

camera := Camera {{0, 0}, 1.1, -1, nil}

Camera :: struct {
	center: [2]f64,
	half_extent: f64,
	tracked_body: int,
	pending_click: Maybe([2]f64)
}

camera_zoom :: proc "contextless" (yOffset: f64) {
	camera.half_extent *= math.pow(0.9, yOffset)
}

camera_update :: proc(bodies: []Body, width, height: i32) {

	if camera.tracked_body >= 0 {
		camera.center = bodies[camera.tracked_body].pos
	}

	if click, ok := camera.pending_click.?; ok {
		camera.pending_click = nil

		best := -1
		best_dist := math.INF_F64
		for body, i in bodies {
			// Forward transform chain -> World -> Screen
			screen := calc_screen_pos(body.pos, camera, width, height)
			diff := screen - click
			dist := math.sqrt(diff.x * diff.x + diff.y * diff.y)

			marker_px := calc_ndc_scale(body.radius, height, camera) * f64(height) / 2
			if dist < max(marker_px, PICK_RADIUS_PX) && dist < best_dist {
				best = i
				best_dist = dist
			}
		}

		if best >= 0 {
			camera_track(best, bodies[best])
		} else {
			camera.tracked_body = -1 // empty space -> free cam
		}
	}
}

camera_track :: proc(index: int, body: Body) {
	if index == camera.tracked_body do return
	camera.tracked_body = index
	camera.half_extent = body.radius * VIEW_SCALE
}
