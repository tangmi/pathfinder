#version 450

// pathfinder/shaders/reproject.vs.glsl
//
// Copyright © 2019 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform Globals {
    mat4 uNewTransform;
};

layout(location = 0) in ivec2 aPosition;

layout(location = 0) out vec2 vTexCoord;

void main() {
    vec2 position = vec2(aPosition);
    vTexCoord = position;

#ifdef PF_ORIGIN_UPPER_LEFT
    // FIXME(pcwalton): This is wrong.
    position.y = 1.0 - position.y;
#endif
    gl_Position = uNewTransform * vec4(position, 0.0, 1.0);
}
