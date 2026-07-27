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

apply_pending_spawn :: proc (state: ^State, bodies: ^[dynamic]Body, trails: ^[dynamic]Trail, width, height: i32) {
	if spawn, ok := state.input.pending_spawn.?; ok {
		world_pos_start := calc_world_pos(spawn.start_pos, &state.camera, width, height)
		world_pos_end := calc_world_pos(spawn.end_pos, &state.camera, width, height)

		world_drag := world_pos_end - world_pos_start

		body := Body {
			name = fmt.aprintf("Spawnius %d", state.spawned_bodies + 1),
			color = palette.Spawn,
			pos = ([2]f64)(world_pos_end),
			prev_pos = ([2]f64)(world_pos_end),
			vel = ([2]f64)(world_drag) / DRAG_TIME,
			mass = spawn.mass,
			radius = spawn.radius
		}

		trail := Trail {
			parent = -1,
			cap = TRAIL_CAP,
			stride = TRAIL_STRIDE_DEFAULT
		}

		append(bodies, body)
		append(trails, trail)

		compute_accels(bodies[:])

		state.input.pending_spawn = nil
		state.spawned_bodies += 1
	}
}
