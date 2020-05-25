#version 430

layout(binding = 0, std140) uniform Globals
{
    mat4 uTransform;
    vec2 uTileSize;
    ivec2 uTextureMetadataSize;
} _28;

uniform sampler2D uTextureMetadata;

layout(location = 1) in ivec2 aTileOrigin;
layout(location = 0) in ivec2 aTileOffset;
layout(location = 2) in uvec2 aMaskTexCoord0;
layout(location = 4) in int aColor;
layout(location = 1) out vec2 vColorTexCoord0;
layout(location = 0) out vec3 vMaskTexCoord0;
layout(location = 3) in ivec2 aMaskBackdrop;
layout(location = 2) out vec4 vBaseColor;
layout(location = 3) out float vTileCtrl;
layout(location = 5) in int aTileCtrl;

void main()
{
    vec2 tileOrigin = vec2(aTileOrigin);
    vec2 tileOffset = vec2(aTileOffset);
    vec2 position = (tileOrigin + tileOffset) * _28.uTileSize;
    vec2 maskTexCoord0 = (vec2(aMaskTexCoord0) + tileOffset) * _28.uTileSize;
    vec2 textureMetadataScale = vec2(1.0) / vec2(_28.uTextureMetadataSize);
    vec2 metadataEntryCoord = vec2(float((aColor % 128) * 4), float(aColor / 128));
    vec2 colorTexMatrix0Coord = (metadataEntryCoord + vec2(0.5)) * textureMetadataScale;
    vec2 colorTexOffsetsCoord = (metadataEntryCoord + vec2(1.5, 0.5)) * textureMetadataScale;
    vec2 baseColorCoord = (metadataEntryCoord + vec2(2.5, 0.5)) * textureMetadataScale;
    vec4 colorTexMatrix0 = textureLod(uTextureMetadata, colorTexMatrix0Coord, 0.0);
    vec4 colorTexOffsets = textureLod(uTextureMetadata, colorTexOffsetsCoord, 0.0);
    vec4 baseColor = textureLod(uTextureMetadata, baseColorCoord, 0.0);
    vColorTexCoord0 = (mat2(vec2(colorTexMatrix0.xy), vec2(colorTexMatrix0.zw)) * position) + colorTexOffsets.xy;
    vMaskTexCoord0 = vec3(maskTexCoord0, float(aMaskBackdrop.x));
    vBaseColor = baseColor;
    vTileCtrl = float(aTileCtrl);
    gl_Position = _28.uTransform * vec4(position, 0.0, 1.0);
}

