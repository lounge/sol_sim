package main

import "core:fmt"
import gl "vendor:OpenGL"

Body_Program :: struct {
	id:    u32,
	mvp:   i32,
	color: i32,
}

Trail_Program :: struct {
	id:     u32,
	offset: i32,
	scale:  i32,
	aspect: i32,
	color:  i32,
	count:  i32,
}

body_program_load :: proc(program: u32) -> Body_Program {


	mvp := gl.GetUniformLocation(program, "mvp")
	if mvp == -1 {
		fmt.println("body_program mvp uniform could not load")
	}

	color := gl.GetUniformLocation(program, "color")
	if color == -1 {
		fmt.println("body_program color uniform could not load")
	}

	program := Body_Program {
		id    = program,
		mvp   = mvp,
		color = color,
	}

	return program
}

trail_program_load :: proc(program: u32) -> Trail_Program {
	offset := gl.GetUniformLocation(program, "offset")
	if offset == -1 {
		fmt.println("trail_program offset uniform could not load")
	}

	scale := gl.GetUniformLocation(program, "scale")
	if scale == -1 {
		fmt.println("trail_program scale uniform could not load")
	}

	aspect := gl.GetUniformLocation(program, "aspect")
	if aspect == -1 {
		fmt.println("trail_program aspect uniform could not load")
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
		id     = program,
		offset = offset,
		scale  = scale,
		aspect = aspect,
		color  = color,
		count  = count,
	}

	return program
}


shader_set_int :: proc(location: i32, value: i32) {
	gl.Uniform1i(location, value)
}

shader_set_float :: proc(location: i32, value: f32) {
	gl.Uniform1f(location, value)
}

shader_set_vec2 :: proc(location: i32, x: f32, y: f32) {
	gl.Uniform2f(location, x, y)
}

shader_set_vec3 :: proc(location: i32, x: f32, y: f32, z: f32) {
	gl.Uniform3f(location, x, y, z)
}

shader_set_mat4 :: proc(location: i32, value: ^matrix[4, 4]f32) {
	gl.UniformMatrix4fv(location, 1, false, &value[0, 0])
}
