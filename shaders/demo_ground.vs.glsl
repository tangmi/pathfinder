#version 450

// pathfinder/resources/shaders/demo_ground.vs.glsl
//
// Copyright © 2019 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform Globals {
    mat4 uTransform;
    int uGridlineCount;
};

layout(location = 0) in ivec2 aPosition;

layout(location = 0) out vec2 vTexCoord;

void main() {
    vTexCoord = vec2(aPosition * uGridlineCount);
    gl_Position = uTransform * vec4(ivec4(aPosition.x, 0, aPosition.y, 1));
}
