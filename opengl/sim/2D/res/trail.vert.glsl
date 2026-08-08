#version 330 core
layout (location = 0) in vec2 aPos;
uniform vec2 offset;
uniform float scale;
uniform float aspect;
uniform int count;

out float t_alpha;

void main()
{
    vec2 p = aPos * scale + offset;
    gl_Position = vec4(p.x * aspect, p.y, 0.0, 1.0);
    t_alpha = float(gl_VertexID) / float(count);
}
