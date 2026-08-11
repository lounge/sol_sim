package main

import "core:fmt"
import gl "vendor:OpenGL"

MAX_OCCLUDERS :: 32 // Needs to stay in sync with body frag shader

Body_Program :: struct {
	id:           u32,
	mv:           i32,
	proj:         i32,
	color:        i32,
	sun_pos_view: i32,
	emissive:     i32,
	lit:          i32,

	occluder_pos_view: i32,
	occluder_radius: i32,
	occluder_count: i32,
	sun_radius: i32,
	receiver_slot: i32,
	body_radius: i32,
}

Trail_Program :: struct {
	id:    u32,
	mvp:   i32,
	color: i32,
	count: i32,
}

body_program_load :: proc(program: u32) -> Body_Program {
	// mv := gl.GetUniformLocation(program, "mv")
	// if mv == -1 {
	// 	fmt.println("body_program mv uniform could not load")
	// }

	// proj := gl.GetUniformLocation(program, "proj")
	// if proj == -1 {
	// 	fmt.println("body_program proj uniform could not load")
	// }

	// sun_pos_view := gl.GetUniformLocation(program, "sun_pos_view")
	// if sun_pos_view == -1 {
	// 	fmt.println("body_program sun_pos_view uniform could not load")
	// }

	// emissive := gl.GetUniformLocation(program, "emissive")
	// if emissive == -1 {
	// 	fmt.println("body_program emissive uniform could not load")
	// }

	// lit := gl.GetUniformLocation(program, "lit")
	// if lit == -1 {
	// 	fmt.println("body_program lit uniform could not load")
	// }

	// color := gl.GetUniformLocation(program, "color")
	// if color == -1 {
	// 	fmt.println("body_program color uniform could not load")
	// }


	// occluder_pos_view := gl.GetUniformLocation(program, "occluder_pos_view")
	// if occluder_pos_view == -1 {
	// 	fmt.println("body_program occluder_pos_view uniform could not load")
	// }
	// occluder_radius := gl.GetUniformLocation(program, "occluder_radius")
	// if occluder_radius == -1 {
	// 	fmt.println("body_program occluder_radius uniform could not load")
	// }
	// occluder_count := gl.GetUniformLocation(program, "occluder_count")
	// if occluder_count == -1 {
	// 	fmt.println("body_program occluder_count uniform could not load")
	// }
	// sun_radius := gl.GetUniformLocation(program, "sun_radius")
	// if sun_radius == -1 {
	// 	fmt.println("body_program sun_radius uniform could not load")
	// }
	// receiver_slot := gl.GetUniformLocation(program, "receiver_slot")
	// if receiver_slot == -1 {
	// 	fmt.println("body_program receiver_slot uniform could not load")
	// }
	// body_radius := gl.GetUniformLocation(program, "body_radius")
	// if body_radius == -1 {
	// 	fmt.println("body_program body_radius uniform could not load")
	// }

	program := Body_Program {
		id           = program,
		mv           = uniform_lookup(program, "mv"),
		proj         = uniform_lookup(program, "proj"),
		color        = uniform_lookup(program, "color"),
		emissive     = uniform_lookup(program, "emissive"),
		lit          = uniform_lookup(program, "lit"),
		sun_pos_view = uniform_lookup(program, "sun_pos_view"),
		occluder_pos_view = uniform_lookup(program, "occluder_pos_view"),
		occluder_radius = uniform_lookup(program, "occluder_radius"),
		occluder_count = uniform_lookup(program, "occluder_count"),
		sun_radius = uniform_lookup(program, "sun_radius"),
		receiver_slot = uniform_lookup(program, "receiver_slot"),
		body_radius = uniform_lookup(program, "body_radius"),
	}

	return program
}

trail_program_load :: proc(program: u32) -> Trail_Program {
	// mvp := gl.GetUniformLocation(program, "mvp")
	// if mvp == -1 {
	// 	fmt.println("trail_program mvp uniform could not load")
	// }

	// color := gl.GetUniformLocation(program, "color")
	// if color == -1 {
	// 	fmt.println("trail_program color uniform could not load")
	// }

	// count := gl.GetUniformLocation(program, "count")
	// if count == -1 {
	// 	fmt.println("trail_program count uniform could not load")
	// }

	program := Trail_Program {
		id    = program,
		mvp   = uniform_lookup(program, "mvp"),
		color = uniform_lookup(program, "color"),
		count = uniform_lookup(program, "count"),
	}

	return program
}


uniform_lookup :: proc(program: u32, name: cstring) -> i32 {
	uniform := gl.GetUniformLocation(program, name)
	if uniform == -1 {
		fmt.printfln("program: %d, %s uniform could not load", program, name)
	}

	return uniform
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

shader_set_float :: proc(location: i32, value: f32) {
	gl.Uniform1f(location, value)
}

shader_set_float_array :: proc(location: i32, value: []f32) {
	gl.Uniform1fv(location, i32(len(value)), raw_data(value))
}

shader_set_vec3_array :: proc(location: i32, value: [][3]f32) {
	gl.Uniform3fv(location, i32(len(value)), cast([^]f32)raw_data(value))
}

shader_set :: proc {
	shader_set_int,
 	shader_set_vec3,
  	shader_set_mat4,
   shader_set_float,
   shader_set_float_array,
   shader_set_vec3_array,
}
