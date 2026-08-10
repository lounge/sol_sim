package sim_core

PLUTO :: Body_Spec {
	mass            = 6.55e-9,
	radius          = 7.94e-6,
	eccentricity    = 0.2488,
	semi_major_axis = 39.48,
	inclination     = 17.16,
	lon_asc_node    = 110.30,
	arg_perihelion  = 113.8,
	color           = PALETTE[.Pluto],
	name            = "Pluto",
	satellites      = {
		{
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
}
