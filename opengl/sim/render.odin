package main

import gl "vendor:OpenGL"
import "core:math"

Mesh :: struct {
	vao: u32,
	vbo: u32,
	vertex_count: i32,
	primitive: u32
}

create_circle_mesh :: proc(segments: i32) -> Mesh {
	VBO, VAO: u32

	vertices: [dynamic]f32
	defer delete(vertices)

	radius: f32 = 1.0
	origin_x: f32 = 0.0
	origin_y: f32 = 0.0

	append(&vertices, origin_x, origin_y)

	for i := 0; i <= int(segments); i += 1 {
		angle := f32(i) * (2 * math.PI / f32(segments))

		x := origin_x + f32(radius) * math.cos(angle)
		y := origin_y + f32(radius) * math.sin(angle)

		append(&vertices, x, y)
	}

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.BindVertexArray(VAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)

	mesh := Mesh {
		VAO,
		VBO,
		segments + 2,
		gl.TRIANGLE_FAN
	}

	return mesh
}

draw_bodies :: proc(bodies: []Body, mesh: Mesh, program: u32, width: i32, height: i32) {
	gl.BindVertexArray(mesh.vao)

	for &body in bodies {
		shader_set_vec2(program, "offset", body.pos.x, body.pos.y)
		shader_set_float(program, "scale", body.size)
		shader_set_float(program, "aspect", f32(height) / f32(width))

		gl.DrawArrays(mesh.primitive, 0, mesh.vertex_count)
	}
}
