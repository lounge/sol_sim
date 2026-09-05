#version 330 core
layout (location = 0) in vec3 a_pos;
uniform mat4 mvp;
uniform int count;
out float t_alpha;

void main()
{
    gl_Position = mvp * vec4(a_pos, 1.0);
    t_alpha = float(gl_VertexID) / float(count);
}
