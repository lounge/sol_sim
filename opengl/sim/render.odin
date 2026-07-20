package main

import gl "vendor:OpenGL"
import "core:math"

SEGMENTS :: 32

create_circle_vertices :: proc() -> [dynamic]f32 {
	vertices: [dynamic]f32

	radius: f32 = 1.0
	origin_x: f32 = 0.0
	origin_y: f32 = 0.0

	append(&vertices, origin_x, origin_y)

	for i := 0; i <= SEGMENTS; i += 1 {
		angle := f32(i) * (2 * math.PI / f32(SEGMENTS))

		x := origin_x + f32(radius) * math.cos(angle)
		y := origin_y + f32(radius) * math.sin(angle)

		append(&vertices, x, y)
	}

	return vertices
}

draw_bodies :: proc(bodies: []Body, program: u32, width: i32, height: i32) {
	for &body in bodies {
		shader_set_vec2(program, "offset", body.pos.x, body.pos.y)
		shader_set_float(program, "scale", body.size)
		shader_set_float(program, "aspect", f32(height) / f32(width))

		gl.DrawArrays(gl.TRIANGLE_FAN, 0, i32(SEGMENTS + 2))
	}
}
