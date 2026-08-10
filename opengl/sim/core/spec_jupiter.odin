package sim_core

JUPITER :: Body_Spec {
	mass            = 9.545e-4,
	radius          = 4.673e-4,
	eccentricity    = 0.0489,
	semi_major_axis = 5.203,
	inclination     = 1.303,
	lon_asc_node    = 100.46,
	arg_perihelion  = 273.9,
	color           = PALETTE[.Jupiter],
	name            = "Jupiter",
	satellites      = {
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
}
