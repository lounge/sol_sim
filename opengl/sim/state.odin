package main

State :: struct {
	sim_speed: int,
	input: Input,
	camera: Camera
}

state_init :: proc() -> State {
	return State{
		sim_speed = 200000,
		input = Input {nil, 0, 0},
		camera = Camera {
			{0.0, 0.0},
			1.1,
			-1
		}
	}
}
