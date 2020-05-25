#version 450

// pathfinder/shaders/clear.fs.glsl
//
// Copyright © 2019 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform Globals {
    vec4 uColor;
};

layout(location = 0) out vec4 oFragColor;

void main() {
    oFragColor = vec4(uColor.rgb, 1.0) * uColor.a;
}
