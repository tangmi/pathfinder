#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Globals
{
    float4x4 uOldTransform;
};

struct main0_out
{
    float4 oFragColor [[color(0)]];
};

struct main0_in
{
    float2 vTexCoord [[user(locn0)]];
};

fragment main0_out main0(main0_in in [[stage_in]], constant Globals& _13 [[buffer(0)]], texture2d<float> uTexture [[texture(0)]], sampler uTextureSampler [[sampler(0)]])
{
    main0_out out = {};
    float4 normTexCoord = _13.uOldTransform * float4(in.vTexCoord, 0.0, 1.0);
    float2 texCoord = ((normTexCoord.xy / float2(normTexCoord.w)) + float2(1.0)) * 0.5;
    out.oFragColor = uTexture.sample(uTextureSampler, texCoord);
    return out;
}

