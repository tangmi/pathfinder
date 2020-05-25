#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Globals
{
    float2 uFramebufferSize;
    float2 uTextureSize;
};

struct main0_out
{
    float2 vTexCoord [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct main0_in
{
    int2 aPosition [[attribute(0)]];
    int2 aTexCoord [[attribute(1)]];
};

vertex main0_out main0(main0_in in [[stage_in]], constant Globals& _18 [[buffer(0)]])
{
    main0_out out = {};
    out.vTexCoord = float2(in.aTexCoord) / _18.uTextureSize;
    float2 position = ((float2(in.aPosition) / _18.uFramebufferSize) * 2.0) - float2(1.0);
    out.gl_Position = float4(position.x, -position.y, 0.0, 1.0);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

