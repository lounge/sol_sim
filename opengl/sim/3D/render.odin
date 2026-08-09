package main

import sim "../core"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

MIN_MARKER_PX :: 4

Mesh :: struct {
	vao:          u32,
	vbo:          u32,
	vertex_count: i32,
	primitive:    u32,
}

Pixel_Pos :: distinct [2]f64
World_Pos :: distinct [2]f64

trail_mesh_create :: proc() -> Mesh {
	vbo, vao: u32

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, (sim.TRAIL_CAP + 1) * 3 * size_of(f32), nil, gl.STREAM_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)

	mesh := Mesh{vao, vbo, 0, gl.LINE_STRIP}

	return mesh
}

trails_draw :: proc(
	trails: []sim.Trail,
	bodies: []sim.Body,
	mesh: Mesh,
	program: Trail_Program,
	camera_state: ^Camera,
	width, height: i32,
	alpha: f64,
) {
	scratch_buffer: [sim.TRAIL_CAP + 1][3]f32

	gl.DepthMask(gl.FALSE)

	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	eye := camera_eye(camera_state^)
	view := camera_view(camera_state^)
	projection := camera_projection(camera_state^, f64(width) / f64(height)) * view

	mvp := (matrix[4, 4]f32)(projection)
	shader_set_mat4(program.mvp, &mvp)

	for trail, i in trails {
		if trail.count == 0 do continue

		oldest_point := 0
		body := bodies[i]

		if trail.count == len(trail.points) {
			oldest_point = trail.head
		}

		anchor: sim.Vec
		if trail.parent >= 0 {
			anchor = pos_render(bodies[trail.parent], alpha)
		}

		for j := 0; j < trail.count; j += 1 {
			point := trail.points[(oldest_point + j) % len(trail.points)]
			rel := anchor + point - eye
			scratch_buffer[j] = {f32(rel.x), f32(rel.y), f32(rel.z)}
		}

		tip := pos_render(bodies[i], alpha) - eye
		scratch_buffer[trail.count] = {f32(tip.x), f32(tip.y), f32(tip.z)}

		color := body.color
		trail_count := trail.count + 1

		shader_set_vec3(program.color, color.x, color.y, color.z)
		shader_set_int(program.count, i32(trail_count))

		gl.BufferData(gl.ARRAY_BUFFER, (sim.TRAIL_CAP + 1) * 3 * size_of(f32), nil, gl.STREAM_DRAW)

		gl.BufferSubData(
			gl.ARRAY_BUFFER,
			0,
			trail_count * 3 * size_of(f32),
			raw_data(&scratch_buffer),
		)
		gl.DrawArrays(mesh.primitive, 0, i32(trail_count))
	}

	gl.DepthMask(gl.TRUE)
}

circle_mesh_create :: proc(segments: i32) -> Mesh {
	vbo, vao: u32

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

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(f32),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)

	mesh := Mesh{vao, vbo, segments + 2, gl.TRIANGLE_FAN}

	return mesh
}

bodies_draw :: proc(
	bodies: []sim.Body,
	mesh: Mesh,
	program: Body_Program,
	camera_state: ^Camera,
	width, height: i32,
	alpha: f64,
) {
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	eye := camera_eye(camera_state^)
	view := camera_view(camera_state^)
	projection := camera_projection(camera_state^, f64(width) / f64(height))

	for &body in bodies {
		rel := pos_render(body, alpha) - eye
		center_view := view * [4]f64{rel.x, rel.y, rel.z, 1}
		depth := -center_view.z
		circle_draw(body, mesh, program, camera_state, center_view, depth, projection, height)
	}
}

circle_draw :: proc(
	body: sim.Body,
	mesh: Mesh,
	program: Body_Program,
	camera: ^Camera,
	center_view: [4]f64,
	depth: f64,
	projection: matrix[4, 4]f64,
	height: i32,
) {
	radius := math.max(
		body.radius,
		MIN_MARKER_PX * depth * math.tan_f64(CAMERA_FOV / 2) / (f64(height) / 2),
	)
	mvp :=
		projection *
		linalg.matrix4_translate_f64(center_view.xyz) *
		linalg.matrix4_scale_f64({radius, radius, radius})

	mvp32 := (matrix[4, 4]f32)(mvp)

	shader_set_vec3(program.color, body.color.x, body.color.y, body.color.z)
	shader_set_mat4(program.mvp, &mvp32)

	gl.DrawArrays(mesh.primitive, 0, mesh.vertex_count)
}


pos_render :: proc(body: sim.Body, alpha: f64) -> [3]f64 {
	return body.prev_pos + (body.pos - body.prev_pos) * alpha
}


gl_check_error :: proc(loc := #caller_location) {
	when ODIN_DEBUG {
		for err := gl.GetError(); err != gl.NO_ERROR; err = gl.GetError() {
			fmt.printfln("GL Error 0x%x at %v", err, loc)
		}
	}
}
