#version 450

// pathfinder/shaders/blit.fs.glsl
//
// Copyright © 2020 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform sampler uSrcSampler;
layout(set = 1, binding = 0) uniform texture2D uSrc;

layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 oFragColor;

void main() {
    vec4 color = texture(sampler2D(uSrc, uSrcSampler), vTexCoord);
    oFragColor = vec4(color.rgb * color.a, color.a);
}
