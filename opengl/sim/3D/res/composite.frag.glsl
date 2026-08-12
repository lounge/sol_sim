#version 330 core

in vec2 v_uv;

uniform sampler2D scene;

out vec4 FragColor;

void main () {
    FragColor = vec4(texture(scene, v_uv).rgb, 1.0);
}
