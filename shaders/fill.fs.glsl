#version 450

// pathfinder/shaders/fill.fs.glsl
//
// Copyright © 2020 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

#extension GL_GOOGLE_include_directive : enable

#include "fill.inc.glsl"

layout(set = 0, binding = 0) uniform sampler uAreaLUTSampler;
layout(set = 1, binding = 0) uniform texture2D uAreaLUT;

layout(location = 0) in vec2 vFrom;
layout(location = 1) in vec2 vTo;

layout(location = 0) out vec4 oFragColor;

void main() {
    oFragColor = computeCoverage(vFrom, vTo, uAreaLUT, uAreaLUTSampler);
}
