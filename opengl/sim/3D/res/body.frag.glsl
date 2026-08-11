#version 330 core

const float AMBIENT = 0.05;
const int MAX_OCCLUDERS = 32; // Needs to stay in sync with shader.odin


uniform vec3 color;
uniform vec3 sun_pos_view;
uniform int emissive;
uniform int lit;

uniform vec3 occluder_pos_view[MAX_OCCLUDERS];
uniform float occluder_radius[MAX_OCCLUDERS];
uniform int occluder_count;
uniform float sun_radius;
uniform int receiver_slot;
uniform float body_radius;

in vec3 v_pos_view;
in vec2 v_local;

out vec4 FragColor;

void main()
{

    if (emissive == 1) {
        FragColor = vec4(color, 1.0);
    } else {
        float diffuse = 0.0;
        if (lit == 1) {
            float r2 = dot(v_local, v_local);
            vec3 L = normalize(sun_pos_view - v_pos_view);
            vec3 N = vec3(v_local, sqrt(max(0.0, 1.0 - r2)));
            diffuse = max(dot(N, L), 0.0);
        }

        vec3 albedo = pow(color, vec3(2.2));
        float lighting = AMBIENT + (1.0 - AMBIENT) * diffuse;
        vec3 shading = albedo * lighting;
        FragColor = vec4(pow(shading, vec3(1.0 / 2.2)), 1.0);
    }

}
