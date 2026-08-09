package main

import sim "../core"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

MIN_MARKER_PX :: 4
MIN_STAR_MASS :: 0.08

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

	projection32 := (matrix[4, 4]f32)(projection)
	shader_set_mat4(program.proj, &projection32)

	light_index, lit := light_scan(bodies)
	shader_set_int(program.lit, i32(lit))

	sun_rel := pos_render(bodies[light_index], alpha) - eye
	sun_pos_view := view * [4]f64{sun_rel.x, sun_rel.y, sun_rel.z, 1}

	if lit {
		shader_set_vec3(
			program.sun_pos_view,
			f32(sun_pos_view.x),
			f32(sun_pos_view.y),
			f32(sun_pos_view.z),
		)
	}


	for body, i in bodies {
		rel := pos_render(body, alpha) - eye
		center_view := view * [4]f64{rel.x, rel.y, rel.z, 1}
		depth := -center_view.z

		emissive := (lit && i == light_index) ? 1 : 0
		shader_set_int(program.emissive, i32(emissive))

		circle_draw(
			body.radius,
			body.color,
			mesh,
			program,
			camera_state,
			center_view,
			depth,
			projection,
			height,
		)


	}
}

circle_draw :: proc(
	radius: f64,
	color: sim.Color,
	mesh: Mesh,
	program: Body_Program,
	camera: ^Camera,
	center_view: [4]f64,
	depth: f64,
	projection: matrix[4, 4]f64,
	height: i32,
) {
	draw_radius := math.max(
		radius,
		MIN_MARKER_PX * depth * math.tan_f64(CAMERA_FOV / 2) / (f64(height) / 2),
	)

	mv :=
		linalg.matrix4_translate(center_view.xyz) *
		linalg.matrix4_scale_f64({draw_radius, draw_radius, draw_radius})
	mv32 := (matrix[4, 4]f32)(mv)

	shader_set_vec3(program.color, color.x, color.y, color.z)
	shader_set_mat4(program.mv, &mv32)

	gl.DrawArrays(mesh.primitive, 0, mesh.vertex_count)
}

drag_preview_draw :: proc(
	start_world, end_world: World_Pos,
	mesh: Mesh,
	program: Trail_Program,
	camera: ^Camera,
	width, height: i32,
) {
	scratch_buffer: [2][3]f32

	eye := camera_eye(camera^)
	view := camera_view(camera^)
	projection := camera_projection(camera^, f64(width) / f64(height)) * view
	projection32 := (matrix[4, 4]f32)(projection)

	a := [3]f64{start_world.x, start_world.y, 0} - eye
	b := [3]f64{end_world.x, end_world.y, 0} - eye

	scratch_buffer[0] = {f32(a.x), f32(a.y), f32(a.z)}
	scratch_buffer[1] = {f32(b.x), f32(b.y), f32(b.z)}

	gl.DepthMask(gl.FALSE)
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)

	shader_set_mat4(program.mvp, &projection32)
	shader_set_vec3(program.color, 1, 1, 1)
	shader_set_int(program.count, 1)

	gl.BufferData(gl.ARRAY_BUFFER, (sim.TRAIL_CAP + 1) * 3 * size_of(f32), nil, gl.STREAM_DRAW)
	gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(scratch_buffer), raw_data(&scratch_buffer))

	gl.DrawArrays(gl.LINE_STRIP, 0, 2)
	gl.DepthMask(gl.TRUE)
}

mass_preview_draw :: proc(
	world: World_Pos,
	radius: f64,
	mesh: Mesh,
	program: Body_Program,
	camera: ^Camera,
	width, height: i32,
) {
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	eye := camera_eye(camera^)
	view := camera_view(camera^)
	projection := camera_projection(camera^, f64(width) / f64(height))

	rel := [3]f64{world.x, world.y, 0} - eye
	center_view := view * [4]f64{rel.x, rel.y, rel.z, 1}
	depth := -center_view.zx

	shader_set_int(program.emissive, 1)
	circle_draw(
		radius,
		sim.PALETTE[.Spawn],
		mesh,
		program,
		camera,
		center_view,
		depth[0],
		projection,
		height,
	)
}


pos_render :: proc(body: sim.Body, alpha: f64) -> [3]f64 {
	return body.prev_pos + (body.pos - body.prev_pos) * alpha
}

light_scan :: proc(bodies: []sim.Body) -> (index: int, lit: bool) {
	if len(bodies) == 0 {
		return -1, false
	}

	index = 0
	for i in 1 ..< len(bodies) {
		if bodies[i].mass > bodies[index].mass {
			index = i
		}
	}

	return index, bodies[index].mass >= MIN_STAR_MASS
}


gl_check_error :: proc(loc := #caller_location) {
	when ODIN_DEBUG {
		for err := gl.GetError(); err != gl.NO_ERROR; err = gl.GetError() {
			fmt.printfln("GL Error 0x%x at %v", err, loc)
		}
	}
}
