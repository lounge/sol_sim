package main

import sim "../core"
import "core:fmt"
import "core:math"

pending_edits_apply :: proc(state: ^State, bodies: []sim.Body, tree: ^sim.Gravity_Tree) {
	if state.input.pending_vel == 0 && state.input.pending_mass == 0 do return

	if state.tracked_body < 0 {
		state.input.pending_vel = 0
		state.input.pending_mass = 0
		return
	}

	body := &bodies[state.tracked_body]

	if state.input.pending_vel != 0 {
		vel_factor := 1.0 + f64(state.input.pending_vel) / 100
		body.vel *= vel_factor
		fmt.printfln("Body: %s, Factor: %f, Speed: %v", body.name, vel_factor, body.vel)
	}

	if state.input.pending_mass != 0 {
		mass_factor := math.pow_f64(MASS_FACTOR, f64(state.input.pending_mass))
		body.mass *= mass_factor

		fmt.printfln("Body: %s, Factor: %f, Mass: %e", body.name, mass_factor, body.mass)

		sim.accels_compute(bodies, tree)
	}

	state.input.pending_vel = 0
	state.input.pending_mass = 0
}
