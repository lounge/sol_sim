#version 330 core
layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec2 a_uv;
uniform mat4 mv;
uniform mat4 proj;

out vec3 v_pos_view;
out vec3 v_normal_view;
out vec2 v_uv;
flat out vec3 v_center_view;

void main()
{
    vec4 pos_view = mv * vec4(a_pos, 1.0);
    v_pos_view = pos_view.xyz;
    v_normal_view = normalize(mat3(mv) * a_pos);
    gl_Position = proj * pos_view;
    v_center_view = (mv * vec4(0,0,0,1)).xyz;
    v_uv = a_uv;
}
