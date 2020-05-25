#version 330

layout(std140) uniform Globals
{
    vec2 uFramebufferSize;
} _17;

uniform sampler2D uSrc;

layout(location = 0) out vec4 oFragColor;

void main()
{
    vec2 texCoord = gl_FragCoord.xy / _17.uFramebufferSize;
    oFragColor = texture(uSrc, texCoord);
}

