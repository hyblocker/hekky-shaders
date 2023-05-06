#ifndef HEKKY_COMMON_SAMPLING
#define HEKKY_COMMON_SAMPLING

#include "Noise.cginc"

#ifndef TEXTURE2D_ARGS
#define TEXTURE2D_ARGS(textureName, samplerName) Texture2D textureName, SamplerState samplerName
#define TEXTURE2D_PARAM(textureName, samplerName) textureName, samplerName
#define SAMPLE_TEXTURE2D(textureName, samplerName, coord2) textureName.Sample(samplerName, coord2)
#endif

// Reimplement texture defines to force DX11
#define HEKKY_DECLARE_TEX2D(tex)                                                    Texture2D tex; SamplerState sampler##tex
#define HEKKY_DECLARE_TEX2D_NOSAMPLER(tex)                                          Texture2D tex
#define HEKKY_DECLARE_TEX2DARR(tex)                                                 Texture2DArray tex; SamplerState sampler##tex
#define HEKKY_DECLARE_TEX2DARR_NOSAMPLER(tex)                                       Texture2DArray tex

#define HEKKY_SAMPLE_TEX2D(tex, coord)                                              tex.Sample(sampler##tex, coord)
#define HEKKY_SAMPLE_TEX2D_LOD(tex, coord, lod)                                     tex.Sample(sampler##tex, coord, lod)
#define HEKKY_SAMPLE_TEX2D_SAMPLER(tex, coord, sampler)                             tex.Sample(sampler, coord)
#define HEKKY_SAMPLE_TEX2D_SAMPLER_LOD(tex, coord, sampler, lod)                    tex.Sample(sampler, coord, lod)

#define HEKKY_SAMPLE_TEX2D_LEVEL(tex, coord, mip)                                   tex.SampleLevel(sampler##tex, coord, mip)
#define HEKKY_SAMPLE_TEX2D_SAMPLER_LEVEL(tex, coord, sampler, mip)                  tex.SampleLevel(sampler, coord, mip)
#define HEKKY_SAMPLE_TEX2D_GRAD(tex, coord, dx, dy)                                 tex.SampleGrad(sampler##tex, coord, dx, dy)
#define HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(tex, coord, sampler, dx, dy)                tex.SampleGrad(sampler, coord, dx, dy)

#define HEKKY_SAMPLE_TEX2DARR(tex, coord)                                           tex.Sample(sampler##tex, coord)
#define HEKKY_SAMPLE_TEX2DARR_LOD(tex, coord, lod)                                  tex.Sample(sampler##tex, coord, lod)
#define HEKKY_SAMPLE_TEX2DARR_SAMPLER(tex, coord, sampler)                          tex.Sample(sampler, coord)
#define HEKKY_SAMPLE_TEX2DARR_SAMPLER_LOD(tex, coord, sampler, lod)                 tex.Sample(sampler, coord, lod)

#define HEKKY_SAMPLE_GRAD_TEX2DARR(tex, coord, dx, dy)                              tex.SampleGrad(sampler##tex, coord, dx, dy)
#define HEKKY_SAMPLE_GRAD_TEX2DARR_SAMPLER(tex, coord, sampler, dx, dy)             tex.SampleGrad(sampler, coord, dx, dy)

#define HEKKY_DECLARE_TEX3D(tex)                                                    Texture3D tex; SamplerState sampler##tex
#define HEKKY_DECLARE_TEX3D_NOSAMPLER(tex)                                          Texture3D tex

#define HEKKY_SAMPLE_TEX3D(tex, coord)                                              tex.Sample(sampler##tex, coord)
#define HEKKY_SAMPLE_TEX3D_LOD(tex, coord, lod)                                     tex.Sample(sampler##tex, coord, lod)
#define HEKKY_SAMPLE_TEX3D_SAMPLER(tex, coord, sampler)                             tex.Sample(sampler, coord)
#define HEKKY_SAMPLE_TEX3D_SAMPLER_LOD(tex, coord, sampler, lod)                    tex.Sample(sampler, coord, lod)

#define HEKKY_DECLARE_TEX_CUBE(tex)                                                 TextureCube tex; SamplerState sampler##tex
#define HEKKY_DECLARE_TEX_CUBE_NOSAMPLER(tex)                                       TextureCube tex

#define HEKKY_SAMPLE_TEX_CUBE(tex, coord)                                           tex.Sample(sampler##tex, coord)
#define HEKKY_SAMPLE_TEX_CUBE_LOD(tex, coord, lod)                                  tex.Sample(sampler##tex, coord, lod)
#define HEKKY_SAMPLE_TEX_CUBE_SAMPLER(tex, coord, sampler)                          tex.Sample(sampler, coord)
#define HEKKY_SAMPLE_TEX_CUBE_SAMPLER_LOD(tex, coord, sampler, lod)                 tex.Sample(sampler, coord, lod)

