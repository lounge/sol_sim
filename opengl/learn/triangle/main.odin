package main

import "core:c"
import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}

vertex_shader_source: cstring = `#version 330 core
	layout (location = 0) in vec3 aPos;
	void main()
	{
		gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	}`

orange_fragment_shader_source: cstring = `#version 330 core
	out vec4 FragColor;
	void main()
	{
		FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
	}`

yellow_fragment_shader_source: cstring = `#version 330 core
	out vec4 FragColor;
	void main()
	{
		FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
	}`

SCR_WIDTH :: 800
SCR_HEIGHT :: 600

main :: proc() {
	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "LearnOpenGL Triangle", nil, nil)
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

	success: i32
	info_log: [512]c.char

	vertex_shader :=  compile_shader(vertex_shader_source, gl.VERTEX_SHADER)
	orange_fragment_shader := compile_shader(orange_fragment_shader_source, gl.FRAGMENT_SHADER)
	yellow_fragment_shader := compile_shader(yellow_fragment_shader_source, gl.FRAGMENT_SHADER)

	orange_shader_program := link_program(vertex_shader, orange_fragment_shader)
	yellow_shader_program := link_program(vertex_shader, yellow_fragment_shader)

	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(orange_fragment_shader)
	gl.DeleteShader(yellow_fragment_shader)

	vertices1 := [?]f32 {
		-1, -0.5, 0.0,
		-0.5, 0.5, 0.0,
		0.0, -0.5, 0.0
	}

	vertices2 := [?]f32 {
		0.0, -0.5, 0.0,
		0.5, 0.5, 0.0,
		1.0, -0.5, 0.0
	}

	// indices := [?]u32{0, 1, 3, 1, 2, 3}

	VBO1, VBO2, VAO1, VAO2, EBO: u32

	// gl.GenBuffers(1, &EBO)

	gl.GenVertexArrays(1, &VAO1)
	gl.GenBuffers(1, &VBO1)
	gl.BindVertexArray(VAO1)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO1)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices1), raw_data(&vertices1), gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.GenVertexArrays(1, &VAO2)
	gl.GenBuffers(1, &VBO2)
	gl.BindVertexArray(VAO2)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO2)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices2), raw_data(&vertices2), gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), raw_data(&indices), gl.STATIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	for !glfw.WindowShouldClose(window) {
		process_input(window)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(orange_shader_program)
		gl.BindVertexArray(VAO1)

		// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		gl.UseProgram(yellow_shader_program)

		gl.BindVertexArray(VAO2)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteVertexArrays(1, &VAO1)
	gl.DeleteBuffers(1, &VBO1)

	gl.DeleteVertexArrays(1, &VAO2)
	gl.DeleteBuffers(1, &VBO2)

	gl.DeleteBuffers(1, &EBO)
	gl.DeleteProgram(orange_shader_program)
	gl.DeleteProgram(yellow_shader_program)

	glfw.Terminate()
}

compile_shader :: proc(source: cstring, kind: u32) -> u32 {
	source := source

	success: i32
	info_log: [512]c.char

	shader := gl.CreateShader(kind)
	gl.ShaderSource(shader, 1, &source, nil)
	gl.CompileShader(shader)
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if success != 1 {
		gl.GetShaderInfoLog(shader, 512, nil, raw_data(&info_log))
		fmt.println("Shader compile failed:", cstring(raw_data(&info_log)))
		os.exit(-1)
	}

	return shader
}

link_program :: proc(vertex_shader: u32, fragment_shader: u32) -> u32 {
	program := gl.CreateProgram()

	success: i32
	info_log: [512]c.char

	gl.AttachShader(program, vertex_shader)
	gl.AttachShader(program, fragment_shader)
	gl.LinkProgram(program)

	gl.GetProgramiv(program, gl.LINK_STATUS, &success)
	if success != 1 {
		gl.GetProgramInfoLog(program, 512, nil, raw_data(&info_log))
		fmt.println("orange program compile failed:", cstring(raw_data(&info_log)))
		os.exit(-1)
	}

	return program
}
