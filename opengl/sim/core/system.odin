package sim_core

Body_Spec :: struct {
	mass:              f64,
	radius:            f64,
	ecc:               f64,
	semi_major_axis:   f64,
	start_at_aphelion: bool,
	color:             Color,
	name:              string,
	satellites:        []Body_Spec,
}

@(rodata)
specs := []Body_Spec {
	Body_Spec {
		mass = 1.0,
		radius = 4.654e-3,
		ecc = 0,
		semi_major_axis = 0,
		color = PALETTE[.Sun],
		name = "Sun",
		satellites = {
			{
				mass = 1.660e-7,
				radius = 1.631e-5,
				ecc = 0.2056,
				semi_major_axis = 0.387,
				color = PALETTE[.Mercury],
				name = "Mercury",
			},
			{
				mass = 2.447e-6,
				radius = 4.045e-5,
				ecc = 0.0068,
				semi_major_axis = 0.723,
				color = PALETTE[.Venus],
				name = "Venus",
			},
			{
				mass = 3.003e-6,
				radius = 4.259e-5,
				ecc = 0.0167,
				semi_major_axis = 1,
				color = PALETTE[.Earth],
				name = "Earth",
				satellites = {
					{
						mass = 3.69e-8,
						radius = 1.161e-5,
						ecc = 0.0549,
						semi_major_axis = 2.570e-3,
						color = PALETTE[.Moon],
						name = "Moon",
					},
				},
			},
			{
				mass = 3.227e-7,
				radius = 2.266e-5,
				ecc = 0.0934,
				semi_major_axis = 1.524,
				color = PALETTE[.Mars],
				name = "Mars",
			},
			{
				mass = 9.545e-4,
				radius = 4.673e-4,
				ecc = 0.0489,
				semi_major_axis = 5.203,
				color = PALETTE[.Jupiter],
				name = "Jupiter",
				satellites = {
					{
						mass = 4.49e-8,
						radius = 1.218e-5,
						ecc = 0.0041,
						semi_major_axis = 2.819e-3,
						color = PALETTE[.Moon],
						name = "Io",
					},
					{
						mass = 2.41e-8,
						radius = 1.043e-5,
						ecc = 0.0094,
						semi_major_axis = 4.486e-3,
						color = PALETTE[.Moon],
						name = "Europa",
					},
					{
						mass = 7.45e-8,
						radius = 1.761e-5,
						ecc = 0.0013,
						semi_major_axis = 7.155e-3,
						color = PALETTE[.Moon],
						name = "Ganymede",
					},
					{
						mass = 5.41e-8,
						radius = 1.611e-5,
						ecc = 0.0074,
						semi_major_axis = 1.259e-2,
						color = PALETTE[.Moon],
						name = "Callisto",
					},
				},
			},
			{
				mass = 2.858e-4,
				radius = 3.893e-4,
				ecc = 0.0565,
				semi_major_axis = 9.537,
				color = PALETTE[.Saturn],
				name = "Saturn",
			},
			{
				mass = 4.366e-5,
				radius = 1.695e-4,
				ecc = 0.0457,
				semi_major_axis = 19.19,
				color = PALETTE[.Uranus],
				name = "Uranus",
			},
			{
				mass = 5.150e-5,
				radius = 1.646e-4,
				ecc = 0.0113,
				semi_major_axis = 30.07,
				color = PALETTE[.Neptune],
				name = "Neptune",
			},
			{
				mass = 6.55e-9,
				radius = 7.94e-6,
				ecc = 0.2488,
				semi_major_axis = 39.48,
				start_at_aphelion = true,
				color = PALETTE[.Pluto],
				name = "Pluto",
			},
		},
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
	trails[0].cap = trails[largest_mass_index].cap
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
