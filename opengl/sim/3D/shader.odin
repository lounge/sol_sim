package main

import "core:fmt"
import gl "vendor:OpenGL"

Body_Program :: struct {
	id:           u32,
	mv:           i32,
	proj:         i32,
	sun_pos_view: i32,
	emissive:     i32,
	lit:          i32,
	color:        i32,
}

Trail_Program :: struct {
	id:    u32,
	mvp:   i32,
	color: i32,
	count: i32,
}

body_program_load :: proc(program: u32) -> Body_Program {
	mv := gl.GetUniformLocation(program, "mv")
	if mv == -1 {
		fmt.println("body_program mv uniform could not load")
	}

	proj := gl.GetUniformLocation(program, "proj")
	if proj == -1 {
		fmt.println("body_program proj uniform could not load")
	}

	sun_pos_view := gl.GetUniformLocation(program, "sun_pos_view")
	if sun_pos_view == -1 {
		fmt.println("body_program sun_pos_view uniform could not load")
	}

	emissive := gl.GetUniformLocation(program, "emissive")
	if emissive == -1 {
		fmt.println("body_program emissive uniform could not load")
	}

	lit := gl.GetUniformLocation(program, "lit")
	if lit == -1 {
		fmt.println("body_program lit uniform could not load")
	}

	color := gl.GetUniformLocation(program, "color")
	if color == -1 {
		fmt.println("body_program color uniform could not load")
	}

	program := Body_Program {
		id           = program,
		mv           = mv,
		proj         = proj,
		emissive     = emissive,
		lit          = lit,
		sun_pos_view = sun_pos_view,
		color        = color,
	}

	return program
}

trail_program_load :: proc(program: u32) -> Trail_Program {
	mvp := gl.GetUniformLocation(program, "mvp")
	if mvp == -1 {
		fmt.println("trail_program mvp uniform could not load")
	}

	color := gl.GetUniformLocation(program, "color")
	if color == -1 {
		fmt.println("trail_program color uniform could not load")
	}

	count := gl.GetUniformLocation(program, "count")
	if count == -1 {
		fmt.println("trail_program count uniform could not load")
	}

	program := Trail_Program {
		id    = program,
		mvp   = mvp,
		color = color,
		count = count,
	}

	return program
}


shader_set_int :: proc(location: i32, value: i32) {
	gl.Uniform1i(location, value)
}

shader_set_vec3 :: proc(location: i32, x: f32, y: f32, z: f32) {
	gl.Uniform3f(location, x, y, z)
}

shader_set_mat4 :: proc(location: i32, value: ^matrix[4, 4]f32) {
	gl.UniformMatrix4fv(location, 1, false, &value[0, 0])
}
