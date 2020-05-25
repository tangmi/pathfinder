#version 450

// pathfinder/resources/shaders/demo_ground.fs.glsl
//
// Copyright © 2019 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.


layout(set = 0, binding = 0) uniform Globals {
    vec4 uGroundColor;
    vec4 uGridlineColor;
};

layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 oFragColor;

void main() {
    vec2 texCoordPx = fract(vTexCoord) / fwidth(vTexCoord);
    oFragColor = any(lessThanEqual(texCoordPx, vec2(1.0))) ? uGridlineColor : uGroundColor;
}
