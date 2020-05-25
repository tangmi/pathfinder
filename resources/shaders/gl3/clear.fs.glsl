#version 330

layout(std140) uniform Globals
{
    vec4 uColor;
} _12;

layout(location = 0) out vec4 oFragColor;

void main()
{
    oFragColor = vec4(_12.uColor.xyz, 1.0) * _12.uColor.w;
}

