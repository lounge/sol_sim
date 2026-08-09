#version 330 core
layout (location = 0) in vec2 a_pos;
uniform mat4 mv;
uniform mat4 proj;

out vec3 v_pos_view;
out vec2 v_local;

void main()
{
    vec4 pos_view = mv * vec4(a_pos, 0.0, 1.0);
    v_pos_view = pos_view.xyz;
    v_local = a_pos;
    gl_Position = proj * pos_view;
}
