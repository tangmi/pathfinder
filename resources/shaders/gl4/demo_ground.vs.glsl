#version 430

layout(binding = 0, std140) uniform Globals
{
    mat4 uTransform;
    int uGridlineCount;
} _19;

layout(location = 0) out vec2 vTexCoord;
layout(location = 0) in ivec2 aPosition;

void main()
{
    vTexCoord = vec2(aPosition * ivec2(_19.uGridlineCount));
    gl_Position = _19.uTransform * vec4(ivec4(aPosition.x, 0, aPosition.y, 1));
}

