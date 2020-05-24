// Automatically generated from files in pathfinder/shaders/. Do not edit!
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct main0_out
{
    float4 oFragColor [[color(0)]];
};

struct main0_in
{
    float2 vTexCoord [[user(locn0)]];
};

fragment main0_out main0(main0_in in [[stage_in]], constant float4& uGridlineColor [[buffer(0)]], constant float4& uGroundColor [[buffer(1)]])
{
    main0_out out = {};
    float2 texCoordPx = fract(in.vTexCoord) / fwidth(in.vTexCoord);
    out.oFragColor = select(uGroundColor, uGridlineColor, bool4(any(texCoordPx <= float2(1.0))));
    return out;
}

