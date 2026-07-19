#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
uniform float xOffset;

out vec3 ourColor;

void main()
{
    vec3 newPos = vec3(aPos.x + xOffset, aPos.yz);
    gl_Position = vec4(newPos, 1.0);
    ourColor = aColor;
}
