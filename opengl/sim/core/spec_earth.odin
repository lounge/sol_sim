package sim_core

EARTH :: Body_Spec {
	mass            = 3.003e-6,
	radius          = 4.259e-5,
	eccentricity    = 0.015914,
	mean_anomaly    = 356.3524,
	semi_major_axis = 0.999194905,
	inclination     = 0.0035,
	lon_asc_node    = 177.6179,
	arg_perihelion  = 286.3569,
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
			color = PALETTE[.Moon],
			name = "Moon",
		},
	},
}
