package main

import "core:fmt"
import "core:math"
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
	gl.BufferData(gl.ARRAY_BUFFER, (TRAIL_CAP + 1) * 2 * size_of(f32), nil, gl.DYNAMIC_DRAW)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.BindVertexArray(0)

	mesh := Mesh{vao, vbo, 0, gl.LINE_STRIP}

	return mesh
}

trails_draw :: proc(
	trails: []Trail,
	bodies: []Body,
	mesh: Mesh,
	program: Trail_Program,
	camera_state: ^Camera,
	width, height: i32,
	alpha: f64,
) {
	scratch_buffer: [TRAIL_CAP + 1][2]f32

	gl.UseProgram(program.id)

	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)

	shader_set_vec2(program.offset, f32(0.0), f32(0.0))
	shader_set_float(program.scale, f32(1))
	shader_set_float(program.aspect, f32(height) / f32(width))

	for trail, i in trails {
		if trail.count == 0 do continue

		oldest_point := 0
		body := bodies[i]

		if trail.count == trail.cap {
			oldest_point = trail.head
		}

		for j := 0; j < trail.count; j += 1 {
			point := trail.points[(oldest_point + j) % trail.cap]

			point_pos := point
			if trail.parent >= 0 {
				world := pos_render(bodies[trail.parent], alpha)
				point_pos = point + world
			}

			ndc_pos := ndc_offset_calc(World_Pos(point_pos), camera_state)
			scratch_buffer[j] = [2]f32{f32(ndc_pos.x), f32(ndc_pos.y)}
		}

		world := pos_render(bodies[i], alpha)
		ndc := ndc_offset_calc(World_Pos(world), camera_state)
		scratch_buffer[trail.count] = {f32(ndc.x), f32(ndc.y)}

		color := body.color
		trail_count := trail.count + 1

		shader_set_vec3(program.color, color.x, color.y, color.z)
		shader_set_int(program.count, i32(trail_count))

		gl.BufferSubData(
			gl.ARRAY_BUFFER,
			0,
			trail_count * 2 * size_of(f32),
			raw_data(&scratch_buffer),
		)
		gl.DrawArrays(mesh.primitive, 0, i32(trail_count))
	}
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
	bodies: []Body,
	mesh: Mesh,
	program: Body_Program,
	camera_state: ^Camera,
	width, height: i32,
	alpha: f64,
) {
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	for &body in bodies {
		world := pos_render(body, alpha)
		circle_draw(
			World_Pos(world),
			body.radius,
			body.color,
			mesh,
			program,
			camera_state,
			width,
			height,
		)
	}
}

circle_draw :: proc(
	world: World_Pos,
	radius: f64,
	color: Color,
	mesh: Mesh,
	program: Body_Program,
	camera: ^Camera,
	width, height: i32,
) {
	ndc_pos := ndc_offset_calc(world, camera)
	shader_set_vec2(program.offset, f32(ndc_pos.x), f32(ndc_pos.y))

	ndc_scale := ndc_scale_calc(radius, height, camera)
	shader_set_float(program.scale, f32(ndc_scale))
	shader_set_float(program.aspect, f32(height) / f32(width))
	shader_set_vec3(program.color, color.x, color.y, color.z)

	gl.DrawArrays(mesh.primitive, 0, mesh.vertex_count)
}

drag_preview_draw :: proc(
	start_world, end_world: World_Pos,
	mesh: Mesh,
	program: Trail_Program,
	camera: ^Camera,
	width, height: i32,
) {
	scratch_buffer: [2][2]f32
	start_ndc := ndc_offset_calc(start_world, camera)
	end_ndc := ndc_offset_calc(end_world, camera)

	gl.UseProgram(program.id)

	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
	scratch_buffer[0] = {f32(start_ndc.x), f32(start_ndc.y)}
	scratch_buffer[1] = {f32(end_ndc.x), f32(end_ndc.y)}

	shader_set_vec2(program.offset, f32(0.0), f32(0.0))
	shader_set_float(program.scale, f32(1))
	shader_set_float(program.aspect, f32(height) / f32(width))
	shader_set_vec3(program.color, 1.0, 1.0, 1.0)
	shader_set_int(program.count, i32(1))

	gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(scratch_buffer), raw_data(&scratch_buffer))
	gl.DrawArrays(gl.LINE_STRIP, 0, 2)
}

mass_preview_draw :: proc(
	world: World_Pos,
	radius: f64,
	color: Color,
	mesh: Mesh,
	program: Body_Program,
	camera: ^Camera,
	width, height: i32,
) {
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	circle_draw(world, radius, color, mesh, program, camera, width, height)
}

// NDC: Normalized Device Coordinates
ndc_offset_calc :: proc(pos: World_Pos, camera_state: ^Camera) -> [2]f64 {
	ndc := (([2]f64)(pos) - camera_state.center) / camera_state.half_extent
	return ndc
}

ndc_scale_calc :: proc(radius: f64, height: i32, camera_state: ^Camera) -> f64 {
	min_marker := MIN_MARKER_PX / (f64(height) / 2)

	ndc := math.max(min_marker, radius / camera_state.half_extent)
	return ndc
}

// World -> Screen
screen_pos_calc :: proc(
	world_pos: World_Pos,
	camera_state: ^Camera,
	width, height: i32,
) -> Pixel_Pos {
	w := f64(width)
	h := f64(height)

	ndc := ndc_offset_calc(world_pos, camera_state)
	clip := [2]f64{ndc.x * f64(h) / f64(w), ndc.y}
	return {(clip.x + 1) * 0.5 * f64(w), (1 - clip.y) * 0.5 * f64(h)}
}

// Screen -> World
world_pos_calc :: proc(px_pos: Pixel_Pos, camera_state: ^Camera, width, height: i32) -> World_Pos {
	w := f64(width)
	h := f64(height)

	clip := [2]f64{px_pos.x / (w / 2) - 1, 1 - px_pos.y / (h / 2)}

	ndc := [2]f64{clip.x * w / h, clip.y}

	return (World_Pos)(ndc * camera_state.half_extent + camera_state.center)
}

pos_render :: proc(body: Body, alpha: f64) -> [2]f64 {
	return body.prev_pos + (body.pos - body.prev_pos) * alpha
}

gl_check_error :: proc(loc := #caller_location) {
	when ODIN_DEBUG {
		for err := gl.GetError(); err != gl.NO_ERROR; err = gl.GetError() {
			fmt.printfln("GL Error 0x%x at %v", err, loc)
		}
	}
}
