#version 430

layout(binding = 0, std140) uniform Globals
{
    vec4 uGroundColor;
    vec4 uGridlineColor;
} _33;

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 oFragColor;

void main()
{
    vec2 texCoordPx = fract(vTexCoord) / fwidth(vTexCoord);
    vec4 _28;
    if (any(lessThanEqual(texCoordPx, vec2(1.0))))
    {
        _28 = _33.uGridlineColor;
    }
    else
    {
        _28 = _33.uGroundColor;
    }
    oFragColor = _28;
}

