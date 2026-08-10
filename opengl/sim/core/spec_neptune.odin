package sim_core

NEPTUNE :: Body_Spec {
	mass            = 5.150e-5,
	radius          = 1.646e-4,
	eccentricity    = 0.010964,
	mean_anomaly    = 312.7649,
	semi_major_axis = 30.1069637,
	inclination     = 1.7739,
	lon_asc_node    = 131.9235,
	arg_perihelion  = 277.2514,
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
			color = PALETTE[.Moon],
			name = "Triton",
		},
	},
}
