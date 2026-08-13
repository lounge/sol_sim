#version 330 core

in vec2 v_uv;

uniform sampler2D source;
uniform vec2 axis; // 1,0 hor, 0,1 vert

out vec4 FragColor;



const int TAPS = 5;
const float WEIGHT[5] = float[](0.227027, 0.194595, 0.121622, 0.054054, 0.016216);

void main() {
    vec2 texel = 1.0 / vec2(textureSize(source, 0));
    vec2 step = axis * texel;

    vec3 result = texture(source, v_uv).rgb * WEIGHT[0];
    for (int i = 1; i < TAPS; ++i) {
        result += texture(source, v_uv + step * float(i)).rgb * WEIGHT[i];
        result += texture(source, v_uv - step * float(i)).rgb * WEIGHT[i];
    }

    FragColor = vec4(result, 1.0);
}
