#version 330

uniform sampler2D uAreaLUT;

layout(location = 0) out vec4 oFragColor;
in vec2 vFrom;
in vec2 vTo;

vec4 computeCoverage(vec2 from, vec2 to, sampler2D SPIRV_Cross_CombineduAreaLUTuAreaLUTSampler)
{
    bvec2 _34 = bvec2(from.x < to.x);
    vec2 left = vec2(_34.x ? from.x : to.x, _34.y ? from.y : to.y);
    bvec2 _44 = bvec2(from.x < to.x);
    vec2 right = vec2(_44.x ? to.x : from.x, _44.y ? to.y : from.y);
    vec2 window = clamp(vec2(from.x, to.x), vec2(-0.5), vec2(0.5));
    float offset = mix(window.x, window.y, 0.5) - left.x;
    float t = offset / (right.x - left.x);
    float y = mix(left.y, right.y, t);
    float d = (right.y - left.y) / (right.x - left.x);
    float dX = window.x - window.y;
    return texture(SPIRV_Cross_CombineduAreaLUTuAreaLUTSampler, vec2(y + 8.0, abs(d * dX)) / vec2(16.0)) * dX;
}

void main()
{
    vec2 param = vFrom;
    vec2 param_1 = vTo;
    oFragColor = computeCoverage(param, param_1, uAreaLUT);
}

