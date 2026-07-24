#version 330 core
uniform vec3 color;
out vec4 FragColor;

void main()
{
    FragColor = vec4(color, 1.0);//vec4(0.9, 0.8, 0.3, 1.0);
}
