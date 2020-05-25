#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Globals
{
    float4x4 uTransform;
    float2 uTileSize;
};

struct main0_out
{
    float4 gl_Position [[position]];
};

struct main0_in
{
    int2 aTilePosition [[attribute(0)]];
};

vertex main0_out main0(main0_in in [[stage_in]], constant Globals& _20 [[buffer(0)]])
{
    main0_out out = {};
    float2 position = float2(in.aTilePosition) * _20.uTileSize;
    out.gl_Position = _20.uTransform * float4(position, 0.0, 1.0);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

