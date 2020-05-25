#version 450

// pathfinder/shaders/debug_texture.vs.glsl
//
// Copyright © 2019 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.


layout(set = 0, binding = 0) uniform Globals {
    vec2 uFramebufferSize;
    vec2 uTextureSize;
};

layout(location = 0) in ivec2 aPosition;
layout(location = 1) in ivec2 aTexCoord;

layout(location = 0) out vec2 vTexCoord;

void main() {
    vTexCoord = vec2(aTexCoord) / uTextureSize;
    vec2 position = vec2(aPosition) / uFramebufferSize * 2.0 - 1.0;
    gl_Position = vec4(position.x, -position.y, 0.0, 1.0);
}
