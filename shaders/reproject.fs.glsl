#version 450

// pathfinder/shaders/reproject.fs.glsl
//
// Copyright © 2019 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform sampler uTextureSampler;
layout(set = 1, binding = 0) uniform texture2D uTexture;

layout(set = 0, binding = 0) uniform Globals {
    mat4 uOldTransform;
};

layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 oFragColor;

void main() {
    vec4 normTexCoord = uOldTransform * vec4(vTexCoord, 0.0, 1.0);
    vec2 texCoord = ((normTexCoord.xy / normTexCoord.w) + 1.0) * 0.5;
    oFragColor = texture(sampler2D(uTexture, uTextureSampler), texCoord);
}
