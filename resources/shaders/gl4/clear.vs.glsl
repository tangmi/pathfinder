#version 430

layout(binding = 0, std140) uniform Globals
{
    vec4 uRect;
    vec2 uFramebufferSize;
} _13;

layout(location = 0) in ivec2 aPosition;

void main()
{
    vec2 position = ((mix(_13.uRect.xy, _13.uRect.zw, vec2(aPosition)) / _13.uFramebufferSize) * 2.0) - vec2(1.0);
    gl_Position = vec4(position.x, -position.y, 0.0, 1.0);
}