#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLCORE)
#define HEKKY_LOD_TEX2D(tex, coord)                                                 tex.CalculateLevelOfDetail (sampler##tex,coord)
#else
// Just match the type i.e. define as a float value
#define HEKKY_LOD_TEX2D(tex,coord) float(0)
#endif

// Screenspace textures should be treated differently, and always sampled from the highest mipmap level
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)

#define HEKKY_DECLARE_TEX2D_SCREENSPACE(tex)                                        HEKKY_DECLARE_TEX2DARR(tex)
#define HEKKY_DECLARE_TEX2D_SCREENSPACE_NOSAMPLER(tex)                              HEKKY_DECLARE_TEX2DARR_NOSAMPLER(tex)
#define HEKKY_SAMPLE_TEX2D_SCREENSPACE(tex, coord)                                  HEKKY_SAMPLE_TEX2DARR_LOD(tex, float3(coord, (float)unity_StereoEyeIndex), 0)
#define HEKKY_SAMPLE_TEX2D_SCREENSPACE_SAMPLER(tex, sampler, coord)                 HEKKY_SAMPLE_TEX2DARR_SAMPLER_LOD(tex, sampler, float3(coord, (float)unity_StereoEyeIndex), 0)

#else

#define HEKKY_DECLARE_TEX2D_SCREENSPACE(tex)                                        HEKKY_DECLARE_TEX2D(tex)
#define HEKKY_DECLARE_TEX2D_SCREENSPACE_NOSAMPLER(tex)                              HEKKY_DECLARE_TEX2D_NOSAMPLER(tex)
#define HEKKY_SAMPLE_TEX2D_SCREENSPACE(tex, coord)                                  HEKKY_SAMPLE_TEX2D_LOD(tex, coord, 0)
#define HEKKY_SAMPLE_TEX2D_SCREENSPACE_SAMPLER(tex, sampler, coord)                 HEKKY_SAMPLE_TEX2D_SAMPLER_LOD(tex, sampler, coord, 0)

#endif // defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)

// Adapted from https://stackoverflow.com/a/42179924
inline float4 cubic(float v)
{
    float4 n = float4(1.0, 2.0, 3.0, 4.0) - v;
    float4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return float4(x, y, z, w) * (1.0 / 6.0);
}

inline float4 SampleTexture2DBicubicFilter(TEXTURE2D_ARGS(tex, smp), float2 coord, float4 texSize)
{
    coord = coord * texSize.xy - 0.5;

    float2 fxy = frac(coord);
    coord -= fxy;

    float4 xcubic = cubic(fxy.x);
    float4 ycubic = cubic(fxy.y);

    float4 c = coord.xxyy + float2(-0.5, +1.5).xyxy;
    float4 s = float4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    float4 offset = c + float4(xcubic.yw, ycubic.yw) / s;

    const float4 sample0 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.xz * texSize.zw, smp);
    const float4 sample1 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.yz * texSize.zw, smp);
    const float4 sample2 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.xw * texSize.zw, smp);
    const float4 sample3 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.yw * texSize.zw, smp);

    const float sx = s.x / (s.x + s.y);
    const float sy = s.z / (s.z + s.w);

    return lerp(lerp(sample3, sample2, sx), lerp(sample1, sample0, sx), sy);
}

inline float4 SampleTexture2DEdgePreserving(TEXTURE2D_ARGS(tex, smp), float2 coord, float4 texSize)
{
    const float EDGE_PRESERVATION_SAMPLE_THRESHOLD = 0.1;
    
    float2 coordOrig = coord;
    
    coord = coord * texSize.zw - 0.5;

    float2 fxy = frac(coord);
    coord -= fxy;

    float4 xcubic = cubic(fxy.x);
    float4 ycubic = cubic(fxy.y);

    float4 c = coord.xxyy + float2 (-0.5, +1.5).xyxy;
    float4 s = float4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    float4 offset = c + float4 (xcubic.yw, ycubic.yw) / s;

    const float4 sample0 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.xz * texSize.xy, smp);
    const float4 sample1 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.yz * texSize.xy, smp);
    const float4 sample2 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.xw * texSize.xy, smp);
    const float4 sample3 = HEKKY_SAMPLE_TEX2D_SAMPLER(tex, offset.yw * texSize.xy, smp);

    const float sx = s.x / (s.x + s.y);
    const float sy = s.z / (s.z + s.w);

    float4 bicubicSample = lerp(lerp(sample3, sample2, sx), lerp(sample1, sample0, sx), sy);
    float4 blendFactorCol = ((sample3 + sample2) / sx - (sample1 + sample0) / sx) * sy;
    float blendFactor = (blendFactorCol.x + blendFactorCol.y + blendFactorCol.z + blendFactorCol.w) / 4.f;
    blendFactor = step(0.01, blendFactor);
    // blendFactor = step(EDGE_PRESERVATION_SAMPLE_THRESHOLD, blendFactor);
    // blendFactor = step(EDGE_PRESERVATION_SAMPLE_THRESHOLD, blendFactor);
    return blendFactor * sample0 + bicubicSample * (1.f - blendFactor);
    // return lerp(bicubicSample, sample0, blendFactor);
}

