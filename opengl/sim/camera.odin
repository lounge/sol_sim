package main

import "core:math"

camera := Camera {{0, 0}, 1.1, -1}

Camera :: struct {
	center: [2]f64,
	half_extent: f64,
	tracked_body: int
}

camera_zoom :: proc "contextless" (yOffset: f64) {
	camera.half_extent *= math.pow(0.9, yOffset)
}

camera_update :: proc(bodies: []Body) {
	if camera.tracked_body >= 0 {
		camera.center = bodies[camera.tracked_body].pos
	}
}

camera_track :: proc(index: int, body: Body) {
	if index == camera.tracked_body do return
	camera.tracked_body = index
	camera.half_extent = body.radius * VIEW_SCALE
}
