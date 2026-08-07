package main

import "core:math"

Body :: struct {
	name:     string,
	color:    Color,
	pos:      [2]f64,
	prev_pos: [2]f64,
	vel:      [2]f64,
	mass:     f64,
	radius:   f64,
	accel:    [2]f64,
	spawned:  bool, // if dynamically spawned
}

body_add :: proc(
	spec: Body_Spec,
	parent_index: int,
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
) {
	pos: [2]f64 = {0.0, 0.0}
	vel: [2]f64 = {0.0, 0.0}
	steps_per_orbit: f64 = 0.0
	stride: int = 1

	if parent_index >= 0 {
		parent := bodies[parent_index]
		ecc_factor := 1 - spec.ecc
		if spec.start_at_aphelion {
			ecc_factor = 1 + spec.ecc
		}

		start_dist := spec.semi_major_axis * ecc_factor
		start_speed := math.sqrt(G * parent.mass * (2 / start_dist - 1 / spec.semi_major_axis))

		pos = parent.pos + {start_dist, 0}
		vel = parent.vel + {0, start_speed}

		T :=
			2 *
			math.PI *
			math.sqrt(math.pow(f64(spec.semi_major_axis), f64(3)) / (G * parent.mass))
		steps_per_orbit = T / DT

		stride = math.max(1, int(math.ceil(TRAIL_FRACTION * steps_per_orbit / TRAIL_CAP)))
	}

	body := Body {
		name     = spec.name,
		color    = spec.color,
		pos      = pos,
		prev_pos = pos,
		vel      = vel,
		mass     = spec.mass,
		radius   = spec.radius,
		accel    = {0.0, 0.0},
	}

	trail := trail_make_orbital(parent_index, steps_per_orbit, stride)

	assert(trail.cap <= TRAIL_CAP, spec.name)

	append(bodies, body)
	append(trails, trail)

	body_index := len(bodies) - 1
	for sat in spec.satellites {
		body_add(sat, body_index, bodies, trails)
	}
}


body_remove :: proc(index: int, bodies: ^[dynamic]Body, trails: ^[dynamic]Trail, tree: ^Quadtree) {
	if bodies[index].spawned do delete(bodies[index].name)

	ordered_remove(bodies, index)
	ordered_remove(trails, index)

	for &trail in trails {
		if trail.parent == index {
			trail = trail_make_default()
		} else if trail.parent > index {
			trail.parent -= 1
		}
	}


	accels_compute(bodies[:], tree)
}
