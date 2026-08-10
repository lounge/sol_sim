package sim_core

PLUTO :: Body_Spec {
	mass            = 6.55e-9,
	radius          = 7.94e-6,
	eccentricity    = 0.247454,
	mean_anomaly    = 51.8352,
	semi_major_axis = 39.6192863,
	inclination     = 17.0299,
	lon_asc_node    = 110.2194,
	arg_perihelion  = 114.9681,
	color           = PALETTE[.Pluto],
	name            = "Pluto",
	satellites      = {
		{
			mass = 7.97e-10,
			radius = 4.051e-6,
			eccentricity = 0.00016,
			mean_anomaly = 75.5547,
			semi_major_axis = 1.30989571e-4,
			inclination = 112.8878,
			lon_asc_node = 227.393,
			arg_perihelion = 172.4679,
			color = PALETTE[.Moon],
			name = "Charon",
		},
	},
}
