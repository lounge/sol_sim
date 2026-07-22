package main

import "core:math"

BodySpec :: struct {
	mass: f64,
	radius: f64,
	ecc: f64,
	semi_major_axis: f64,
	parent: int,
	name: string
}

specs := []BodySpec {
	BodySpec {
		mass = 1.0,
		radius = 4.654e-3,
		ecc = 0,
		semi_major_axis = 0,
		parent = -1,
		name = "Sun"
	},
	BodySpec {
		mass = 1.660e-7,
		radius = 1.631e-5,
		ecc = 0.2056,
		semi_major_axis = 0.387,
		parent = 0,
		name = "Mercury"
	},
	BodySpec {
		mass = 2.447e-6,
		radius = 4.045e-5,
		ecc = 0.0068,
		semi_major_axis = 0.723,
		parent = 0,
		name = "Venus"
	},
	BodySpec {
		mass = 3.003 * math.pow10(f64(-6.0)),
		radius = 4.259e-5,
		ecc = 0.0167,
		semi_major_axis = 1,
		parent = 0,
		name = "Earth"
	},
	BodySpec {
		mass = 3.69 * math.pow10(f64(-8.0)),
		radius = 1.161e-5,
		ecc = 0.0549,
		semi_major_axis = 2.570 * math.pow10(f64(-3)),
		parent = 3,
		name = "Moon"
	},
	BodySpec {
		mass = 3.227e-7,
		radius = 2.266e-5,
		ecc = 0.0934,
		semi_major_axis = 1.524,
		parent = 0,
		name = "Mars"
	}
}

create_system :: proc() -> (bodies: [dynamic]Body, trails: [dynamic]Trail) {
	for &spec, i in specs {
		pos: [2]f64 = {0.0, 0.0}
		vel: [2]f64 = {0.0, 0.0}
		frames_per_orbit: f64 = 0.0

		if spec.parent >= 0  {
			start_dist := spec.semi_major_axis * (1 - spec.ecc)
			start_speed := math.sqrt(G * bodies[spec.parent].mass * (2 / start_dist - 1 / spec.semi_major_axis))

			pos = bodies[spec.parent].pos + {start_dist, 0}
			vel = bodies[spec.parent].vel + {0, start_speed}

			T := 2 * math.PI * math.sqrt(math.pow(f64(spec.semi_major_axis), f64(3)) / (G * bodies[spec.parent].mass))
			frames_per_orbit = T / (DT * STEPS_PER_FRAME)
		}

		body := Body {
			pos,
			vel,
			spec.mass,
			spec.radius
		}

		trail := Trail {
			parent = spec.parent,
			cap = int(TRAIL_FRACTION * frames_per_orbit)
		}

		assert(trail.cap <= TRAIL_CAP, spec.name)

		append(&bodies, body)
		append(&trails, trail)
	}

	max_cap := trails[0].cap
	for trail in trails[1:] {
    	max_cap = max(max_cap, trail.cap)
	}

	trails[0].cap = max_cap

	momentum_sum := [2]f64{0, 0}
	for body in bodies {
    	momentum_sum += body.mass * body.vel
	}

	bodies[0].vel -= momentum_sum / bodies[0].mass

	return bodies, trails
}
