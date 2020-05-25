#version 430

layout(binding = 0, std140) uniform Globals
{
    vec2 uFramebufferSize;
    vec2 uTileSize;
} _20;

layout(location = 5) in uint aTileIndex;
layout(location = 1) in uint aFromPx;
layout(location = 3) in vec2 aFromSubpx;
layout(location = 2) in uint aToPx;
layout(location = 4) in vec2 aToSubpx;
layout(location = 0) in uvec2 aTessCoord;
layout(location = 0) out vec2 vFrom;
layout(location = 1) out vec2 vTo;

vec2 computeTileOffset(uint tileIndex, float stencilTextureWidth)
{
    uint tilesPerRow = uint(stencilTextureWidth / _20.uTileSize.x);
    uvec2 tileOffset = uvec2(tileIndex % tilesPerRow, tileIndex / tilesPerRow);
    return (vec2(tileOffset) * _20.uTileSize) * vec2(1.0, 0.25);
}

void main()
{
    uint param = aTileIndex;
    float param_1 = _20.uFramebufferSize.x;
    vec2 tileOrigin = computeTileOffset(param, param_1);
    vec2 from = vec2(float(aFromPx & 15u), float(aFromPx >> 4u)) + aFromSubpx;
    vec2 to = vec2(float(aToPx & 15u), float(aToPx >> 4u)) + aToSubpx;
    vec2 position;
    if (aTessCoord.x == 0u)
    {
        position.x = floor(min(from.x, to.x));
    }
    else
    {
        position.x = ceil(max(from.x, to.x));
    }
    if (aTessCoord.y == 0u)
    {
        position.y = floor(min(from.y, to.y));
    }
    else
    {
        position.y = _20.uTileSize.y;
    }
    position.y = floor(position.y * 0.25);
    vec2 offset = vec2(0.0, 1.5) - (position * vec2(1.0, 4.0));
    vFrom = from + offset;
    vTo = to + offset;
    vec2 globalPosition = (((tileOrigin + position) / _20.uFramebufferSize) * 2.0) - vec2(1.0);
    gl_Position = vec4(globalPosition, 0.0, 1.0);
}

