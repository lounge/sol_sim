package main

import "core:fmt"
import "core:math"

pending_edits_apply :: proc(state: ^State, bodies: []Body) {
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
		mass_factor := math.pow_f64(MASS_FACTOR, f64(state.input.pending_mass))
		body.mass *= mass_factor

		fmt.printfln("Body: %s, Factor: %f, Mass: %v", body.name, mass_factor, body.mass)

		accels_compute(bodies)
	}

	state.input.pending_vel = 0
	state.input.pending_mass = 0
}

pending_spawn_apply :: proc(
	state: ^State,
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
	width, height: i32,
) {
	if spawn, ok := state.input.pending_spawn.?; ok {
		world_pos_start := world_pos_calc(spawn.start_pos, &state.camera, width, height)
		world_pos_end := world_pos_calc(spawn.end_pos, &state.camera, width, height)

		world_drag := world_pos_end - world_pos_start

		body := Body {
			name     = fmt.aprintf("Spawnius %d", state.spawned_bodies + 1),
			color    = PALETTE[.Spawn],
			pos      = ([2]f64)(world_pos_end),
			prev_pos = ([2]f64)(world_pos_end),
			vel      = ([2]f64)(world_drag) / DRAG_TIME,
			mass     = spawn.mass,
			radius   = spawn.radius,
			spawned  = true,
		}

		trail := trail_make_default()

		append(bodies, body)
		append(trails, trail)

		accels_compute(bodies[:])

		state.input.pending_spawn = nil
		state.spawned_bodies += 1
	}
}

pending_delete_apply :: proc(state: ^State, bodies: ^[dynamic]Body, trails: ^[dynamic]Trail) {
	if state.input.pending_delete == false do return

	if state.camera.tracked_body < 0 {
		state.input.pending_delete = false
		return
	}

	tracked_id := state.camera.tracked_body

	if bodies[tracked_id].spawned do delete(bodies[tracked_id].name)

	ordered_remove(bodies, tracked_id)
	ordered_remove(trails, tracked_id)

	for &trail in trails {
		if trail.parent == tracked_id {
			trail = trail_make_default()
		} else if trail.parent > tracked_id {
			trail.parent -= 1
		}
	}

	state.camera.tracked_body = -1
	state.input.pending_delete = false
	state.title_stale = true

	accels_compute(bodies[:])
}
