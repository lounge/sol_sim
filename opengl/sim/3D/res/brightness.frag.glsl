#version 330 core

uniform sampler2D scene;
uniform float threshold;
uniform float  knee;

in vec2 v_uv;

out vec4 FragColor;

void main() {
    vec3 c = texture(scene, v_uv).rgb;
    float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float w = clamp ((lum - threshold) / knee, 0.0, 1.0);
    FragColor = vec4(c * w, 1.0);
}
