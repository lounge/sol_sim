package main

import "core:math"

State :: struct {
	sim_speed:      int,
	spawned_bodies: int,
	// input:          Input,
	camera:         Camera,
	title_stale:    bool,
	tracked_body:   int,
}

state_init :: proc() -> State {
	return State {
		sim_speed = 200000,
		// input = Input{},
		camera = Camera{target = {0, 0, 0}, azimuth = math.PI / 2, elevation = 0, distance = 45},
		title_stale = true,
		tracked_body = -1,
	}
}
