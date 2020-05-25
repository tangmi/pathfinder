#version 330

layout(std140) uniform Globals
{
    vec4 uColor;
} _30;

uniform sampler2D uTexture;

in vec2 vTexCoord;
layout(location = 0) out vec4 oFragColor;

void main()
{
    float alpha = texture(uTexture, vTexCoord).x * _30.uColor.w;
    oFragColor = vec4(_30.uColor.xyz, 1.0) * alpha;
}

