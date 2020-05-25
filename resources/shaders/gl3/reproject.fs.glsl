#version 330

layout(std140) uniform Globals
{
    mat4 uOldTransform;
} _13;

uniform sampler2D uTexture;

in vec2 vTexCoord;
layout(location = 0) out vec4 oFragColor;

void main()
{
    vec4 normTexCoord = _13.uOldTransform * vec4(vTexCoord, 0.0, 1.0);
    vec2 texCoord = ((normTexCoord.xy / vec2(normTexCoord.w)) + vec2(1.0)) * 0.5;
    oFragColor = texture(uTexture, texCoord);
}

