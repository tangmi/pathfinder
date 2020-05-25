#version 330

uniform sampler2D uSrc;

layout(location = 0) out vec4 oFragColor;
in vec2 vTexCoord;
in float vBackdrop;

void main()
{
    oFragColor = clamp(abs(texture(uSrc, vTexCoord) + vec4(vBackdrop)), vec4(0.0), vec4(1.0));
}

