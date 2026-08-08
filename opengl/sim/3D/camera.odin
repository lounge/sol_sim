package main

import sim "../core"

import "core:math"
import "core:math/linalg"


CAMERA_FOV :: math.PI / 4
CAMERA_NEAR_FACTOR :: 1e-3
CAMERA_FAR_FACTOR :: 1e3
CAMERA_ELEVATION_MAX :: math.PI / 2 - 0.01

Camera :: struct {
	target:    sim.Vec,
	azimuth:   f64,
	elevation: f64,
	distance:  f64,
}

camera_eye :: proc "contextless" (camera: Camera) -> sim.Vec {
	offset :=
		camera.distance *
		[3]f64 {
				math.cos(camera.elevation) * math.cos(camera.azimuth),
				math.cos(camera.elevation) * math.sin(camera.azimuth),
				math.sin(camera.elevation),
			}
	eye := camera.target + offset
	return eye
}

camera_view :: proc "contextless" (camera: Camera) -> matrix[4, 4]f64 {
	eye := camera_eye(camera)
	view_matrix := linalg.matrix4_look_at_f64(0, camera.target - eye, {0, 0, 1})
	return view_matrix
}

camera_projection :: proc "contextless" (camera: Camera, aspect: f64) -> matrix[4, 4]f64 {
	projection := linalg.matrix4_perspective_f64(
		CAMERA_FOV,
		aspect,
		camera.distance * CAMERA_NEAR_FACTOR,
		camera.distance * CAMERA_FAR_FACTOR,
	)
	return projection
}

camera_dolly :: proc "contextless" (camera: ^Camera, y_offset: f64) {
	camera.distance *= math.pow(0.9, y_offset)
}

camera_update :: proc(state: ^State, cursor: [2]f64, prev_cursor: ^[2]f64) {
	if state.input.orbiting {
		state.camera.azimuth -= (cursor.x - prev_cursor.x) * ORBIT_SENS
		state.camera.elevation += (cursor.y - prev_cursor.y) * ORBIT_SENS
		state.camera.elevation = math.clamp(
			state.camera.elevation,
			-CAMERA_ELEVATION_MAX,
			CAMERA_ELEVATION_MAX,
		)
	}

	prev_cursor^ = cursor
}
