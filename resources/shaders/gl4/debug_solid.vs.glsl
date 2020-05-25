#version 430

layout(binding = 0, std140) uniform Globals
{
    vec2 uFramebufferSize;
} _18;

layout(location = 0) in ivec2 aPosition;

void main()
{
    vec2 position = ((vec2(aPosition) / _18.uFramebufferSize) * 2.0) - vec2(1.0);
    gl_Position = vec4(position.x, -position.y, 0.0, 1.0);
}

