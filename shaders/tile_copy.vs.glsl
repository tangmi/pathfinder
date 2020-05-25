#version 450

// pathfinder/shaders/tile_copy.vs.glsl
//
// Copyright © 2020 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

layout(set = 0, binding = 0) uniform Globals {
    mat4 uTransform;
    vec2 uTileSize;
};

layout(location = 0) in ivec2 aTilePosition;

void main() {
    vec2 position = vec2(aTilePosition) * uTileSize;
    gl_Position = uTransform * vec4(position, 0.0, 1.0);
}
