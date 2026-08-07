package main

import "core:math/linalg"
import "core:math"
_ :: math


G :: 1.0
DT :: #config(DT, 0.0001)

// Integrator: Kick–drift–kick velocity Verlet
physics_step :: proc(bodies: []Body, dt: f64, tree: ^Quadtree) {
	for &body in bodies do body.prev_pos = body.pos
	for &body in bodies do body.vel += body.accel * (dt / 2) // half-kick
	for &body in bodies do body.pos += body.vel * dt // drift
	accels_compute(bodies, tree)
	for &body in bodies do body.vel += body.accel * (dt / 2) // half-kick
}

accels_compute :: proc(bodies: []Body, tree: ^Quadtree) {
	if len(bodies) < BH_THRESHOLD {
		for &body in bodies do body.accel = 0

		for i in 0 ..< len(bodies) {
			for j in (i + 1) ..< len(bodies) {
				body_a := &bodies[i]
				body_b := &bodies[j]

				r_vec := body_a.pos - body_b.pos
				distance := linalg.length(r_vec)
				direction := r_vec / distance

				body_a.accel -= direction * (G * body_b.mass / (distance * distance))
				body_b.accel += direction * (G * body_a.mass / (distance * distance))
			}
		}
	} else {
		quadtree_build(tree, bodies[:])
		for i in 0 ..< len(bodies) {
			bodies[i].accel = quadtree_accel(tree, 0, i32(i), bodies)
		}
	}

	when BH_VALIDATE {
		for i in 0 ..< len(bodies) {
			brute: [2]f64 = {0, 0}
			for j in 0 ..< len(bodies) {
				if j != i {
					brute += quadtree_accel_toward(bodies[i].pos, bodies[j].pos, bodies[j].mass)
				}
			}
			err := linalg.length(bodies[i].accel - brute) / linalg.length(brute)
			tree.validate_max_err = math.max(tree.validate_max_err, err)
		}
	}
}
