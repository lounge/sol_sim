package main

import sim "../core"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

import "core:fmt"
_ :: fmt

MIN_MARKER_PX :: 4
MIN_STAR_MASS :: 0.08
EMISSIVE_INTENSITY :: 8.0
BLOOM_THRESHOLD  :: 1.0
BLOOM_KNEE       :: 0.5
BLOOM_ITERATIONS :: 5

Mesh :: struct {
	vao:          u32,
	vbo:          u32,
	vertex_count: i32,
	primitive:    u32,
}

Render_Target :: struct {
	fbo:       u32,
	color_tex: u32,
	depth_rb:  u32,
	width:     i32,
	height:    i32,
}

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
	camera_frame: Camera_Frame,
	alpha: f64,
) {
	scratch_buffer: [sim.TRAIL_CAP + 1][3]f32

	gl.DepthMask(gl.FALSE)

	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	projection := camera_frame.proj * camera_frame.view
	mvp := (matrix[4, 4]f32)(projection)
	shader_set(program.mvp, &mvp)

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
			rel := anchor + point - camera_frame.eye
			scratch_buffer[j] = {f32(rel.x), f32(rel.y), f32(rel.z)}
		}

		tip := pos_render(bodies[i], alpha) - camera_frame.eye
		scratch_buffer[trail.count] = {f32(tip.x), f32(tip.y), f32(tip.z)}

		color := body.color
		trail_count := trail.count + 1

		shader_set(program.color, color.x, color.y, color.z)
		shader_set(program.count, i32(trail_count))


		gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
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
	camera_frame: Camera_Frame,
	height: i32,
	alpha: f64,
) {
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	projection32 := (matrix[4, 4]f32)(camera_frame.proj)
	shader_set(program.proj, &projection32)

	light_index, lit := light_scan(bodies)
	shader_set(program.lit, i32(lit))

	slots := make([]i32, len(bodies), context.temp_allocator)
	for &slot in slots {
		slot = -1
	}

	if lit {
		sun_rel := pos_render(bodies[light_index], alpha) - camera_frame.eye
		sun_pos_view := camera_frame.view * [4]f64{sun_rel.x, sun_rel.y, sun_rel.z, 1}

		shader_set(
			program.sun_pos_view,
			f32(sun_pos_view.x),
			f32(sun_pos_view.y),
			f32(sun_pos_view.z),
		)

		occ_pos: [MAX_OCCLUDERS][3]f32
		occ_rad: [MAX_OCCLUDERS]f32
		n := 0
		for body, i in bodies {
			if i == light_index do continue
			if n == MAX_OCCLUDERS do break

			rel := pos_render(body, alpha) - camera_frame.eye
			pos_v := camera_frame.view * [4]f64{rel.x, rel.y, rel.z, 1}
			occ_pos[n] = ([3]f32)(pos_v.xyz)
			occ_rad[n] = f32(body.radius)
			slots[i] = i32(n)
			n += 1
		}

		shader_set(program.occluder_pos_view, occ_pos[:n])
		shader_set(program.occluder_radius, occ_rad[:n])
		shader_set(program.occluder_count, i32(n))
		shader_set(program.sun_radius, f32(bodies[light_index].radius))
	}


	for body, i in bodies {
		rel := pos_render(body, alpha) - camera_frame.eye
		center_view := camera_frame.view * [4]f64{rel.x, rel.y, rel.z, 1}
		depth := -center_view.z

		emissive := (lit && i == light_index) ? 1 : 0
		shader_set(program.emissive, i32(emissive))
		shader_set(program.emissive_intensity, EMISSIVE_INTENSITY)
		circle_draw(body.radius, body.color, mesh, program, center_view, depth, height, slots[i])
	}
}

drag_preview_pass :: proc(
	state: ^State,
	cursor: Pixel_Pos,
	drag: Pixel_Pos,
	trail_mesh, circle_mesh: Mesh,
	trail_program: Trail_Program,
	body_program: Body_Program,
	camera_frame: Camera_Frame,
	window_width, window_height: i32,
	fb_height: i32,
) -> (
	pos_a, pos_b: World_Pos,
	ok: bool,
) {

	a, a_ok := ray_plane_hit(
		camera_ray(state.camera, drag, f64(window_width), f64(window_height)),
	).?
	b, b_ok := ray_plane_hit(
		camera_ray(state.camera, cursor, f64(window_width), f64(window_height)),
	).?

	if a_ok && b_ok {
		drag_preview_draw(a, b, trail_mesh, trail_program, camera_frame)

		_, radius := mass_radius_get(state.input.spawn_mass_exp)
		mass_preview_draw(b, radius, circle_mesh, body_program, camera_frame, fb_height)
	}

	return a, b, a_ok && b_ok
}

