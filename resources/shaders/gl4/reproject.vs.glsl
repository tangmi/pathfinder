#version 430

layout(binding = 0, std140) uniform Globals
{
    mat4 uNewTransform;
} _30;

layout(location = 0) in ivec2 aPosition;
layout(location = 0) out vec2 vTexCoord;

void main()
{
    vec2 position = vec2(aPosition);
    vTexCoord = position;
    gl_Position = _30.uNewTransform * vec4(position, 0.0, 1.0);
}

