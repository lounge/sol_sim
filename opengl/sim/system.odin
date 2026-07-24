package main

import "core:math"

palette := realistic.body

BodySpec :: struct {
	mass: f64,
	radius: f64,
	ecc: f64,
	semi_major_axis: f64,
	parent: int,
	start_at_aphelion: bool,
	color: [3]f32,
	name: string,
}

specs := []BodySpec {
	BodySpec {
		mass = 1.0,
		radius = 4.654e-3,
		ecc = 0,
		semi_major_axis = 0,
		parent = -1,
		color = palette.Sun,
		name = "Sun"
	},
	BodySpec {
		mass = 1.660e-7,
		radius = 1.631e-5,
		ecc = 0.2056,
		semi_major_axis = 0.387,
		parent = 0,
		color = palette.Mercury,
		name = "Mercury"
	},
	BodySpec {
		mass = 2.447e-6,
		radius = 4.045e-5,
		ecc = 0.0068,
		semi_major_axis = 0.723,
		parent = 0,
		color = palette.Venus,
		name = "Venus"
	},
	BodySpec {
		mass = 3.003 * math.pow10(f64(-6.0)),
		radius = 4.259e-5,
		ecc = 0.0167,
		semi_major_axis = 1,
		parent = 0,
		color = palette.Earth,
		name = "Earth"
	},
	BodySpec {
		mass = 3.69 * math.pow10(f64(-8.0)),
		radius = 1.161e-5,
		ecc = 0.0549,
		semi_major_axis = 2.570 * math.pow10(f64(-3)),
		parent = 3,
		color = palette.Moon,
		name = "Moon"
	},
	BodySpec {
		mass = 3.227e-7,
		radius = 2.266e-5,
		ecc = 0.0934,
		semi_major_axis = 1.524,
		parent = 0,
		color = palette.Mars,
		name = "Mars"
	},
	BodySpec {
		mass = 9.545e-4,
		radius = 4.673e-4,
		ecc = 0.0489,
		semi_major_axis = 5.203,
		parent = 0,
		color = palette.Jupiter,
		name = "Jupiter"
	},
	BodySpec {
		mass = 2.858e-4,
		radius = 3.893e-4,
		ecc = 0.0565,
		semi_major_axis = 9.537,
		parent = 0,
		color = palette.Saturn,
		name = "Saturn"
	},
	BodySpec {
		mass = 4.366e-5,
		radius = 1.695e-4,
		ecc = 0.0457,
		semi_major_axis = 19.19,
		parent = 0,
		color = palette.Uranus,
		name = "Uranus"
	},
	BodySpec {
		mass = 5.150e-5,
		radius = 1.646e-4,
		ecc = 0.0113,
		semi_major_axis = 30.07,
		parent = 0,
		color = palette.Neptune,
		name = "Neptune"
	},
	BodySpec {
		mass = 6.55e-9,
		radius = 7.94e-6,
		ecc = 0.2488,
		semi_major_axis = 39.48,
		parent = 0,
		start_at_aphelion = true,
		color = palette.Pluto,
		name = "Pluto"
	}
}

create_system :: proc() -> (bodies: [dynamic]Body, trails: [dynamic]Trail) {
	for &spec, i in specs {
		pos: [2]f64 = {0.0, 0.0}
		vel: [2]f64 = {0.0, 0.0}
		steps_per_orbit: f64 = 0.0
		stride: int = 1

		if spec.parent >= 0  {
			ecc_factor := 1 - spec.ecc
			if spec.start_at_aphelion {
    			ecc_factor = 1 + spec.ecc
			}

			start_dist := spec.semi_major_axis * ecc_factor
			start_speed := math.sqrt(G * bodies[spec.parent].mass * (2 / start_dist - 1 / spec.semi_major_axis))

			pos = bodies[spec.parent].pos + {start_dist, 0}
			vel = bodies[spec.parent].vel + {0, start_speed}

			T := 2 * math.PI * math.sqrt(math.pow(f64(spec.semi_major_axis), f64(3)) / (G * bodies[spec.parent].mass))
			steps_per_orbit = T / DT

			stride = math.max(1, int(math.ceil(TRAIL_FRACTION * steps_per_orbit / TRAIL_CAP)))
		}

		body := Body {
			spec.name,
			spec.color,
			pos,
			vel,
			spec.mass,
			spec.radius
		}

		trail := Trail {
			parent = spec.parent,
			cap = int(TRAIL_FRACTION * steps_per_orbit / f64(stride)),
			stride = stride
		}

		assert(trail.cap <= TRAIL_CAP, spec.name)

		append(&bodies, body)
		append(&trails, trail)
	}

	largest_mass_index := 1
    for i in 2..<len(bodies) {
        if bodies[i].mass > bodies[largest_mass_index].mass do largest_mass_index = i
    }

    // Copy the most massive body cap / stride to the Sun
	trails[0].cap = trails[largest_mass_index].cap
	trails[0].stride = trails[largest_mass_index].stride

	total_mass: f64
	momentum_sum := [2]f64{0, 0}
	for &body in bodies {
		total_mass += body.mass
    	momentum_sum += body.mass * body.vel
	}

	// Barycenter velocity
	v_cm := momentum_sum / total_mass
	for &body in bodies {
		body.vel -= v_cm
	}

	return bodies, trails
}
