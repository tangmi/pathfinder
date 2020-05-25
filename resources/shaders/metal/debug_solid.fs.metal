#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Globals
{
    float4 uColor;
};

struct main0_out
{
    float4 oFragColor [[color(0)]];
};

fragment main0_out main0(constant Globals& _12 [[buffer(0)]])
{
    main0_out out = {};
    out.oFragColor = float4(_12.uColor.xyz, 1.0) * _12.uColor.w;
    return out;
}

