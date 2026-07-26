package main

import "core:math"

MASS_FACTOR :: 2
DRAG_TIME :: 0.4
SPAWN_MASS_SENS :: 0.5
SPAWN_BASE_MASS :: 3.69e-8 // Moon
SPAWN_BASE_RADIUS :: 1.161e-5 // Moon

Input :: struct {
	pending_click: Maybe([2]f64),
	pending_vel: int,
	pending_mass: int,
	pending_spawn: Maybe(Spawn_Request),
	drag_start: Maybe([2]f64),
	spawn_mass_exp: f64
}

Spawn_Request :: struct {
	start_pos: [2]f64,
	end_pos: [2]f64,
	mass: f64,
	radius: f64
}

spawn_mass_radius :: proc "contextless" (mass_exp: f64) -> (mass: f64, radius: f64) {
	mass = SPAWN_BASE_MASS * math.pow(2, mass_exp)
	radius = SPAWN_BASE_RADIUS * math.pow(mass / SPAWN_BASE_MASS, 1.0/3.0)

	return mass, radius
}
