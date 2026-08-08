package main

State :: struct {
	sim_speed:      int,
	spawned_bodies: int,
	input:          Input,
	camera:         Camera,
	title_stale:    bool,
	tracked_body:   int,
}

state_init :: proc() -> State {
	return State {
		sim_speed = 200000,
		input = Input{},
		camera = Camera{{0.0, 0.0}, 1.1},
		title_stale = true,
		tracked_body = -1,
	}
}
