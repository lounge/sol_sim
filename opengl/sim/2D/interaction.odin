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

		fmt.printfln("Body: %s, Factor: %f, Mass: %v", body.name, mass_factor, body.mass)

		sim.accels_compute(bodies, tree)
	}

	state.input.pending_vel = 0
	state.input.pending_mass = 0
}

pending_spawn_apply :: proc(
	state: ^State,
	bodies: ^[dynamic]sim.Body,
	trails: ^[dynamic]sim.Trail,
	width, height: i32,
	tree: ^sim.Gravity_Tree,
) {
	if spawn, ok := state.input.pending_spawn.?; ok {
		world_pos_start := world_pos_calc(spawn.start_pos, &state.camera, width, height)
		world_pos_end := world_pos_calc(spawn.end_pos, &state.camera, width, height)
		world_drag := world_pos_end - world_pos_start

		sim.body_spawn(
			bodies,
			trails,
			tree,
			fmt.aprintf("Spawnius %d", state.spawned_bodies + 1),
			sim.PALETTE[.Spawn],
			([2]f64)(world_pos_end),
			([2]f64)(world_drag) / DRAG_TIME,
			spawn.mass,
			spawn.radius,
		)

		state.input.pending_spawn = nil
		state.spawned_bodies += 1
	}
}

pending_delete_apply :: proc(
	state: ^State,
	bodies: ^[dynamic]sim.Body,
	trails: ^[dynamic]sim.Trail,
	tree: ^sim.Gravity_Tree,
) {
	if state.input.pending_delete == false do return

	if state.tracked_body < 0 {
		state.input.pending_delete = false
		return
	}

	tracked_id := state.tracked_body

	sim.body_remove(tracked_id, bodies, trails, tree)

	state.tracked_body = -1
	state.input.pending_delete = false
	state.title_stale = true
}
