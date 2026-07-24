package main

import gl "vendor:OpenGL"


shader_set_int :: proc(id: u32, name: cstring, value: i32) {
	gl.Uniform1i(gl.GetUniformLocation(id, name), value)
}

shader_set_float :: proc(id: u32, name: cstring, value: f32) {
	gl.Uniform1f(gl.GetUniformLocation(id, name), value)
}

shader_set_vec2 :: proc(id: u32, name: cstring, x: f32, y: f32) {
	gl.Uniform2f(gl.GetUniformLocation(id, name), x, y)
}

shader_set_vec3 :: proc(id: u32, name: cstring, x: f32, y: f32, z: f32) {
	gl.Uniform3f(gl.GetUniformLocation(id, name), x, y, z)
}
