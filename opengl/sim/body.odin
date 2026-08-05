package main

Body :: struct {
	name:     string,
	color:    Color,
	pos:      [2]f64,
	prev_pos: [2]f64,
	vel:      [2]f64,
	mass:     f64,
	radius:   f64,
	accel:    [2]f64,
	spawned:  bool, // if dynamically spawned
}
