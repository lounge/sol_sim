package main

Color :: [3]f32

Body_Colors :: struct {
	Sun:     Color,
	Mercury: Color,
	Venus:   Color,
	Earth:   Color,
	Moon:    Color,
	Mars:    Color,
	Jupiter: Color,
	Saturn:  Color,
	Uranus:  Color,
	Neptune: Color,
	Pluto:   Color,
}

Color_Set :: struct {
	body: Body_Colors,
}

albedo: Color_Set = {
	body = {
		Sun     = {1.00, 0.84, 0.32},
		Mercury = {0.62, 0.60, 0.58},
		Venus   = {0.91, 0.86, 0.72},
		Earth   = {0.22, 0.45, 0.85},
		Moon    = {0.75, 0.75, 0.73},
		Mars    = {0.72, 0.36, 0.22},
		Jupiter = {0.78, 0.66, 0.50},
		Saturn  = {0.86, 0.78, 0.52},
		Uranus  = {0.56, 0.86, 0.90},
		Neptune = {0.18, 0.32, 0.78},
		Pluto   = {0.54, 0.48, 0.42},
	},
}

realistic: Color_Set = {
	body = {
		Sun     = {1.00, 0.78, 0.30},
		Mercury = {0.45, 0.43, 0.41},
		Venus   = {0.82, 0.76, 0.62},
		Earth   = {0.20, 0.37, 0.62},
		Moon    = {0.58, 0.57, 0.54},
		Mars    = {0.60, 0.28, 0.17},
		Jupiter = {0.67, 0.56, 0.43},
		Saturn  = {0.76, 0.69, 0.49},
		Uranus  = {0.48, 0.75, 0.78},
		Neptune = {0.13, 0.24, 0.56},
		Pluto   = {0.40, 0.35, 0.31},
	},
}

vibrant: Color_Set = {
	body = {
		Sun     = {1.00, 0.88, 0.25},
		Mercury = {0.68, 0.66, 0.63},
		Venus   = {1.00, 0.90, 0.67},
		Earth   = {0.12, 0.45, 1.00},
		Moon    = {0.82, 0.82, 0.80},
		Mars    = {0.85, 0.30, 0.14},
		Jupiter = {0.88, 0.68, 0.43},
		Saturn  = {0.96, 0.82, 0.42},
		Uranus  = {0.40, 0.92, 1.00},
		Neptune = {0.08, 0.25, 0.95},
		Pluto   = {0.58, 0.47, 0.39},
	},
}
