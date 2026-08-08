package sim_core

import "core:math"
import "core:math/linalg"

import "core:fmt"
_ :: fmt

BH_THETA :: #config(BH_THETA, 0.5)
BH_THRESHOLD :: #config(BH_THRESHOLD, 300)
BH_MAX_DEPTH :: #config(BH_MAX_DEPTH, 32)
BH_VALIDATE :: #config(BH_VALIDATE, false)
BH_DEBUG :: #config(BH_DEBUG, false)
BH_DEBUG_DRAW :: #config(BH_DEBUG_DRAW, false)

Tree_Node :: struct {
	center:    Vec,
	half_size: f64,
	children:  [1 << DIM]i32,
	body:      i32,
	mass:      f64,
	com:       Vec,
}

Gravity_Tree :: struct {
	node:             [dynamic]Tree_Node,
	max_depth:        int,
	validate_max_err: f64,
	debug_last:       f64,
}

gravity_tree_build :: proc(tree: ^Gravity_Tree, bodies: []Body) {
	clear(&tree.node)
	tree.max_depth = 0

	if len(bodies) == 0 {
		return
	}

	lo := bodies[0].pos
	hi := bodies[0].pos

	for b in bodies[1:] {
		lo = linalg.min(lo, b.pos)
		hi = linalg.max(hi, b.pos)
	}

	center := (lo + hi) / 2
	half_size := math.max(0.001, linalg.max(hi - lo) / 2 * 1.01)

	node_idx := gravity_tree_create_node(tree, center, half_size)

	for i in 0 ..< len(bodies) {
		gravity_tree_insert(tree, node_idx, i32(i), bodies, 0)
	}

	gravity_tree_calc(tree, bodies)
}

gravity_tree_create_node :: proc(tree: ^Gravity_Tree, center: Vec, half_size: f64) -> int {
	node := Tree_Node {
		center    = center,
		half_size = half_size,
		children  = {0 ..< 1 << DIM = -1},
		body      = -1,
	}

	append(&tree.node, node)

	return len(tree.node) - 1
}

gravity_tree_insert :: proc(
	tree: ^Gravity_Tree,
	node_idx: int,
	body_idx: i32,
	bodies: []Body,
	depth: int,
) {
	for child in tree.node[node_idx].children {
		if child != -1 {
			gravity_tree_push_down(tree, node_idx, body_idx, bodies, depth)
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

	gravity_tree_push_down(tree, node_idx, old, bodies, depth)
	gravity_tree_push_down(tree, node_idx, body_idx, bodies, depth)
}

gravity_tree_push_down :: proc(
	tree: ^Gravity_Tree,
	node_idx: int,
	body_idx: i32,
	bodies: []Body,
	depth: int,
) {
	quad := 0
	pos := bodies[body_idx].pos
  	center := tree.node[node_idx].center
	for i in 0 ..< DIM do quad |= int(pos[i] > center[i]) << uint(i)

	if tree.node[node_idx].children[quad] == -1 {
		offset := tree.node[node_idx].half_size / 2
		child_center := center
		for i in 0 ..< DIM {
			child_center[i] += (quad >> uint(i)) & 1 == 1 ? +offset : -offset
		}

		child_idx := gravity_tree_create_node(tree, child_center, offset)
		tree.node[node_idx].children[quad] = i32(child_idx)
	}

	gravity_tree_insert(tree, int(tree.node[node_idx].children[quad]), body_idx, bodies, depth + 1)
}

gravity_tree_calc :: proc(tree: ^Gravity_Tree, bodies: []Body) {
	#reverse for &node in tree.node {
		if (node.body >= 0) {
			node.mass = bodies[node.body].mass
			node.com = bodies[node.body].pos
			continue
		}

		total_mass := 0.0
		total_com := Vec{}
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

gravity_tree_accel :: proc(tree: ^Gravity_Tree, node_idx: int, body_idx: i32, bodies: []Body) -> Vec {
	node := tree.node[node_idx]
	body_pos := bodies[body_idx].pos

	if node.body >= 0 {
		if node.body == body_idx {
			return {}
		}
		return gravity_tree_accel_toward(body_pos, bodies[node.body].pos, bodies[node.body].mass)
	}

	size := node.half_size * 2
	distance := linalg.length(body_pos - node.com)
	outside := linalg.max(linalg.abs(body_pos - node.center)) > node.half_size

	if outside && size / distance < BH_THETA {
		return gravity_tree_accel_toward(body_pos, node.com, node.mass)
	}

	sum: Vec
	for child in node.children {
		if child != -1 {
			sum += gravity_tree_accel(tree, int(child), body_idx, bodies)
		}
	}

	return sum
}


gravity_tree_accel_toward :: proc(pos: Vec, source_pos: Vec, source_mass: f64) -> Vec {
	r_vec := pos - source_pos
	distance := linalg.length(r_vec)
	return -(r_vec / distance) * (G * source_mass / (distance * distance))
}

gravity_tree_contact :: proc(
	tree: ^Gravity_Tree,
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
			partner, found = gravity_tree_contact(tree, int(child), body_idx, bodies, r_max)
			if found do return
		}
	}

	return
}

box_within_reach :: proc(center: Vec, half_size: f64, pos: Vec, reach: f64) -> bool {
	overhang := linalg.max(linalg.abs(pos - center) - half_size, Vec{})
	return linalg.dot(overhang, overhang) < reach * reach
}

when BH_DEBUG {
	gravity_tree_debug :: proc(tree: ^Gravity_Tree, bodies: []Body, now: f64) {
		if now - tree.debug_last < 1 || len(tree.node) == 0 do return

		tree.debug_last = now

		mass_sum: f64
		weighted_pos: Vec
		for body in bodies {
			mass_sum += body.mass
			weighted_pos += body.pos * body.mass
		}
		barycenter := weighted_pos / mass_sum

		root := tree.node[0]
		fmt.printfln(
			"BH: nodes %d - depth %d - mass diff %e - com diff %v - max err %e",
			len(tree.node),
			tree.max_depth,
			root.mass - mass_sum,
			root.com - barycenter,
			tree.validate_max_err,
		)
		tree.validate_max_err = 0
	}
}
