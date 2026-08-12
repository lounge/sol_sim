#version 330 core

const float PI = 3.14159265358979323846;
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
uniform float emissive_intensity;

flat in vec3 v_center_view;
in vec3 v_pos_view;
in vec2 v_local;

out vec4 FragColor;

float disc_visibility(float a_s, float a_o, float theta) {
    if (theta >= a_s + a_o) {
        return 1.0; // clear
    }
    if (theta <= abs(a_s - a_o)) { // containment
        return a_o >= a_s ? 0.0 : 1.0 - (a_o*a_o)/(a_s*a_s); // total / annular
    }

    float d1 = (pow(theta, 2.0) + pow(a_s, 2.0) - pow(a_o, 2.0)) / (2.0 * theta);
    float d2 = theta - d1;

    float A = pow(a_s, 2.0) * acos(clamp(d1/a_s, -1.0, 1.0)) - d1 * sqrt(max(pow(a_s, 2.0) - pow(d1, 2.0), 0.0)) +
              pow(a_o, 2.0) * acos(clamp(d2/a_o, -1.0, 1.0)) - d2 * sqrt(max(pow(a_o, 2.0) - pow(d2, 2.0), 0.0));

    return 1.0 - A / (PI * pow(a_s, 2.0));
}

void main()
{

    if (emissive == 1) {
        FragColor = vec4(pow(color, vec3(2.2)) * emissive_intensity, 1.0);
    } else {
        float diffuse = 0.0;
        if (lit == 1) {
            float r2 = dot(v_local, v_local);
            vec3 L = normalize(sun_pos_view - v_pos_view);
            vec3 N = vec3(v_local, sqrt(max(0.0, 1.0 - r2)));


            vec3 P = v_center_view + N * body_radius;
            vec3 to_sun = sun_pos_view - P;
            float d_sun = length(to_sun);
            float a_sun = asin(clamp(sun_radius / d_sun, 0, 1));

            float vis = 1.0;
            for (int i = 0; i < occluder_count; ++i) {
                if (i == receiver_slot) {
                    continue;
                }

                vec3 V = occluder_pos_view[i] - P;
                float d = length(V);
                if (d <= occluder_radius[i]) { // defensive - inside
                    vis = 0.0;
                    break;
                }
                if (dot(V, to_sun) <= 0 || d >= d_sun) {
                    continue;
                }

                float a_occ = asin(occluder_radius[i] / d);
                float theta = atan(length(cross(V, to_sun)), dot(V, to_sun));
                vis *= disc_visibility(a_sun, a_occ, theta);
            }


            diffuse = max(dot(N, L), 0.0) * vis;
        }

        vec3 albedo = pow(color, vec3(2.2));
        float lighting = AMBIENT + (1.0 - AMBIENT) * diffuse;
        vec3 shading = albedo * lighting;
        FragColor = vec4(shading, 1.0);
    }

}