gravity_tree_cells_draw :: proc(
	tree: ^sim.Gravity_Tree,
	mesh: Mesh,
	program: Trail_Program,
	camera_frame: Camera_Frame,
) {

	scratch_buffer: [sim.TRAIL_CAP + 1][3]f32
	filled := 0

	projection := camera_frame.proj * camera_frame.view
	mvp32 := (matrix[4, 4]f32)(projection)

	gl.Disable(gl.BLEND)
	gl.DepthMask(gl.FALSE)
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)


	shader_set(program.mvp, &mvp32)
	shader_set(program.color, 1.0, 0.0, 0.0)
	shader_set(program.count, 1) // meaningless with blend off

	for node in tree.node {
		if filled + 24 > len(scratch_buffer) {
			// flush
			tree_cells_flush(&scratch_buffer, &filled)
		}

		for c in 0 ..< 8 {
			for axis in 0 ..< 3 {
				if c & (1 << uint(axis)) == 0 {
					a := tree_cell_corner(node, c) - camera_frame.eye
					b := tree_cell_corner(node, c | (1 << uint(axis))) - camera_frame.eye
					scratch_buffer[filled] = {f32(a.x), f32(a.y), f32(a.z)}
					scratch_buffer[filled + 1] = {f32(b.x), f32(b.y), f32(b.z)}
					filled += 2
				}
			}
		}
	}

	// flush
	tree_cells_flush(&scratch_buffer, &filled)

	gl.DepthMask(gl.TRUE)
	gl.Enable(gl.BLEND)
}

render_target_storage :: proc(target: ^Render_Target, width, height: i32) {
	gl.BindTexture(gl.TEXTURE_2D, target.color_tex)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, width, height, 0, gl.RGBA, gl.HALF_FLOAT, nil)

	if target.depth_rb != 0 {
		gl.BindRenderbuffer(gl.RENDERBUFFER, target.depth_rb)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, width, height)
	}

	target.width = width
	target.height = height
}


render_target_create :: proc(width, height: i32, want_depth: bool) -> Render_Target {
	target: Render_Target
	target.width = width
	target.height = height

	gl.GenFramebuffers(1, &target.fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, target.fbo)

	gl.GenTextures(1, &target.color_tex)

	// TODO:     set filters, attach colour
	if want_depth {
		gl.GenRenderbuffers(1, &target.depth_rb)
	} else {
		target.depth_rb = 0
	}

	render_target_storage(&target, width, height)


	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.FramebufferTexture2D(
		gl.FRAMEBUFFER,
		gl.COLOR_ATTACHMENT0,
		gl.TEXTURE_2D,
		target.color_tex,
		0,
	)

	if want_depth {
		gl.FramebufferRenderbuffer(
			gl.FRAMEBUFFER,
			gl.DEPTH_ATTACHMENT,
			gl.RENDERBUFFER,
			target.depth_rb,
		)
	}

	frame_buff_status := gl.CheckFramebufferStatus(gl.FRAMEBUFFER)
	if frame_buff_status != gl.FRAMEBUFFER_COMPLETE {
		panic(fmt.aprintf("scene framebuffer is incomplete 0x%x", frame_buff_status))
	}

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	return target
}

render_target_resize :: proc(target: ^Render_Target, width, height: i32) {
	if width == target.width && height == target.height {
		return
	}

	render_target_storage(target, width, height)
}

composite_draw :: proc(source: ^Render_Target, program: ^Composite_Program, vao: u32) {
	gl.Disable(gl.DEPTH_TEST)
	gl.Disable(gl.BLEND)

	gl.UseProgram(program.id)
	gl.BindVertexArray(vao)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, source.color_tex)

	shader_set(program.scene, 0)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)

	gl.Enable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
}

brightness_draw :: proc(
	source: ^Render_Target,
	dest: ^Render_Target,
	program: ^Brightness_Program,
	vao: u32,
) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, dest.fbo)
	gl.Viewport(0, 0, dest.width, dest.height) //  half res

	gl.Disable(gl.DEPTH_TEST)
	gl.Disable(gl.BLEND)

	gl.UseProgram(program.id)
	gl.BindVertexArray(vao)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, source.color_tex)

	shader_set(program.scene, 0)
	shader_set(program.threshold, BLOOM_THRESHOLD)
	shader_set(program.knee, BLOOM_KNEE)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
	gl.Enable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
}


blur_draw :: proc(
	source: ^Render_Target,
	dest: ^Render_Target,
	program: ^Blur_Program,
	vao: u32,
	axis_x, axis_y: f64,
) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, dest.fbo)
	gl.Viewport(0, 0, dest.width, dest.height)

	gl.Disable(gl.DEPTH_TEST)
	gl.Disable(gl.BLEND)
	gl.UseProgram(program.id)
	gl.BindVertexArray(vao)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, source.color_tex)

	shader_set(program.source, 0)
	shader_set(program.axis, f32(axis_x), f32( axis_y))

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
	gl.Enable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
}

