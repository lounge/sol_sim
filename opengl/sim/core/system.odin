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
		satellites = {
			{
				mass = 1.660e-7,
				radius = 1.631e-5,
				eccentricity = 0.2056,
				semi_major_axis = 0.387,
				inclination = 7.005,
				lon_asc_node = 48.33,
				arg_perihelion = 29.12,
				color = PALETTE[.Mercury],
				name = "Mercury",
			},
			{
				mass = 2.447e-6,
				radius = 4.045e-5,
				eccentricity = 0.0068,
				semi_major_axis = 0.723,
				inclination = 3.395,
				lon_asc_node = 76.68,
				arg_perihelion = 54.88,
				color = PALETTE[.Venus],
				name = "Venus",
			},
			{
				mass = 3.003e-6,
				radius = 4.259e-5,
				eccentricity = 0.0167,
				semi_major_axis = 1,
				inclination = 0.000,
				lon_asc_node = 0,
				arg_perihelion = 0,
				color = PALETTE[.Earth],
				name = "Earth",
				satellites = {
					{
						mass = 3.69e-8,
						radius = 1.161e-5,
						eccentricity = 0.0549,
						semi_major_axis = 2.570e-3,
						inclination = 5.145,
						lon_asc_node = 0,
						arg_perihelion = 0,
						color = PALETTE[.Moon],
						name = "Moon",
					},
				},
			},
			{
				mass = 3.227e-7,
				radius = 2.266e-5,
				eccentricity = 0.0934,
				semi_major_axis = 1.524,
				inclination = 1.850,
				lon_asc_node = 49.56,
				arg_perihelion = 286.5,
				color = PALETTE[.Mars],
				name = "Mars",
			},
			{
				mass = 9.545e-4,
				radius = 4.673e-4,
				eccentricity = 0.0489,
				semi_major_axis = 5.203,
				inclination = 1.303,
				lon_asc_node = 100.46,
				arg_perihelion = 273.9,
				color = PALETTE[.Jupiter],
				name = "Jupiter",
				satellites = {
					{
						mass = 4.49e-8,
						radius = 1.218e-5,
						eccentricity = 0.0041,
						semi_major_axis = 2.819e-3,
						color = PALETTE[.Moon],
						name = "Io",
					},
					{
						mass = 2.41e-8,
						radius = 1.043e-5,
						eccentricity = 0.0094,
						semi_major_axis = 4.486e-3,
						color = PALETTE[.Moon],
						name = "Europa",
					},
					{
						mass = 7.45e-8,
						radius = 1.761e-5,
						eccentricity = 0.0013,
						semi_major_axis = 7.155e-3,
						color = PALETTE[.Moon],
						name = "Ganymede",
					},
					{
						mass = 5.41e-8,
						radius = 1.611e-5,
						eccentricity = 0.0074,
						semi_major_axis = 1.259e-2,
						color = PALETTE[.Moon],
						name = "Callisto",
					},
				},
			},
			{
				mass = 2.858e-4,
				radius = 3.893e-4,
				eccentricity = 0.0565,
				semi_major_axis = 9.537,
				inclination = 2.485,
				lon_asc_node = 113.67,
				arg_perihelion = 338.9,
				color = PALETTE[.Saturn],
				name = "Saturn",
				// Titan/Rhea ride Saturn's equatorial plane (28.05/169.53 in
				// ecliptic terms, from the IAU pole); Iapetus rides its own
				// Laplace plane between equator and orbit.
				satellites = {
					{
						mass = 6.763e-8,
						radius = 1.721e-5,
						eccentricity = 0.0288,
						semi_major_axis = 8.168e-3,
						inclination = 28.05,
						lon_asc_node = 169.53,
						color = PALETTE[.Moon],
						name = "Titan",
					},
					{
						mass = 1.160e-9,
						radius = 5.106e-6,
						eccentricity = 0.001,
						semi_major_axis = 3.523e-3,
						inclination = 28.05,
						lon_asc_node = 169.53,
						color = PALETTE[.Moon],
						name = "Rhea",
					},
					{
						mass = 9.08e-10,
						radius = 4.910e-6,
						eccentricity = 0.0277,
						semi_major_axis = 2.380e-2,
						inclination = 17.28,
						lon_asc_node = 225.0,
						color = PALETTE[.Moon],
						name = "Iapetus",
					},
				},
			},
			{
				mass = 4.366e-5,
				radius = 1.695e-4,
				eccentricity = 0.0457,
				semi_major_axis = 19.19,
				inclination = 0.773,
				lon_asc_node = 74.01,
				arg_perihelion = 96.9,
				color = PALETTE[.Uranus],
				name = "Uranus",
				// All three ride Uranus's equatorial plane — tipped 97.72 to
				// the ecliptic (the sideways system). The IAU pole gives the
				// invariable-plane north; Uranus spins retrograde, so the
				// moons' orbit normal is the flipped pole: 180 - 82.28, node
				// + 180.
				satellites = {
					{
						mass = 3.31e-11,
						radius = 1.576e-6,
						eccentricity = 0.0013,
						semi_major_axis = 8.649e-4,
						inclination = 97.72,
						lon_asc_node = 167.65,
						color = PALETTE[.Moon],
						name = "Miranda",
					},
					{
						mass = 1.71e-9,
						radius = 5.273e-6,
						eccentricity = 0.0011,
						semi_major_axis = 2.914e-3,
						inclination = 97.72,
						lon_asc_node = 167.65,
						color = PALETTE[.Moon],
						name = "Titania",
					},
					{
						mass = 1.55e-9,
						radius = 5.090e-6,
						eccentricity = 0.0014,
						semi_major_axis = 3.901e-3,
						inclination = 97.72,
						lon_asc_node = 167.65,
						color = PALETTE[.Moon],
						name = "Oberon",
					},
				},
			},
			{
				mass = 5.150e-5,
				radius = 1.646e-4,
				eccentricity = 0.0113,
				semi_major_axis = 30.07,
				inclination = 1.770,
				lon_asc_node = 131.78,
				arg_perihelion = 273.2,
				color = PALETTE[.Neptune],
				name = "Neptune",
				satellites = {
					{
						// Retrograde (i > 90): Horizons osculating elements,
						// 2026-01-01 epoch — the node precesses on a ~688 yr
						// cycle, so this is a snapshot.
						mass = 1.075e-8,
						radius = 9.047e-6,
						eccentricity = 0,
						semi_major_axis = 2.371e-3,
						inclination = 129.15,
						lon_asc_node = 222.66,
						color = PALETTE[.Moon],
						name = "Triton",
					},
				},
			},
			{
				mass = 6.55e-9,
				radius = 7.94e-6,
				eccentricity = 0.2488,
				semi_major_axis = 39.48,
				inclination = 17.16,
				lon_asc_node = 110.30,
				arg_perihelion = 113.8,
				color = PALETTE[.Pluto],
				name = "Pluto",
				satellites = {
					{
						// 1/8 of Pluto's mass — a binary, not a moon: the
						// barycenter sits outside Pluto. Rides Pluto's
						// equatorial plane (112.82: Pluto spins retrograde).
						mass = 7.97e-10,
						radius = 4.051e-6,
						eccentricity = 0.0002,
						semi_major_axis = 1.310e-4,
						inclination = 112.82,
						lon_asc_node = 227.35,
						color = PALETTE[.Moon],
						name = "Charon",
					},
				},
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
