package main

import "core:math"
import "core:math/linalg"

BH_THETA :: #config(BH_THETA, 0.5)
BH_THRESHOLD :: #config(BH_THRESHOLD, 300)
BH_MAX_DEPTH :: #config(BH_MAX_DEPTH, 32)
BH_VALIDATE :: #config(BH_VALIDATE, false)
BH_DEBUG :: #config(BH_DEBUG, false)

Quad_Node :: struct {
	center:    [2]f64,
	half_size: f64,
	children:  [4]i32,
	body:      i32,
	mass:      f64,
	com:       [2]f64,
}

Quadtree :: struct {
	node:             [dynamic]Quad_Node,
	max_depth:        int,
	validate_max_err: f64,
}

quadtree_build :: proc(tree: ^Quadtree, bodies: []Body) {
	clear(&tree.node)
	tree.max_depth = 0

	if len(bodies) == 0 {
		return
	}

	min_x := bodies[0].pos.x
	max_x := bodies[0].pos.x
	min_y := bodies[0].pos.y
	max_y := bodies[0].pos.y

	for b in bodies[1:] {
		min_x = min(min_x, b.pos.x)
		max_x = max(max_x, b.pos.x)
		min_y = min(min_y, b.pos.y)
		max_y = max(max_y, b.pos.y)
	}

	min: [2]f64 = {min_x, min_y}
	max: [2]f64 = {max_x, max_y}

	center := (min + max) / 2
	half_size := math.max(0.001, math.max(max.x - min.x, max.y - min.y) / 2 * 1.01)

	node_idx := quadtree_create_node(tree, center, half_size)

	for i in 0 ..< len(bodies) {
		quadtree_insert(tree, node_idx, i32(i), bodies, 0)
	}

	quadtree_calc(tree, bodies)
}

quadtree_create_node :: proc(tree: ^Quadtree, center: [2]f64, half_size: f64) -> int {
	node := Quad_Node {
		center    = center,
		half_size = half_size,
		children  = {-1, -1, -1, -1},
		body      = -1,
	}

	append(&tree.node, node)

	return len(tree.node) - 1
}

quadtree_insert :: proc(
	tree: ^Quadtree,
	node_idx: int,
	body_idx: i32,
	bodies: []Body,
	depth: int,
) {
	for child in tree.node[node_idx].children {
		if child != -1 {
			quadtree_push_down(tree, node_idx, body_idx, bodies, depth)
			return
		}
	}

	if tree.node[node_idx].body == -1 {
		tree.node[node_idx].body = body_idx
		tree.max_depth = max(tree.max_depth, depth)
		return
	}

	assert(depth < BH_MAX_DEPTH)

	old := tree.node[node_idx].body
	tree.node[node_idx].body = -1

	quadtree_push_down(tree, node_idx, old, bodies, depth)
	quadtree_push_down(tree, node_idx, body_idx, bodies, depth)
}

quadtree_push_down :: proc(
	tree: ^Quadtree,
	node_idx: int,
	body_idx: i32,
	bodies: []Body,
	depth: int,
) {
	quad :=
		int(bodies[body_idx].pos.x > tree.node[node_idx].center.x) +
		2 * int(bodies[body_idx].pos.y > tree.node[node_idx].center.y)
	if tree.node[node_idx].children[quad] == -1 {
		offset := tree.node[node_idx].half_size / 2
		child_center :=
			tree.node[node_idx].center +
			{quad & 1 == 1 ? +offset : -offset, quad & 2 == 2 ? +offset : -offset}

		child_idx := quadtree_create_node(tree, child_center, offset)
		tree.node[node_idx].children[quad] = i32(child_idx)
	}

	quadtree_insert(tree, int(tree.node[node_idx].children[quad]), body_idx, bodies, depth + 1)
}

quadtree_calc :: proc(tree: ^Quadtree, bodies: []Body) {
	#reverse for &node in tree.node {
		if (node.body >= 0) {
			node.mass = bodies[node.body].mass
			node.com = bodies[node.body].pos
			continue
		}

		total_mass := 0.0
		total_com := [2]f64{}
		for &child in node.children {
			if child == -1 do continue

			child_node := tree.node[child]

			total_mass += child_node.mass
			total_com += child_node.com * child_node.mass
		}

		node.mass = total_mass
		node.com = total_com / total_mass
	}
}

quadtree_accel :: proc(tree: ^Quadtree, node_idx: int, body_idx: i32, bodies: []Body) -> [2]f64 {
	node := tree.node[node_idx]
	body_pos := bodies[body_idx].pos

	if node.body >= 0 {
		if node.body == body_idx {
			return {0, 0}
		}
		return quadtree_accel_toward(body_pos, bodies[node.body].pos, bodies[node.body].mass)
	}

	size := node.half_size * 2
	distance := linalg.length(body_pos - node.com)
	outside :=
		math.abs(body_pos.x - node.center.x) > node.half_size ||
		math.abs(body_pos.y - node.center.y) > node.half_size

	if outside && size / distance < BH_THETA {
		return quadtree_accel_toward(body_pos, node.com, node.mass)
	}

	sum: [2]f64 = {0, 0}
	for child in node.children {
		if child != -1 {
			sum += quadtree_accel(tree, int(child), body_idx, bodies)
		}
	}

	return sum
}


quadtree_accel_toward :: proc(pos: [2]f64, source_pos: [2]f64, source_mass: f64) -> [2]f64 {
	r_vec := pos - source_pos
	distance := linalg.length(r_vec)
	return -(r_vec / distance) * (G * source_mass / (distance * distance))
}

quadtree_contact :: proc(
	tree: ^Quadtree,
	node_idx: int,
	body_idx: i32,
	bodies: []Body,
	r_max: f64,
) -> (
	partner: int,
	found: bool,
) {
	node := tree.node[node_idx]

	if node.body >= 0 {
		if node.body == body_idx do return
		if bodies_overlap(&bodies[body_idx], &bodies[node.body]) {
			return int(node.body), true
		}
		return
	}

	reach := bodies[body_idx].radius + r_max
	if !box_within_reach(node.center, node.half_size, bodies[body_idx].pos, reach) do return

	for child in node.children {
		if child != -1 {
			partner, found = quadtree_contact(tree, int(child), body_idx, bodies, r_max)
			if found do return
		}
	}

	return
}

box_within_reach :: proc(center: [2]f64, half_size: f64, pos: [2]f64, reach: f64) -> bool {
	overhang_x := max(0.0, abs(pos.x - center.x) - half_size)
	overhang_y := max(0.0, abs(pos.y - center.y) - half_size)
	return overhang_x * overhang_x + overhang_y * overhang_y < reach * reach
}
