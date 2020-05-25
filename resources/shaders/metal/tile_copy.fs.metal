#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Globals
{
    float2 uFramebufferSize;
};

struct main0_out
{
    float4 oFragColor [[color(0)]];
};

fragment main0_out main0(constant Globals& _17 [[buffer(0)]], texture2d<float> uSrc [[texture(0)]], sampler uSrcSampler [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 texCoord = gl_FragCoord.xy / _17.uFramebufferSize;
    out.oFragColor = uSrc.sample(uSrcSampler, texCoord);
    return out;
}

