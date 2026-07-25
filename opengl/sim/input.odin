package main

MASS_FACTOR :: 2
DRAG_TIME :: 0.4

Input :: struct {
	pending_click: Maybe([2]f64),
	pending_vel: int,
	pending_mass: int,
	pending_spawn: Maybe(Spawn_Request),
	drag_start: Maybe([2]f64)
}

Spawn_Request :: struct {
	start_pos: [2]f64,
	end_pos: [2]f64,
	mass: f64,
	radius: f64
}
