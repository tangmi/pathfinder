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
    float vBackdrop [[user(locn1)]];
};

fragment main0_out main0(main0_in in [[stage_in]], texture2d<float> uSrc [[texture(0)]], sampler uSrcSampler [[sampler(0)]])
{
    main0_out out = {};
    out.oFragColor = fast::clamp(abs(uSrc.sample(uSrcSampler, in.vTexCoord) + float4(in.vBackdrop)), float4(0.0), float4(1.0));
    return out;
}

