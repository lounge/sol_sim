package sim_core

EARTH :: Body_Spec {
	mass            = 3.003e-6,
	radius          = 4.259e-5,
	eccentricity    = 0.0167,
	semi_major_axis = 1,
	inclination     = 0.000,
	lon_asc_node    = 0,
	arg_perihelion  = 0,
	color           = PALETTE[.Earth],
	name            = "Earth",
	satellites      = {
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
}
