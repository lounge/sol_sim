package sim_core

EARTH :: Body_Spec {
	mass            = 3.003e-6,
	radius          = 4.259e-5,
	eccentricity    = 0.016670,
	mean_anomaly    = 357.2702,
	semi_major_axis = 1.00000189,
	inclination     = 0.0034,
	lon_asc_node    = 174.9687,
	arg_perihelion  = 288.0618,
	rotation_period = 0.99727, // 23.934 h
	color           = PALETTE[.Earth],
	name            = "Earth",
	satellites      = {
		{
			mass = 3.69e-8,
			radius = 1.161e-5,
			eccentricity = 0.062936,
			mean_anomaly = 346.5525,
			semi_major_axis = 2.57001538e-3,
			inclination = 5.0596,
			lon_asc_node = 340.5846,
			arg_perihelion = 101.0339,
			rotation_period = 27.3217,
			color = PALETTE[.Moon],
			name = "Moon",
		},
	},
}
