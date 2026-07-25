package main

import "core:math"
import "core:fmt"

G :: 1.0
DT :: #config(DT, 0.0001)

Body :: struct {
	name: string,
	color: [3]f32,
	pos: [2]f64,
	prev_pos: [2]f64,
	vel: [2]f64,
	mass: f64,
	radius: f64,
	accel: [2]f64
}

// Integrator: Kick–drift–kick velocity Verlet
physics_step :: proc(bodies: []Body, dt: f64) {
	for &body in bodies do body.prev_pos = body.pos
	for &body in bodies do body.vel += body.accel * (dt / 2) // half-kick
	for &body in bodies do body.pos += body.vel * dt // drift
	compute_accels(bodies[:])
	for &body in bodies do body.vel += body.accel * (dt / 2) // half-kick
}

compute_accels :: proc(bodies: []Body) {
	for &body in bodies do body.accel = 0

	for i := 0; i < len(bodies); i += 1 {
	 	for j := i + 1; j < len(bodies); j += 1 {
			bodyA := &bodies[i]
 			bodyB := &bodies[j]

	        r_vec := bodyA.pos - bodyB.pos
	        distance := math.sqrt(r_vec.x * r_vec.x + r_vec.y * r_vec.y)
	        direction := r_vec / distance

			bodyA.accel -= direction * (G * bodyB.mass / (distance * distance))
			bodyB.accel += direction * (G * bodyA.mass / (distance * distance))
		}
	}
}

apply_pending_edits :: proc (state: ^State, bodies: []Body) {
	if state.input.pending_vel == 0 && state.input.pending_mass == 0 do return

	if state.camera.tracked_body < 0 {
		state.input.pending_vel = 0
		state.input.pending_mass = 0
		return
	}

	body := &bodies[state.camera.tracked_body]

	if state.input.pending_vel != 0 {
		vel_factor := 1.0 + f64(state.input.pending_vel) / 100
		body.vel *= vel_factor
		fmt.printfln("Body: %s, Factor: %f, Speed: %v", body.name, vel_factor, body.vel)
	}

	if state.input.pending_mass != 0 {
		mass_factor :=  math.pow_f64(MASS_FACTOR, f64(state.input.pending_mass))
		body.mass *= mass_factor

		fmt.printfln("Body: %s, Factor: %f, Mass: %v", body.name, mass_factor, body.mass)

		compute_accels(bodies)
	}

	state.input.pending_vel = 0
	state.input.pending_mass = 0
}
