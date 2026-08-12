#version 330 core

in vec2 v_uv;

uniform sampler2D scene;

out vec4 FragColor;

void main () {
    FragColor = vec4(pow(texture(scene, v_uv).rgb, vec3(1.0/2.2)), 1.0);
}
