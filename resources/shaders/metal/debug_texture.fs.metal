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

struct main0_in
{
    float2 vTexCoord [[user(locn0)]];
};

fragment main0_out main0(main0_in in [[stage_in]], constant Globals& _30 [[buffer(0)]], texture2d<float> uTexture [[texture(0)]], sampler uTextureSampler [[sampler(0)]])
{
    main0_out out = {};
    float alpha = uTexture.sample(uTextureSampler, in.vTexCoord).x * _30.uColor.w;
    out.oFragColor = float4(_30.uColor.xyz, 1.0) * alpha;
    return out;
}

