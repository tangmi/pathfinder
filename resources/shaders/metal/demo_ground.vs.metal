#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Globals
{
    float4x4 uTransform;
    int uGridlineCount;
};

struct main0_out
{
    float2 vTexCoord [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct main0_in
{
    int2 aPosition [[attribute(0)]];
};

vertex main0_out main0(main0_in in [[stage_in]], constant Globals& _19 [[buffer(0)]])
{
    main0_out out = {};
    out.vTexCoord = float2(in.aPosition * int2(_19.uGridlineCount));
    out.gl_Position = _19.uTransform * float4(int4(in.aPosition.x, 0, in.aPosition.y, 1));
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

