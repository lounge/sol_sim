#version 330 core

in vec2 v_uv;

uniform sampler2D scene;
uniform sampler2D bloom;
uniform float bloom_strength;

out vec4 FragColor;

//Narkowicz's ACES fit
vec3 aces(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}


void main () {
    vec3 hdr = texture(scene, v_uv).rgb + texture(bloom, v_uv).rgb * bloom_strength;
    vec3 mapped = aces(hdr);
    FragColor = vec4(pow(mapped, vec3(1.0 / 2.2)), 1.0);
}
