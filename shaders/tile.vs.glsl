#version 450

// pathfinder/shaders/tile.vs.glsl
//
// Copyright © 2020 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform sampler uTextureMetadataSampler;
layout(set = 1, binding = 0) uniform texture2D uTextureMetadata;

layout(set = 0, binding = 0) uniform Globals {
    mat4 uTransform;
    vec2 uTileSize;
    ivec2 uTextureMetadataSize;
};

layout(location = 0) in ivec2 aTileOffset;
layout(location = 1) in ivec2 aTileOrigin;
layout(location = 2) in uvec2 aMaskTexCoord0;
layout(location = 3) in ivec2 aMaskBackdrop;
layout(location = 4) in int aColor;
layout(location = 5) in int aTileCtrl;

layout(location = 0) out vec3 vMaskTexCoord0;
layout(location = 1) out vec2 vColorTexCoord0;
layout(location = 2) out vec4 vBaseColor;
layout(location = 3) out float vTileCtrl;

void main() {
    vec2 tileOrigin = vec2(aTileOrigin), tileOffset = vec2(aTileOffset);
    vec2 position = (tileOrigin + tileOffset) * uTileSize;

    vec2 maskTexCoord0 = (vec2(aMaskTexCoord0) + tileOffset) * uTileSize;

    vec2 textureMetadataScale = vec2(1.0) / vec2(uTextureMetadataSize);
    vec2 metadataEntryCoord = vec2(aColor % 128 * 4, aColor / 128);
    vec2 colorTexMatrix0Coord = (metadataEntryCoord + vec2(0.5, 0.5)) * textureMetadataScale;
    vec2 colorTexOffsetsCoord = (metadataEntryCoord + vec2(1.5, 0.5)) * textureMetadataScale;
    vec2 baseColorCoord = (metadataEntryCoord + vec2(2.5, 0.5)) * textureMetadataScale;
    vec4 colorTexMatrix0 = texture(sampler2D(uTextureMetadata, uTextureMetadataSampler), colorTexMatrix0Coord);
    vec4 colorTexOffsets = texture(sampler2D(uTextureMetadata, uTextureMetadataSampler), colorTexOffsetsCoord);
    vec4 baseColor = texture(sampler2D(uTextureMetadata, uTextureMetadataSampler), baseColorCoord);

    vColorTexCoord0 = mat2(colorTexMatrix0) * position + colorTexOffsets.xy;
    vMaskTexCoord0 = vec3(maskTexCoord0, float(aMaskBackdrop.x));
    vBaseColor = baseColor;
    vTileCtrl = float(aTileCtrl);
    gl_Position = uTransform * vec4(position, 0.0, 1.0);
}
