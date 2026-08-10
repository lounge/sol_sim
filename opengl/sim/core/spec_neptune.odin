package sim_core

NEPTUNE :: Body_Spec {
	mass            = 5.150e-5,
	radius          = 1.646e-4,
	eccentricity    = 0.0113,
	semi_major_axis = 30.07,
	inclination     = 1.770,
	lon_asc_node    = 131.78,
	arg_perihelion  = 273.2,
	color           = PALETTE[.Neptune],
	name            = "Neptune",
	satellites      = {
		{
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
}
