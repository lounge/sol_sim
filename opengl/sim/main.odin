package main

import gl "vendor:OpenGL"

import "core:c"
import "core:fmt"
import "core:os"
import "core:math"
import "vendor:glfw"

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}

shader_set_float :: proc(id: u32, name: cstring, value: f32) {
	gl.Uniform1f(gl.GetUniformLocation(id, name), value)
}

shader_set_vec2 :: proc(id: u32, name: cstring, x: f32, y: f32) {
	gl.Uniform2f(gl.GetUniformLocation(id, name), x, y)
}

SCR_WIDTH :: 800
SCR_HEIGHT :: 600

main :: proc() {
	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "Sol_Sim", nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		glfw.Terminate()
		os.exit(-1)
	}

	glfw.MakeContextCurrent(window)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	fb_width, fb_height := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, fb_width, fb_height)

	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	shader_program, loaded_ok := gl.load_shaders_file(#directory + "res/vertex.vert.glsl", #directory + "res/fragment.frag.glsl")
	if !loaded_ok {
		os.exit(-1)
	}

	VBO, VAO: u32
	segments: int = 32

	circle_verts := create_circle_vertices(segments)

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.BindVertexArray(VAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, len(circle_verts) * size_of(f32), raw_data(circle_verts), gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	for !glfw.WindowShouldClose(window) {
		process_input(window)

		fb_width, fb_height := glfw.GetFramebufferSize(window)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)
		gl.BindVertexArray(VAO)

		// Earth
		shader_set_vec2(shader_program, "offset", -0.3, 0.0)
		shader_set_float(shader_program, "scale", 0.4)
		shader_set_float(shader_program, "aspect", f32(fb_height) / f32(fb_width))

		gl.DrawArrays(gl.TRIANGLE_FAN, 0, i32(segments + 2))

		// Moon
		shader_set_vec2(shader_program, "offset", 0.6, 0.3)
		shader_set_float(shader_program, "scale", 0.1)
		shader_set_float(shader_program, "aspect", f32(fb_height) / f32(fb_width))

		gl.DrawArrays(gl.TRIANGLE_FAN, 0, i32(segments + 2))

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	glfw.Terminate()
}

create_circle_vertices :: proc(segments: int) -> [dynamic]f32 {
	vertices: [dynamic]f32

	// TODO: make params
	radius: f32 = 1.0
	origin_x: f32 = 0.0
	origin_y: f32 = 0.0

	append(&vertices, origin_x, origin_y)

	for i := 0; i <= segments; i += 1 {
		angle := f32(i) * (2 * math.PI / f32(segments))

		x := origin_x + f32(radius) * math.cos(angle)
		y := origin_y + f32(radius) * math.sin(angle)

		append(&vertices, x, y)
	}

	return vertices
}
