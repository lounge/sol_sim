package sim_core

NEPTUNE :: Body_Spec {
	mass            = 5.150e-5,
	radius          = 1.646e-4,
	eccentricity    = 0.011112,
	mean_anomaly    = 313.958,
	semi_major_axis = 30.1151345,
	inclination     = 1.7706,
	lon_asc_node    = 131.8,
	arg_perihelion  = 276.1762,
	rotation_period = 0.67125, // 16.11 h
	color           = PALETTE[.Neptune],
	name            = "Neptune",
	satellites      = {
		{
			mass = 1.075e-8,
			radius = 9.047e-6,
			eccentricity = 0.000138,
			mean_anomaly = 307.4759,
			semi_major_axis = 2.37146586e-3,
			inclination = 129.1481,
			lon_asc_node = 222.662,
			arg_perihelion = 102.1705,
			rotation_period = -5.8769,
			color = PALETTE[.Moon],
			name = "Triton",
		},
	},
}
