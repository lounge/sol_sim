package main

import "core:math"

G :: 1.0
DT :: #config(DT, 0.0001)

Body :: struct {
	name:     string,
	color:    Color,
	pos:      [2]f64,
	prev_pos: [2]f64,
	vel:      [2]f64,
	mass:     f64,
	radius:   f64,
	accel:    [2]f64,
	spawned:  bool, // if dynamicaly spawned
}

// Integrator: Kick–drift–kick velocity Verlet
physics_step :: proc(bodies: []Body, dt: f64) {
	for &body in bodies do body.prev_pos = body.pos
	for &body in bodies do body.vel += body.accel * (dt / 2) // half-kick
	for &body in bodies do body.pos += body.vel * dt // drift
	accels_compute(bodies[:])
	for &body in bodies do body.vel += body.accel * (dt / 2) // half-kick
}

accels_compute :: proc(bodies: []Body) {
	for &body in bodies do body.accel = 0

	for i := 0; i < len(bodies); i += 1 {
		for j := i + 1; j < len(bodies); j += 1 {
			body_a := &bodies[i]
			body_b := &bodies[j]

			r_vec := body_a.pos - body_b.pos
			distance := math.sqrt(r_vec.x * r_vec.x + r_vec.y * r_vec.y)
			direction := r_vec / distance

			body_a.accel -= direction * (G * body_b.mass / (distance * distance))
			body_b.accel += direction * (G * body_a.mass / (distance * distance))
		}
	}
}
