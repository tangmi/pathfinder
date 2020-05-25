#version 430

uniform sampler2D uSrc;

layout(location = 0) out vec4 oFragColor;
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vBackdrop;

void main()
{
    oFragColor = clamp(abs(texture(uSrc, vTexCoord) + vec4(vBackdrop)), vec4(0.0), vec4(1.0));
}