bloom_blur :: proc(
	brightness: ^Render_Target,
	targets: ^[2]Render_Target,
	program: ^Blur_Program,
	vao: u32,
	iterations: int,
) -> ^Render_Target {
	source := brightness
	dest := 0

	for i in 0 ..< iterations * 2 {
		horizontal := (i % 2 == 0)
		blur_draw(source, &targets[dest], program, vao, horizontal ? 1 : 0, horizontal ? 0 : 1)
		source = &targets[dest]
		dest = 1 - dest
	}

	return source
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


@(private = "file")
circle_draw :: proc(
	radius: f64,
	color: sim.Color,
	mesh: Mesh,
	program: Body_Program,
	center_view: [4]f64,
	depth: f64,
	height: i32,
	receiver_slots: i32,
) {
	draw_radius := math.max(
		radius,
		MIN_MARKER_PX * depth * math.tan_f64(CAMERA_FOV / 2) / (f64(height) / 2),
	)

	mv :=
		linalg.matrix4_translate(center_view.xyz) *
		linalg.matrix4_scale_f64({draw_radius, draw_radius, draw_radius})
	mv32 := (matrix[4, 4]f32)(mv)

	shader_set(program.color, color.x, color.y, color.z)
	shader_set(program.mv, &mv32)
	shader_set(program.body_radius, f32(radius))
	shader_set(program.receiver_slot, receiver_slots)

	gl.DrawArrays(mesh.primitive, 0, mesh.vertex_count)
}

@(private = "file")
drag_preview_draw :: proc(
	start_world, end_world: World_Pos,
	mesh: Mesh,
	program: Trail_Program,
	camera_frame: Camera_Frame,
) {
	scratch_buffer: [2][3]f32
	projection := camera_frame.proj * camera_frame.view
	projection32 := (matrix[4, 4]f32)(projection)

	start := [3]f64{start_world.x, start_world.y, 0} - camera_frame.eye
	end := [3]f64{end_world.x, end_world.y, 0} - camera_frame.eye

	scratch_buffer[0] = {f32(start.x), f32(start.y), f32(start.z)}
	scratch_buffer[1] = {f32(end.x), f32(end.y), f32(end.z)}

	gl.DepthMask(gl.FALSE)
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)

	shader_set(program.mvp, &projection32)
	shader_set(program.color, 1, 1, 1)
	shader_set(program.count, 1)

	gl.BufferData(gl.ARRAY_BUFFER, (sim.TRAIL_CAP + 1) * 3 * size_of(f32), nil, gl.STREAM_DRAW)
	gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(scratch_buffer), raw_data(&scratch_buffer))

	gl.DrawArrays(gl.LINE_STRIP, 0, 2)
	gl.DepthMask(gl.TRUE)
}

@(private = "file")
mass_preview_draw :: proc(
	world: World_Pos,
	radius: f64,
	mesh: Mesh,
	program: Body_Program,
	camera_frame: Camera_Frame,
	height: i32,
) {
	gl.UseProgram(program.id)
	gl.BindVertexArray(mesh.vao)

	rel := [3]f64{world.x, world.y, 0} - camera_frame.eye
	center_view := camera_frame.view * [4]f64{rel.x, rel.y, rel.z, 1}

	shader_set(program.emissive, 1)
	shader_set(program.emissive_intensity, EMISSIVE_INTENSITY)

	projection32 := (matrix[4, 4]f32)(camera_frame.proj)
	shader_set(program.proj, &projection32)

	circle_draw(
		radius,
		sim.PALETTE[.Spawn],
		mesh,
		program,
		center_view,
		-center_view.z,
		height,
		-1,
	)
}

@(private = "file")
tree_cell_corner :: proc(node: sim.Tree_Node, bits: int) -> [3]f64 {
	offset: [3]f64
	for axis in 0 ..< 3 {
		offset[axis] = (bits >> uint(axis)) & 1 == 1 ? +node.half_size : -node.half_size
	}
	return ([3]f64)(node.center) + offset
}

@(private = "file")
tree_cells_flush :: proc(scratch: ^[sim.TRAIL_CAP + 1][3]f32, filled: ^int) {
	if filled^ == 0 do return

	gl.BufferData(gl.ARRAY_BUFFER, (sim.TRAIL_CAP + 1) * 3 * size_of(f32), nil, gl.STREAM_DRAW)
	gl.BufferSubData(gl.ARRAY_BUFFER, 0, filled^ * 3 * size_of(f32), raw_data(scratch))
	gl.DrawArrays(gl.LINES, 0, i32(filled^))
	filled^ = 0
}

@(private = "file")
light_scan :: proc(bodies: []sim.Body) -> (index: int, lit: bool) {
	if len(bodies) == 0 {
		return -1, false
	}

	largest_mass_index := sim.most_massive_body_index(bodies[:], 0)

	return largest_mass_index, bodies[largest_mass_index].mass >= MIN_STAR_MASS
}
