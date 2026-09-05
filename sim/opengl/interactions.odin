package main

import sim "../core"
import "core:fmt"
import "core:math"
import "core:math/linalg"


PICK_RADIUS_PX :: 8

pending_click_apply :: proc(
	state: ^State,
	bodies: []sim.Body,
	alpha: f64,
	camera_frame: Camera_Frame,
	width, height: i32,
) {
	click, ok := state.input.pending_click.?
	if !ok do return
	state.input.pending_click = nil

	projection := camera_frame.proj * camera_frame.view

	best_index := -1
	best_dist := math.INF_F64
	for body, i in bodies {
		rel := pos_render(body, alpha) - camera_frame.eye
		clip := projection * [4]f64{rel.x, rel.y, rel.z, 1}
		if clip.w <= 0 do continue

		ndc := clip.xyz / clip.w
		px := (ndc.x + 1) / 2 * f64(width) // NDC -> WINDOW pixels
		py := (-ndc.y + 1) / 2 * f64(height) // y-flip

		radius_px := body.radius / (clip.w * math.tan_f64(CAMERA_FOV / 2)) * f64(height) / 2
		pick_px := math.max(math.max(radius_px, MIN_MARKER_PX), PICK_RADIUS_PX)

		dist := linalg.length([2]f64{px, py} - ([2]f64)(click))
		if dist < pick_px && dist < best_dist {
			best_dist = dist
			best_index = i
		}
	}

	state.tracked_body = best_index
	state.title_stale = true

	if best_index >= 0 {
		state.camera.distance = bodies[best_index].radius * CAMERA_VIEW_SCALE
	}
}

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

pending_spawn_apply :: proc(
	state: ^State,
	bodies: ^[dynamic]sim.Body,
	trails: ^[dynamic]sim.Trail,
	width, height: i32,
	tree: ^sim.Gravity_Tree,
) {
	if spawn, ok := state.input.pending_spawn.?; ok {
		defer state.input.pending_spawn = nil

		origin_a, s_dir := camera_ray(state.camera, spawn.start_pos, f64(width), f64(height))
		s_hit, s_ok := ray_plane_hit(origin_a, s_dir).?

		origin_b, e_dir := camera_ray(state.camera, spawn.end_pos, f64(width), f64(height))
		e_hit, e_ok := ray_plane_hit(origin_b, e_dir).?

		if !s_ok || !e_ok do return

		tracked_vel := state.tracked_body >= 0 ? bodies[state.tracked_body].vel : {}
		drag_vel := (([2]f64)(e_hit) - ([2]f64)(s_hit)) / DRAG_TIME

		spawn_vel := tracked_vel + {drag_vel.x, drag_vel.y, 0}

		sim.body_spawn(
			bodies,
			trails,
			tree,
			fmt.aprintf("Spawnius %d", state.spawned_bodies + 1),
			sim.PALETTE[.Spawn],
			{e_hit.x, e_hit.y, 0},
			spawn_vel,
			spawn.mass,
			spawn.radius,
		)

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
