#version 330

uniform sampler2D uSrc;

in vec2 vTexCoord;
layout(location = 0) out vec4 oFragColor;

void main()
{
    vec4 color = texture(uSrc, vTexCoord);
    oFragColor = vec4(color.xyz * color.w, color.w);
}

