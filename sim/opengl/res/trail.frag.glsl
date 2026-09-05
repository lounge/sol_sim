#version 330 core
uniform vec3 color;

in float t_alpha;
out vec4 FragColor;

void main()
{
    FragColor = vec4(pow(color, vec3(2.2)), t_alpha);
}
