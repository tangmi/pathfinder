#version 430

layout(binding = 0, std140) uniform Globals
{
    vec2 uColorTextureSize0;
    vec2 uMaskTextureSize0;
    vec4 uFilterParams0;
    vec4 uFilterParams1;
    vec4 uFilterParams2;
    vec2 uFramebufferSize;
    int uCtrl;
} _1293;

uniform sampler2D uMaskTexture0;
uniform sampler2D uColorTexture0;
uniform sampler2D uGammaLUT;
uniform sampler2D uDestTexture;

layout(location = 0) in vec3 vMaskTexCoord0;
layout(location = 2) in vec4 vBaseColor;
layout(location = 1) in vec2 vColorTexCoord0;
layout(location = 0) out vec4 oFragColor;
layout(location = 3) in float vTileCtrl;

float sampleMask(float maskAlpha, vec2 maskTextureSize, vec3 maskTexCoord, int maskCtrl, sampler2D SPIRV_Cross_CombinedmaskTexturemaskTextureSampler)
{
    if (maskCtrl == 0)
    {
        return maskAlpha;
    }
    ivec2 maskTexCoordI = ivec2(floor(maskTexCoord.xy));
    vec4 texel = texture(SPIRV_Cross_CombinedmaskTexturemaskTextureSampler, (vec2(maskTexCoordI / ivec2(1, 4)) + vec2(0.5)) / maskTextureSize);
    float coverage = texel[maskTexCoordI.y % 4] + maskTexCoord.z;
    if ((maskCtrl & 1) != 0)
    {
        coverage = abs(coverage);
    }
    else
    {
        coverage = 1.0 - abs(1.0 - mod(coverage, 2.0));
    }
    return min(maskAlpha, coverage);
}

vec4 filterRadialGradient(vec2 colorTexCoord, vec2 colorTextureSize, vec2 fragCoord, vec2 framebufferSize, vec4 filterParams0, vec4 filterParams1, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler)
{
    vec2 lineFrom = filterParams0.xy;
    vec2 lineVector = filterParams0.zw;
    vec2 radii = filterParams1.xy;
    vec2 uvOrigin = filterParams1.zw;
    vec2 dP = colorTexCoord - lineFrom;
    vec2 dC = lineVector;
    float dR = radii.y - radii.x;
    float a = dot(dC, dC) - (dR * dR);
    float b = dot(dP, dC) + (radii.x * dR);
    float c = dot(dP, dP) - (radii.x * radii.x);
    float discrim = (b * b) - (a * c);
    vec4 color = vec4(0.0);
    if (abs(discrim) >= 9.9999997473787516355514526367188e-06)
    {
        vec2 ts = vec2((vec2(1.0, -1.0) * sqrt(discrim)) + vec2(b)) / vec2(a);
        if (ts.x > ts.y)
        {
            ts = ts.yx;
        }
        float _579;
        if (ts.x >= 0.0)
        {
            _579 = ts.x;
        }
        else
        {
            _579 = ts.y;
        }
        float t = _579;
        color = texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, uvOrigin + vec2(clamp(t, 0.0, 1.0), 0.0));
    }
    return color;
}

vec4 filterBlur(vec2 colorTexCoord, vec2 colorTextureSize, vec4 filterParams0, vec4 filterParams1, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler)
{
    vec2 srcOffsetScale = filterParams0.xy / colorTextureSize;
    int support = int(filterParams0.z);
    vec3 gaussCoeff = filterParams1.xyz;
    float gaussSum = gaussCoeff.x;
    vec4 color = texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, colorTexCoord) * gaussCoeff.x;
    vec2 _628 = gaussCoeff.xy * gaussCoeff.yz;
    gaussCoeff = vec3(_628.x, _628.y, gaussCoeff.z);
    for (int i = 1, i = 1; i <= support; i += 2)
    {
        float gaussPartialSum = gaussCoeff.x;
        vec2 _648 = gaussCoeff.xy * gaussCoeff.yz;
        gaussCoeff = vec3(_648.x, _648.y, gaussCoeff.z);
        gaussPartialSum += gaussCoeff.x;
        vec2 srcOffset = srcOffsetScale * (float(i) + (gaussCoeff.x / gaussPartialSum));
        color += ((texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, colorTexCoord - srcOffset) + texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, colorTexCoord + srcOffset)) * gaussPartialSum);
        gaussSum += (2.0 * gaussPartialSum);
        vec2 _692 = gaussCoeff.xy * gaussCoeff.yz;
        gaussCoeff = vec3(_692.x, _692.y, gaussCoeff.z);
    }
    return color / vec4(gaussSum);
}

