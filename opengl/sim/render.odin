package main

import gl "vendor:OpenGL"
import "core:math"

Mesh :: struct {
	vao: u32,
	vbo: u32,
	vertex_count: i32,
	primitive: u32
}

Trail :: struct {
	points: [TRAIL_CAP][2]f64,
	head: int,
	count: int,
	parent: int,
	cap: int,
	stride: int,
	frame_count: int
}

record_trail :: proc(bodies: []Body, trails: []Trail) {
	for &body, i in bodies {
		trail := &trails[i]

		trail.frame_count += 1
		if trail.frame_count >= trail.stride {
			trail.points[trail.head] = body.pos

			if trail.parent >= 0 {
				trail.points[trail.head] = body.pos - bodies[trail.parent].pos
			}

			trail.head = (trail.head + 1) % trail.cap
			trail.count = min(trail.count + 1, trail.cap)
		}

		trail.frame_count %= trail.stride
	}
}

create_trail_mesh :: proc() -> Mesh {
	VBO, VAO: u32

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.BindVertexArray(VAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, (TRAIL_CAP + 1) * 2 * size_of(f32), nil, gl.DYNAMIC_DRAW)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)

	mesh := Mesh {
		VAO,
		VBO,
		0,
		gl.LINE_STRIP
	}

	return mesh
}

draw_trails :: proc(trails: []Trail, bodies: []Body, mesh: Mesh, program: u32, camera: Camera,  width: i32, height: i32, alpha: f64) {
	scratch_buffer: [TRAIL_CAP + 1][2]f32

	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)

	shader_set_vec2(program, "offset", f32(0.0), f32(0.0))
	shader_set_float(program, "scale", f32(1))
	shader_set_float(program, "aspect", f32(height) / f32(width))

	for trail, i in trails {
		if trail.count == 0 do continue

		oldest_point := 0
		body := bodies[i]

		if trail.count == trail.cap {
			oldest_point = trail.head
		}

		for j := 0; j < trail.count ; j += 1 {
			point := trail.points[(oldest_point + j) % trail.cap]

			point_pos := point
		 	if trail.parent >= 0 {
				world := render_pos(bodies[trail.parent], alpha)
				point_pos = point + world
			}

			ndc_pos := calc_ndc_offset(point_pos, camera)
			scratch_buffer[j] = [2]f32{f32(ndc_pos.x),f32(ndc_pos.y)}
		}

		world := render_pos(bodies[i], alpha)
		ndc := calc_ndc_offset(world, camera)
		scratch_buffer[trail.count] = {f32(ndc.x), f32(ndc.y)}

		color := body.color
		trail_count := trail.count + 1

		shader_set_vec3(program, "color", color.x, color.y, color.z)
		shader_set_int(program, "count", i32(trail_count))

		gl.BufferSubData(gl.ARRAY_BUFFER, 0, trail_count  * 2 * size_of(f32), raw_data(&scratch_buffer))
		gl.DrawArrays(mesh.primitive, 0, i32(trail_count))
	}
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

draw_bodies :: proc(bodies: []Body, mesh: Mesh, program: u32, camera: Camera,  width: i32, height: i32, alpha: f64) {
	gl.BindVertexArray(mesh.vao)

	for &body in bodies {
		world := render_pos(body, alpha)
		ndc_pos := calc_ndc_offset(world, camera)
		shader_set_vec2(program, "offset", f32(ndc_pos.x), f32(ndc_pos.y))

		ndc_scale := calc_ndc_scale(body.radius, height, camera)
		shader_set_float(program, "scale", f32(ndc_scale))
		shader_set_float(program, "aspect", f32(height) / f32(width))
		shader_set_vec3(program, "color", body.color.x, body.color.y, body.color.z)

		gl.DrawArrays(mesh.primitive, 0, mesh.vertex_count)
	}
}

// NDC: Normalized Device Coordinates
calc_ndc_offset :: proc(pos: [2]f64, camera: Camera) -> [2]f64 {
	ndc := (pos - camera.center) / camera.half_extent
	return ndc
}

calc_ndc_scale :: proc(radius: f64, height: i32, camera: Camera) -> f64 {
	min_marker := MIN_MARKER_PX / (f64(height) / 2)

	ndc := math.max(min_marker, radius / camera.half_extent)
	return ndc
}

calc_screen_pos :: proc(pos: [2]f64, camera: Camera, width, height: i32) -> [2]f64 {
	ndc := calc_ndc_offset(pos, camera)
	clip := [2]f64{ndc.x * f64(height) / f64(width), ndc.y}
	return {
		(clip.x + 1) * 0.5 * f64(width),
		(1- clip.y) * 0.5 * f64(height)
	}
}

render_pos :: proc(body: Body, alpha: f64) -> [2]f64 {
	return body.prev_pos + (body.pos - body.prev_pos) * alpha
}
