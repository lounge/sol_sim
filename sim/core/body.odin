package sim_core

import "core:math"

INCL_SCALE :: #config(INCL_SCALE, 1.0)
KEPLER_MAX_ITERATIONS :: 12

Body :: struct {
	name:            string,
	color:           Color,
	pos:             Vec,
	prev_pos:        Vec,
	vel:             Vec,
	mass:            f64,
	radius:          f64,
	accel:           Vec,
	rotation_period: f64,
	spawned:         bool, // if dynamically spawned
}

body_add :: proc(
	spec: Body_Spec,
	parent_index: int,
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
	delta_t: f64,
) {
	bary_pos: Vec = {}
	bary_vel: Vec = {}
	steps_per_orbit: f64 = 0.0
	stride: int = 1

	sum_pos: Vec = {}
	sum_vel: Vec = {}
	m_sys := spec.mass
	if parent_index >= 0 {
		parent := bodies[parent_index]

		mu := G * (parent.mass + spec.mass)
		rel_pos, rel_vel := spec_rel_state(spec, mu, delta_t)
		bary_pos = parent.pos + rel_pos
		bary_vel = parent.vel + rel_vel

		T := 2 * math.PI * math.sqrt(math.pow(f64(spec.semi_major_axis), f64(3)) / mu)
		steps_per_orbit = T / DT

		stride = math.max(1, int(math.ceil(TRAIL_FRACTION * steps_per_orbit / TRAIL_CAP)))


		for sat in spec.satellites {
			mu_sat := G * (spec.mass + sat.mass)
			sat_rel_pos, sat_rel_vel := spec_rel_state(sat, mu_sat, delta_t)
			sum_pos += sat.mass * sat_rel_pos
			sum_vel += sat.mass * sat_rel_vel
			m_sys += sat.mass
		}
	}

	pos := bary_pos - sum_pos / m_sys
	vel := bary_vel - sum_vel / m_sys


	body := Body {
		name            = spec.name,
		color           = spec.color,
		pos             = pos,
		prev_pos        = pos,
		vel             = vel,
		mass            = spec.mass,
		radius          = spec.radius,
		accel           = {},
		rotation_period = spec.rotation_period,
	}

	trail := trail_make_orbital(parent_index, steps_per_orbit, stride)

	assert(len(trail.points) <= TRAIL_CAP, spec.name)

	append(bodies, body)
	append(trails, trail)

	body_index := len(bodies) - 1
	for sat in spec.satellites {
		body_add(sat, body_index, bodies, trails, delta_t)
	}
}


body_remove :: proc(
	index: int,
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
	tree: ^Gravity_Tree,
) {
	if bodies[index].spawned do delete(bodies[index].name)

	delete(trails[index].points)
	ordered_remove(bodies, index)
	ordered_remove(trails, index)

	for &trail in trails {
		if trail.parent == index {
			delete(trail.points)
			trail = trail_make_default()
		} else if trail.parent > index {
			trail.parent -= 1
		}
	}


	accels_compute(bodies[:], tree)
}

body_spawn :: proc(
	bodies: ^[dynamic]Body,
	trails: ^[dynamic]Trail,
	tree: ^Gravity_Tree,
	name: string,
	color: Color,
	pos: Vec,
	vel: Vec,
	mass: f64,
	radius: f64,
) {
	body := Body {
		name     = name,
		color    = color,
		pos      = pos,
		prev_pos = pos,
		vel      = vel,
		mass     = mass,
		radius   = radius,
		spawned  = true,
	}

	append(bodies, body)
	append(trails, trail_make_default())

	accels_compute(bodies[:], tree)
}

@(private)
spec_rel_state :: proc "contextless" (
	spec: Body_Spec,
	mu: f64,
	delta_t: f64,
) -> (
	rel_pos, rel_vel: Vec,
) {

	a := spec.semi_major_axis
	e := spec.eccentricity
	n := math.sqrt(mu / math.pow(a, 3))

	M := math.to_radians(spec.mean_anomaly) + n * delta_t
	M = math.mod(M, 2 * math.PI)
	E := kepler_solve(M, e)

	r := a * (1 - e * math.cos(E))

	x := a * (math.cos(E) - e) // along p_hat
	y := a * math.sqrt(1 - e * e) * math.sin(E) // along q_hat

	v_scale := math.sqrt(mu * a) / r
	vx := -v_scale * math.sin(E)
	vy := v_scale * math.sqrt(1 - e * e) * math.cos(E)

	cos_i := math.cos(math.to_radians(spec.inclination * INCL_SCALE))
	sin_i := math.sin(math.to_radians(spec.inclination * INCL_SCALE))

	cos_O := math.cos(math.to_radians(spec.lon_asc_node * INCL_SCALE))
	sin_O := math.sin(math.to_radians(spec.lon_asc_node * INCL_SCALE))

	cos_w := math.cos(math.to_radians(spec.arg_perihelion * INCL_SCALE))
	sin_w := math.sin(math.to_radians(spec.arg_perihelion * INCL_SCALE))

	p_hat := [3]f64 {
		cos_O * cos_w - sin_O * sin_w * cos_i,
		sin_O * cos_w + cos_O * sin_w * cos_i,
		sin_w * sin_i,
	}

	q_hat := [3]f64 {
		-cos_O * sin_w - sin_O * cos_w * cos_i,
		-sin_O * sin_w + cos_O * cos_w * cos_i,
		cos_w * sin_i,
	}

	pos := x * p_hat + y * q_hat
	vel := vx * p_hat + vy * q_hat
	return pos, vel
}


// Keplers equation solver
@(private)
kepler_solve :: proc "contextless" (m, e: f64) -> f64 {
	E := m

	for _ in 0 ..< KEPLER_MAX_ITERATIONS {
		f := E - e * math.sin(E) - m
		f_prime := 1 - e * math.cos(E)
		delta := f / f_prime
		E = E - delta
		if E - delta == E do break
	}

	return E
}