float filterTextSample1Tap(float offset, vec2 colorTexCoord, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler)
{
    return texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, colorTexCoord + vec2(offset, 0.0)).x;
}

void filterTextSample9Tap(out vec4 outAlphaLeft, out float outAlphaCenter, out vec4 outAlphaRight, vec2 colorTexCoord, vec4 kernel, float onePixel, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler)
{
    bool wide = kernel.x > 0.0;
    float _256;
    if (wide)
    {
        float param = (-4.0) * onePixel;
        vec2 param_1 = colorTexCoord;
        _256 = filterTextSample1Tap(param, param_1, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
    }
    else
    {
        _256 = 0.0;
    }
    float param_2 = (-3.0) * onePixel;
    vec2 param_3 = colorTexCoord;
    float param_4 = (-2.0) * onePixel;
    vec2 param_5 = colorTexCoord;
    float param_6 = (-1.0) * onePixel;
    vec2 param_7 = colorTexCoord;
    outAlphaLeft = vec4(_256, filterTextSample1Tap(param_2, param_3, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler), filterTextSample1Tap(param_4, param_5, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler), filterTextSample1Tap(param_6, param_7, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler));
    float param_8 = 0.0;
    vec2 param_9 = colorTexCoord;
    outAlphaCenter = filterTextSample1Tap(param_8, param_9, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
    float param_10 = 1.0 * onePixel;
    vec2 param_11 = colorTexCoord;
    float param_12 = 2.0 * onePixel;
    vec2 param_13 = colorTexCoord;
    float param_14 = 3.0 * onePixel;
    vec2 param_15 = colorTexCoord;
    float _316;
    if (wide)
    {
        float param_16 = 4.0 * onePixel;
        vec2 param_17 = colorTexCoord;
        _316 = filterTextSample1Tap(param_16, param_17, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
    }
    else
    {
        _316 = 0.0;
    }
    outAlphaRight = vec4(filterTextSample1Tap(param_10, param_11, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler), filterTextSample1Tap(param_12, param_13, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler), filterTextSample1Tap(param_14, param_15, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler), _316);
}

float filterTextConvolve7Tap(vec4 alpha0, vec3 alpha1, vec4 kernel)
{
    return dot(alpha0, kernel) + dot(alpha1, kernel.zyx);
}

float filterTextGammaCorrectChannel(float bgColor, float fgColor, sampler2D SPIRV_Cross_CombinedgammaLUTgammaLUTSampler)
{
    return texture(SPIRV_Cross_CombinedgammaLUTgammaLUTSampler, vec2(fgColor, 1.0 - bgColor)).x;
}

vec3 filterTextGammaCorrect(vec3 bgColor, vec3 fgColor, sampler2D SPIRV_Cross_CombinedgammaLUTgammaLUTSampler)
{
    float param = bgColor.x;
    float param_1 = fgColor.x;
    float param_2 = bgColor.y;
    float param_3 = fgColor.y;
    float param_4 = bgColor.z;
    float param_5 = fgColor.z;
    return vec3(filterTextGammaCorrectChannel(param, param_1, SPIRV_Cross_CombinedgammaLUTgammaLUTSampler), filterTextGammaCorrectChannel(param_2, param_3, SPIRV_Cross_CombinedgammaLUTgammaLUTSampler), filterTextGammaCorrectChannel(param_4, param_5, SPIRV_Cross_CombinedgammaLUTgammaLUTSampler));
}

vec4 filterText(vec2 colorTexCoord, vec2 colorTextureSize, vec4 filterParams0, vec4 filterParams1, vec4 filterParams2, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, sampler2D SPIRV_Cross_CombinedgammaLUTgammaLUTSampler)
{
    vec4 kernel = filterParams0;
    vec3 bgColor = filterParams1.xyz;
    vec3 fgColor = filterParams2.xyz;
    bool gammaCorrectionEnabled = filterParams2.w != 0.0;
    vec3 alpha;
    if (kernel.w == 0.0)
    {
        alpha = texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, colorTexCoord).xxx;
    }
    else
    {
        vec2 param_3 = colorTexCoord;
        vec4 param_4 = kernel;
        float param_5 = 1.0 / colorTextureSize.x;
        vec4 param;
        float param_1;
        vec4 param_2;
        filterTextSample9Tap(param, param_1, param_2, param_3, param_4, param_5, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
        vec4 alphaLeft = param;
        float alphaCenter = param_1;
        vec4 alphaRight = param_2;
        vec4 param_6 = alphaLeft;
        vec3 param_7 = vec3(alphaCenter, alphaRight.xy);
        vec4 param_8 = kernel;
        float r = filterTextConvolve7Tap(param_6, param_7, param_8);
        vec4 param_9 = vec4(alphaLeft.yzw, alphaCenter);
        vec3 param_10 = alphaRight.xyz;
        vec4 param_11 = kernel;
        float g = filterTextConvolve7Tap(param_9, param_10, param_11);
        vec4 param_12 = vec4(alphaLeft.zw, alphaCenter, alphaRight.x);
        vec3 param_13 = alphaRight.yzw;
        vec4 param_14 = kernel;
        float b = filterTextConvolve7Tap(param_12, param_13, param_14);
        alpha = vec3(r, g, b);
    }
    if (gammaCorrectionEnabled)
    {
        vec3 param_15 = bgColor;
        vec3 param_16 = alpha;
        alpha = filterTextGammaCorrect(param_15, param_16, SPIRV_Cross_CombinedgammaLUTgammaLUTSampler);
    }
    return vec4(mix(bgColor, fgColor, alpha), 1.0);
}

vec4 sampleColor(vec2 colorTexCoord, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler)
{
    return texture(SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, colorTexCoord);
}

vec4 filterNone(vec2 colorTexCoord, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler)
{
    vec2 param = colorTexCoord;
    return sampleColor(param, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
}

vec4 filterColor(vec2 colorTexCoord, vec2 colorTextureSize, vec2 fragCoord, vec2 framebufferSize, vec4 filterParams0, vec4 filterParams1, vec4 filterParams2, int colorFilter, sampler2D SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, sampler2D SPIRV_Cross_CombinedgammaLUTgammaLUTSampler)
{
    switch (colorFilter)
    {
        case 1:
        {
            vec2 param = colorTexCoord;
            vec2 param_1 = colorTextureSize;
            vec2 param_2 = fragCoord;
            vec2 param_3 = framebufferSize;
            vec4 param_4 = filterParams0;
            vec4 param_5 = filterParams1;
            return filterRadialGradient(param, param_1, param_2, param_3, param_4, param_5, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
        }
        case 3:
        {
            vec2 param_6 = colorTexCoord;
            vec2 param_7 = colorTextureSize;
            vec4 param_8 = filterParams0;
            vec4 param_9 = filterParams1;
            return filterBlur(param_6, param_7, param_8, param_9, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
        }
        case 2:
        {
            vec2 param_10 = colorTexCoord;
            vec2 param_11 = colorTextureSize;
            vec4 param_12 = filterParams0;
            vec4 param_13 = filterParams1;
            vec4 param_14 = filterParams2;
            return filterText(param_10, param_11, param_12, param_13, param_14, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler, SPIRV_Cross_CombinedgammaLUTgammaLUTSampler);
        }
    }
    vec2 param_15 = colorTexCoord;
    return filterNone(param_15, SPIRV_Cross_CombinedcolorTexturecolorTextureSampler);
}

vec4 combineColor0(vec4 destColor, vec4 srcColor, int op)
{
    switch (op)
    {
        case 1:
        {
            return vec4(srcColor.xyz, srcColor.w * destColor.w);
        }
        case 2:
        {
            return vec4(destColor.xyz, srcColor.w * destColor.w);
        }
    }
    return destColor;
}

vec3 compositeScreen(vec3 destColor, vec3 srcColor)
{
    return (destColor + srcColor) - (destColor * srcColor);
}

vec3 compositeSelect(bvec3 cond, vec3 ifTrue, vec3 ifFalse)
{
    float _758;
    if (cond.x)
    {
        _758 = ifTrue.x;
    }
    else
    {
        _758 = ifFalse.x;
    }
    float _769;
    if (cond.y)
    {
        _769 = ifTrue.y;
    }
    else
    {
        _769 = ifFalse.y;
    }
    float _780;
    if (cond.z)
    {
        _780 = ifTrue.z;
    }
    else
    {
        _780 = ifFalse.z;
    }
    return vec3(_758, _769, _780);
}

vec3 compositeHardLight(vec3 destColor, vec3 srcColor)
{
    vec3 param = destColor;
    vec3 param_1 = (vec3(2.0) * srcColor) - vec3(1.0);
    bvec3 param_2 = lessThanEqual(srcColor, vec3(0.5));
    vec3 param_3 = (destColor * vec3(2.0)) * srcColor;
    vec3 param_4 = compositeScreen(param, param_1);
    return compositeSelect(param_2, param_3, param_4);
}

vec3 compositeColorDodge(vec3 destColor, vec3 srcColor)
{
    bvec3 destZero = equal(destColor, vec3(0.0));
    bvec3 srcOne = equal(srcColor, vec3(1.0));
    bvec3 param = srcOne;
    vec3 param_1 = vec3(1.0);
    vec3 param_2 = destColor / (vec3(1.0) - srcColor);
    bvec3 param_3 = destZero;
    vec3 param_4 = vec3(0.0);
    vec3 param_5 = compositeSelect(param, param_1, param_2);
    return compositeSelect(param_3, param_4, param_5);
}

vec3 compositeSoftLight(vec3 destColor, vec3 srcColor)
{
    bvec3 param = lessThanEqual(destColor, vec3(0.25));
    vec3 param_1 = ((((vec3(16.0) * destColor) - vec3(12.0)) * destColor) + vec3(4.0)) * destColor;
    vec3 param_2 = sqrt(destColor);
    vec3 darkenedDestColor = compositeSelect(param, param_1, param_2);
    bvec3 param_3 = lessThanEqual(srcColor, vec3(0.5));
    vec3 param_4 = destColor * (vec3(1.0) - destColor);
    vec3 param_5 = darkenedDestColor - destColor;
    vec3 factor = compositeSelect(param_3, param_4, param_5);
    return destColor + (((srcColor * 2.0) - vec3(1.0)) * factor);
}

float compositeDivide(float num, float denom)
{
    float _794;
    if (denom != 0.0)
    {
        _794 = num / denom;
    }
    else
    {
        _794 = 0.0;
    }
    return _794;
}

vec3 compositeRGBToHSL(vec3 rgb)
{
    float v = max(max(rgb.x, rgb.y), rgb.z);
    float xMin = min(min(rgb.x, rgb.y), rgb.z);
    float c = v - xMin;
    float l = mix(xMin, v, 0.5);
    vec3 _900;
    if (rgb.x == v)
    {
        _900 = vec3(0.0, rgb.yz);
    }
    else
    {
        vec3 _913;
        if (rgb.y == v)
        {
            _913 = vec3(2.0, rgb.zx);
        }
        else
        {
            _913 = vec3(4.0, rgb.xy);
        }
        _900 = _913;
    }
    vec3 terms = _900;
    float param = ((terms.x * c) + terms.y) - terms.z;
    float param_1 = c;
    float h = 1.0471975803375244140625 * compositeDivide(param, param_1);
    float param_2 = c;
    float param_3 = v;
    float s = compositeDivide(param_2, param_3);
    return vec3(h, s, l);
}

vec3 compositeHSL(vec3 destColor, vec3 srcColor, int op)
{
    switch (op)
    {
        case 12:
        {
            return vec3(srcColor.x, destColor.y, destColor.z);
        }
        case 13:
        {
            return vec3(destColor.x, srcColor.y, destColor.z);
        }
        case 14:
        {
            return vec3(srcColor.x, srcColor.y, destColor.z);
        }
        default:
        {
            return vec3(destColor.x, destColor.y, srcColor.z);
        }
    }
}

vec3 compositeHSLToRGB(vec3 hsl)
{
    float a = hsl.y * min(hsl.z, 1.0 - hsl.z);
    vec3 ks = mod(vec3(0.0, 8.0, 4.0) + vec3(hsl.x * 1.90985929965972900390625), vec3(12.0));
    return hsl.zzz - (clamp(min(ks - vec3(3.0), vec3(9.0) - ks), vec3(-1.0), vec3(1.0)) * a);
}

vec3 compositeRGB(vec3 destColor, vec3 srcColor, int op)
{
    switch (op)
    {
        case 1:
        {
            return destColor * srcColor;
        }
        case 2:
        {
            vec3 param = destColor;
            vec3 param_1 = srcColor;
            return compositeScreen(param, param_1);
        }
        case 3:
        {
            vec3 param_2 = srcColor;
            vec3 param_3 = destColor;
            return compositeHardLight(param_2, param_3);
        }
        case 4:
        {
            return min(destColor, srcColor);
        }
        case 5:
        {
            return max(destColor, srcColor);
        }
        case 6:
        {
            vec3 param_4 = destColor;
            vec3 param_5 = srcColor;
            return compositeColorDodge(param_4, param_5);
        }
        case 7:
        {
            vec3 param_6 = vec3(1.0) - destColor;
            vec3 param_7 = vec3(1.0) - srcColor;
            return vec3(1.0) - compositeColorDodge(param_6, param_7);
        }
        case 8:
        {
            vec3 param_8 = destColor;
            vec3 param_9 = srcColor;
            return compositeHardLight(param_8, param_9);
        }
        case 9:
        {
            vec3 param_10 = destColor;
            vec3 param_11 = srcColor;
            return compositeSoftLight(param_10, param_11);
        }
        case 10:
        {
            return abs(destColor - srcColor);
        }
        case 11:
        {
            return (destColor + srcColor) - ((vec3(2.0) * destColor) * srcColor);
        }
        case 12:
        case 13:
        case 14:
        case 15:
        {
            vec3 param_12 = destColor;
            vec3 param_13 = srcColor;
            vec3 param_14 = compositeRGBToHSL(param_12);
            vec3 param_15 = compositeRGBToHSL(param_13);
            int param_16 = op;
            vec3 param_17 = compositeHSL(param_14, param_15, param_16);
            return compositeHSLToRGB(param_17);
        }
    }
    return srcColor;
}

vec4 composite(vec4 srcColor, vec2 destTextureSize, vec2 fragCoord, int op, sampler2D SPIRV_Cross_CombineddestTexturedestTextureSampler)
{
    if (op == 0)
    {
        return srcColor;
    }
    vec2 destTexCoord = fragCoord / destTextureSize;
    vec4 destColor = texture(SPIRV_Cross_CombineddestTexturedestTextureSampler, destTexCoord);
    vec3 param = destColor.xyz;
    vec3 param_1 = srcColor.xyz;
    int param_2 = op;
    vec3 blendedRGB = compositeRGB(param, param_1, param_2);
    return vec4(((srcColor.xyz * (srcColor.w * (1.0 - destColor.w))) + (blendedRGB * (srcColor.w * destColor.w))) + (destColor.xyz * (1.0 - srcColor.w)), 1.0);
}

void calculateColor(int tileCtrl, int ctrl)
{
    int maskCtrl0 = (tileCtrl >> 0) & 3;
    float maskAlpha = 1.0;
    float param = maskAlpha;
    vec2 param_1 = _1293.uMaskTextureSize0;
    vec3 param_2 = vMaskTexCoord0;
    int param_3 = maskCtrl0;
    maskAlpha = sampleMask(param, param_1, param_2, param_3, uMaskTexture0);
    vec4 color = vBaseColor;
    int color0Combine = (ctrl >> 6) & 3;
    if (color0Combine != 0)
    {
        int color0Filter = (ctrl >> 4) & 3;
        vec2 param_4 = vColorTexCoord0;
        vec2 param_5 = _1293.uColorTextureSize0;
        vec2 param_6 = gl_FragCoord.xy;
        vec2 param_7 = _1293.uFramebufferSize;
        vec4 param_8 = _1293.uFilterParams0;
        vec4 param_9 = _1293.uFilterParams1;
        vec4 param_10 = _1293.uFilterParams2;
        int param_11 = color0Filter;
        vec4 color0 = filterColor(param_4, param_5, param_6, param_7, param_8, param_9, param_10, param_11, uColorTexture0, uGammaLUT);
        vec4 param_12 = color;
        vec4 param_13 = color0;
        int param_14 = color0Combine;
        color = combineColor0(param_12, param_13, param_14);
    }
    color.w *= maskAlpha;
    int compositeOp = (ctrl >> 8) & 15;
    vec4 param_15 = color;
    vec2 param_16 = _1293.uFramebufferSize;
    vec2 param_17 = gl_FragCoord.xy;
    int param_18 = compositeOp;
    color = composite(param_15, param_16, param_17, param_18, uDestTexture);
    vec3 _1392 = color.xyz * color.w;
    color = vec4(_1392.x, _1392.y, _1392.z, color.w);
    oFragColor = color;
}

void main()
{
    int param = int(vTileCtrl);
    int param_1 = _1293.uCtrl;
    calculateColor(param, param_1);
}

