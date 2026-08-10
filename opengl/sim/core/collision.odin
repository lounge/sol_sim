package sim_core

import "core:math"
import "core:math/linalg"

collision_compute :: proc(bodies: []Body, tree: ^Gravity_Tree) -> (pair: [2]int, collision: bool) {
	if len(bodies) < BH_THRESHOLD {
		return collision_scan(bodies)
	}

	r_max := 0.0
	for body in bodies do r_max = max(r_max, body.radius)

	for i in 0 ..< len(bodies) {
		partner, found := gravity_tree_contact(tree, 0, i32(i), bodies, r_max)
		if found do return {i, partner}, true
	}

	when BH_VALIDATE {
		_, brute_collision := collision_scan(bodies)
		assert(!brute_collision)
	}

	return
}

collision_scan :: proc(bodies: []Body) -> (pair: [2]int, collision: bool) {
	for i in 0 ..< len(bodies) {
		for j in (i + 1) ..< len(bodies) {
			if bodies_overlap(&bodies[i], &bodies[j]) {
				return {i, j}, true
			}
		}
	}

	return
}

bodies_overlap :: proc(body_a, body_b: ^Body) -> bool {
	r_vec := body_a.pos - body_b.pos
	reach := body_a.radius + body_b.radius
	return linalg.length2(r_vec) < reach * reach
}

collision_merge :: proc(
	pair: [2]int,
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
	tracked_body: ^int,
	tree: ^Gravity_Tree,
) {
	body_a := &bodies[pair.x]
	body_b := &bodies[pair.y]

	survivor := body_a
	removed := body_b

	survivor_index := pair.x
	removed_index := pair.y
	if body_b.mass > body_a.mass {
		survivor = body_b
		removed = body_a

		survivor_index = pair.y
		removed_index = pair.x
	}

	mass := body_a.mass + body_b.mass
	vel := (body_a.mass * body_a.vel + body_b.mass * body_b.vel) / mass
	pos := (body_a.mass * body_a.pos + body_b.mass * body_b.pos) / mass
	prev_pos := (body_a.mass * body_a.prev_pos + body_b.mass * body_b.prev_pos) / mass

	radius := math.pow((math.pow(body_a.radius, 3.0) + math.pow(body_b.radius, 3.0)), 1.0 / 3.0)

	survivor.mass = mass
	survivor.vel = vel
	survivor.pos = pos
	survivor.prev_pos = prev_pos
	survivor.radius = radius

	if tracked_body^ == removed_index do tracked_body^ = survivor_index
	if tracked_body^ > removed_index do tracked_body^ -= 1

	body_remove(removed_index, bodies, trails, tree)
}

collisions_drain :: proc(
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
	tracked_body: ^int,
	tree: ^Gravity_Tree,
) -> bool {
	merged := false
	for {
		pair, collision := collision_compute(bodies[:], tree)
		if !collision do break
		collision_merge(pair, bodies, trails, tracked_body, tree)
		merged = true
	}
	return merged
}
