// Automatically generated from files in pathfinder/shaders/. Do not edit!
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct main0_out
{
    float3 vMaskTexCoord0 [[user(locn0)]];
    float2 vColorTexCoord0 [[user(locn1)]];
    float4 vBaseColor [[user(locn2)]];
    float vTileCtrl [[user(locn3)]];
    float4 gl_Position [[position]];
};

struct main0_in
{
    int2 aTileOffset [[attribute(0)]];
    int2 aTileOrigin [[attribute(1)]];
    uint2 aMaskTexCoord0 [[attribute(2)]];
    int2 aMaskBackdrop [[attribute(3)]];
    int aColor [[attribute(4)]];
    int aTileCtrl [[attribute(5)]];
};

vertex main0_out main0(main0_in in [[stage_in]], constant int2& uTextureMetadataSize [[buffer(1)]], constant float2& uTileSize [[buffer(0)]], constant float4x4& uTransform [[buffer(2)]], texture2d<float> uTextureMetadata [[texture(0)]], sampler uTextureMetadataSmplr [[sampler(0)]])
{
    main0_out out = {};
    float2 tileOrigin = float2(in.aTileOrigin);
    float2 tileOffset = float2(in.aTileOffset);
    float2 position = (tileOrigin + tileOffset) * uTileSize;
    float2 maskTexCoord0 = (float2(in.aMaskTexCoord0) + tileOffset) * uTileSize;
    float2 textureMetadataScale = float2(1.0) / float2(uTextureMetadataSize);
    float2 metadataEntryCoord = float2(float((in.aColor % 128) * 4), float(in.aColor / 128));
    float2 colorTexMatrix0Coord = (metadataEntryCoord + float2(0.5)) * textureMetadataScale;
    float2 colorTexOffsetsCoord = (metadataEntryCoord + float2(1.5, 0.5)) * textureMetadataScale;
    float2 baseColorCoord = (metadataEntryCoord + float2(2.5, 0.5)) * textureMetadataScale;
    float4 colorTexMatrix0 = uTextureMetadata.sample(uTextureMetadataSmplr, colorTexMatrix0Coord, level(0.0));
    float4 colorTexOffsets = uTextureMetadata.sample(uTextureMetadataSmplr, colorTexOffsetsCoord, level(0.0));
    float4 baseColor = uTextureMetadata.sample(uTextureMetadataSmplr, baseColorCoord, level(0.0));
    out.vColorTexCoord0 = (float2x2(float2(colorTexMatrix0.xy), float2(colorTexMatrix0.zw)) * position) + colorTexOffsets.xy;
    out.vMaskTexCoord0 = float3(maskTexCoord0, float(in.aMaskBackdrop.x));
    out.vBaseColor = baseColor;
    out.vTileCtrl = float(in.aTileCtrl);
    out.gl_Position = uTransform * float4(position, 0.0, 1.0);
    return out;
}