// =====================================================================================================
//                                                LIGHTMAPS
// =====================================================================================================

// These functions are basically the exact same thing, for different lightmap types
// They will sample using bicubic sampling on DX11
// They also remove the necessity of manually sampling the textures yourself

#ifndef NO_LIGHTMAP

inline float4 SampleLightmapBicubic(float2 uv)
{
    #ifdef SHADER_API_D3D11
        float width, height;
        unity_Lightmap.GetDimensions(width, height);
        const float4 unity_Lightmap_TexelSize = float4(width, height, 1.0/width, 1.0/height);
        return SampleTexture2DBicubicFilter(TEXTURE2D_PARAM(unity_Lightmap, samplerunity_Lightmap),
            uv, unity_Lightmap_TexelSize);

    #else
        return HEKKY_SAMPLE_TEX2D_SAMPLER(unity_Lightmap, samplerunity_Lightmap, uv);
    #endif
}
inline float4 SampleLightmapDirBicubic(float2 uv)
{
    #ifdef SHADER_API_D3D11
        float width, height;
        unity_LightmapInd.GetDimensions(width, height);
        const float4 unity_LightmapInd_TexelSize = float4(width, height, 1.0/width, 1.0/height);
        return SampleTexture2DBicubicFilter(TEXTURE2D_PARAM(unity_LightmapInd, samplerunity_Lightmap),
            uv, unity_LightmapInd_TexelSize);

    #else
        return HEKKY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, samplerunity_Lightmap, uv);
    #endif
}
inline float4 SampleDynamicLightmapBicubic(float2 uv)
{
    #ifdef SHADER_API_D3D11
        float width, height;
        unity_DynamicLightmap.GetDimensions(width, height);
        const float4 unity_DynamicLightmap_TexelSize = float4(width, height, 1.0/width, 1.0/height);
        return SampleTexture2DBicubicFilter(TEXTURE2D_PARAM(unity_DynamicLightmap, samplerunity_DynamicLightmap),
            uv, unity_DynamicLightmap_TexelSize);

    #else
        return HEKKY_SAMPLE_TEX2D_SAMPLER(unity_DynamicLightmap, samplerunity_DynamicLightmap, uv);
    #endif
}
inline float4 SampleDynamicLightmapDirBicubic(float2 uv)
{
    #ifdef SHADER_API_D3D11
        float width, height;
        unity_DynamicDirectionality.GetDimensions(width, height);
        const float4 unity_DynamicDirectionality_TexelSize = float4(width, height, 1.0/width, 1.0/height);
        return SampleTexture2DBicubicFilter(TEXTURE2D_PARAM(unity_DynamicDirectionality, samplerunity_DynamicLightmap),
            uv, unity_DynamicDirectionality_TexelSize);

    #else
        return HEKKY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, samplerunity_DynamicLightmap, uv);
    #endif
}

#endif // NO_LIGHTMAP

// Thanks bgolus https://bgolus.medium.com/normal-mapping-for-a-triplanar-shader-10bf39dca05a#0f18
inline float4 sampleTexture2DArrayTriplanarFast(Texture2DArray textures, SamplerState theSampler, float3 position, float3 normal, int index, float4 texScaleTranslate)
{
    // calculate triplanar blend
    half3 triBlend = pow(abs(normal), 4);
    triBlend /= max(dot(triBlend, half3(1,1,1)), 0.0001);

    // calculate triplanar uvs
    // applying texture scale and offset values ala TRANSFORM_TEX macro
    float2 uvX = position.zy * texScaleTranslate.xy + texScaleTranslate.zw;
    float2 uvY = position.xz * texScaleTranslate.xy + texScaleTranslate.zw;
    float2 uvZ = position.xy * texScaleTranslate.xy + texScaleTranslate.zw;

    // minor optimization of sign(), prevents return value of 0
    const half3 axisSign = normal < 0 ? -1 : 1;
                
    // flip UVs horizontally to correct for back side projection
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
              
    // albedo textures
    const fixed4 colX = HEKKY_SAMPLE_TEX2DARR_SAMPLER(textures, float3(uvX, index), theSampler);
    const fixed4 colY = HEKKY_SAMPLE_TEX2DARR_SAMPLER(textures, float3(uvY, index), theSampler);
    const fixed4 colZ = HEKKY_SAMPLE_TEX2DARR_SAMPLER(textures, float3(uvZ, index), theSampler);
    const fixed4 col = colX * triBlend.x + colY * triBlend.y + colZ * triBlend.z;

    return col;
}

