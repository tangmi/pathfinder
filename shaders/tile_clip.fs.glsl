#version 330

// pathfinder/shaders/tile_clip.fs.glsl
//
// Copyright © 2020 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

precision highp float;
precision highp sampler2D;

uniform sampler2D uSrc;

in vec2 vTexCoord;
in float vBackdrop;

out vec4 oFragColor;

void main() {
    float alpha = clamp(abs(texture(uSrc, vTexCoord).r + vBackdrop), 0.0, 1.0);
    oFragColor = vec4(alpha, 0.0, 0.0, 1.0);
}
