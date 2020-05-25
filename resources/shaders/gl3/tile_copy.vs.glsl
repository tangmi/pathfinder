#version 330

layout(std140) uniform Globals
{
    mat4 uTransform;
    vec2 uTileSize;
} _20;

layout(location = 0) in ivec2 aTilePosition;

void main()
{
    vec2 position = vec2(aTilePosition) * _20.uTileSize;
    gl_Position = _20.uTransform * vec4(position, 0.0, 1.0);
}