inline float3 sampleTexture2DArrayTriplanarNormalsFast(Texture2DArray textures, SamplerState theSampler, float3 position, float3 normal, int index, float4 texScaleTranslate, float normalScale)
{
    // calculate triplanar blend
    half3 triBlend = pow(abs(normal), 4);
    triBlend /= max(dot(triBlend, half3(1,1,1)), 0.0001);

    // calculate triplanar uvs
    // applying texture scale and offset values ala TRANSFORM_TEX macro
    float2 uvX = position.zy * texScaleTranslate.xy + texScaleTranslate.zw;
    float2 uvY = position.xz * texScaleTranslate.xy + texScaleTranslate.zw;
    float2 uvZ = position.xy * texScaleTranslate.xy + texScaleTranslate.zw;

    // minor optimization of sign(), prevents return value of 0
    const half3 axisSign = normal < 0 ? -1 : 1;
                
    // flip UVs horizontally to correct for back side projection
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
    
    // tangent space normal maps
    half3 tNormalX = UnpackScaleNormal(HEKKY_SAMPLE_TEX2DARR_SAMPLER(textures, float3(uvX, index), theSampler), normalScale);
    half3 tNormalY = UnpackScaleNormal(HEKKY_SAMPLE_TEX2DARR_SAMPLER(textures, float3(uvY, index), theSampler), normalScale);
    half3 tNormalZ = UnpackScaleNormal(HEKKY_SAMPLE_TEX2DARR_SAMPLER(textures, float3(uvZ, index), theSampler), normalScale);
    
    // flip normal maps' x axis to account for flipped UVs
    tNormalX.x *= axisSign.x;
    tNormalY.x *= axisSign.y;
    tNormalZ.x *= -axisSign.z;
  
    // swizzle world normals to match tangent space and apply Whiteout normal blend
    tNormalX = half3(tNormalX.xy + normal.zy, tNormalX.z * normal.x);
    tNormalY = half3(tNormalY.xy + normal.xz, tNormalY.z * normal.y);
    tNormalZ = half3(tNormalZ.xy + normal.xy, tNormalZ.z * normal.z);

    // swizzle tangent normals to match world normal and blend together
    const half3 worldNormal = normalize(
        tNormalX.zyx * triBlend.x +
        tNormalY.xzy * triBlend.y +
        tNormalZ.xyz * triBlend.z
    );

    return worldNormal;
}

float4 sampleTexture2dStochastic(Texture2D tex, SamplerState theSampler, float2 uv) {
    // Thanks Mochie
    // skew the uv to create triangular grid
    float2 skewUV = mul(float2x2 (1.0, 0.0, -0.57735027, 1.15470054), uv * 3.464);

    // vertices on the triangular grid
    int2 vertID = int2(floor(skewUV));

    // barycentric coordinates of uv position
    float3 temp = float3(frac(skewUV), 0);
    temp.z = 1.0 - temp.x - temp.y;
    
    // each vertex on the grid gets an according weight value
    int2 vertA, vertB, vertC;
    float weightA, weightB, weightC;

    // determine which triangle we're in
    if (temp.z > 0.0){
        weightA = temp.z;
        weightB = temp.y;
        weightC = temp.x;
        vertA = vertID;
        vertB = vertID + int2(0, 1);
        vertC = vertID + int2(1, 0);
    }
    else {
        weightA = -temp.z;
        weightB = 1.0 - temp.y;
        weightC = 1.0 - temp.x;
        vertA = vertID + int2(1, 1);
        vertB = vertID + int2(1, 0);
        vertC = vertID + int2(0, 1);
    }    

    // get derivatives to avoid triangular artifacts
    float2 dx = ddx(uv);
    float2 dy = ddy(uv);

    // offset uvs using magic numbers
    float2 randomA = uv + frac(sin(fmod(float2(dot(vertA, float2(127.1, 311.7)), dot(vertA, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
    float2 randomB = uv + frac(sin(fmod(float2(dot(vertB, float2(127.1, 311.7)), dot(vertB, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
    float2 randomC = uv + frac(sin(fmod(float2(dot(vertC, float2(127.1, 311.7)), dot(vertC, float2(269.5, 183.3))), 3.14159)) * 43758.5453);
    
    // get texture samples
    float4 sampleA = HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(tex, randomA, theSampler, dx, dy);
    float4 sampleB = HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(tex, randomB, theSampler, dx, dy);
    float4 sampleC = HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(tex, randomC, theSampler, dx, dy);
    
    // blend samples with weights    
    return sampleA * weightA + sampleB * weightB + sampleC * weightC;
}

#endif // HEKKY_COMMON_SAMPLING