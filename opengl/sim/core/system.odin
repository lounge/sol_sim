package sim_core

Body_Spec :: struct {
	mass:            f64,
	radius:          f64,
	eccentricity:    f64,
	semi_major_axis: f64,
	inclination:     f64,
	lon_asc_node:    f64,
	arg_perihelion:  f64,
	color:           Color,
	name:            string,
	satellites:      []Body_Spec,
}

@(rodata)
specs := []Body_Spec {
	Body_Spec {
		mass = 1.0,
		radius = 4.654e-3,
		eccentricity = 0,
		semi_major_axis = 0,
		color = PALETTE[.Sun],
		name = "Sun",
		satellites = {MERCURY, VENUS, EARTH, MARS, JUPITER, SATURN, URANUS, NEPTUNE, PLUTO},
	},
}

// TODO: Maybe handle multiple roots
create_system :: proc(tree: ^Gravity_Tree) -> (bodies: [dynamic]Body, trails: [dynamic]Trail) {
	assert(len(specs) == 1, "trails[0] cap fix-up assumes exactly one root")
	assert(len(specs[0].satellites) >= 1, "root requires at least 1 satellite")

	for spec in specs {
		body_add(spec, -1, &bodies, &trails)
	}

	largest_mass_index := 1
	for i in 2 ..< len(bodies) {
		if bodies[i].mass > bodies[largest_mass_index].mass do largest_mass_index = i
	}

	// Copy the most massive body cap / stride to the Sun
	delete(trails[0].points)

	trails[0].points = make([]Vec, len(trails[largest_mass_index].points))
	trails[0].stride = trails[largest_mass_index].stride

	total_mass: f64
	momentum_sum := Vec{}
	for &body in bodies {
		total_mass += body.mass
		momentum_sum += body.mass * body.vel
	}

	// Barycenter velocity
	v_cm := momentum_sum / total_mass
	for &body in bodies {
		body.vel -= v_cm
	}

	// Set priming force
	accels_compute(bodies[:], tree)

	return bodies, trails
}
