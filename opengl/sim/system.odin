package main

import "core:math"

BodySpec :: struct {
	mass: f64,
	radius: f64,
	orbit_r: f64,
	parent: int,
	name: string
}

specs := []BodySpec {
	BodySpec {
		mass = 1.0,
		radius = 4.654e-3,
		orbit_r = 0,
		parent = -1,
		name = "Sun"
	},
	BodySpec {
		mass = 3.003 * math.pow10(f64(-6.0)),
		radius = 4.259e-5,
		orbit_r = 1,
		parent = 0,
		name = "Earth"
	},
	BodySpec {
		mass = 3.69 * math.pow10(f64(-8.0)),
		radius = 1.161e-5,
		orbit_r = 2.570 * math.pow10(f64(-3)),
		parent = 1,
		name = "Moon"
	}
}

create_system :: proc() -> (bodies: [dynamic]Body, trails: [dynamic]Trail) {
	for &spec, i in specs {
		pos: [2]f64 = {0.0, 0.0}
		vel: [2]f64 = {0.0, 0.0}
		speed: f64 = 0.0
		frames_per_orbit: f64 = 0.0

		if spec.parent >= 0  {
			speed = math.sqrt(G * bodies[spec.parent].mass / spec.orbit_r)
			pos = bodies[spec.parent].pos + {spec.orbit_r, 0}
			vel = bodies[spec.parent].vel + {0, speed}

			T := 2 * math.PI * spec.orbit_r / speed
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
