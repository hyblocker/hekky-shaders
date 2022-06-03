#ifndef HEKKY_COMMON_SAMPLING
#define HEKKY_COMMON_SAMPLING

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

#define HEKKY_SAMPLE_TEX2DARR(tex, coord)                                           tex.Sample(sampler##tex, coord)
#define HEKKY_SAMPLE_TEX2DARR_LOD(tex, coord, lod)                                  tex.Sample(sampler##tex, coord, lod)
#define HEKKY_SAMPLE_TEX2DARR_SAMPLER(tex, coord, sampler)                          tex.Sample(sampler, coord)
#define HEKKY_SAMPLE_TEX2DARR_SAMPLER_LOD(tex, coord, sampler, lod)                 tex.Sample(sampler, coord, lod)

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

// =====================================================================================================
//                                           SPHERICAL HARMONICS
// =====================================================================================================

// https://web.archive.org/web/20160313132301/http://www.geomerics.com/wp-content/uploads/2015/08/CEDEC_Geomerics_ReconstructingDiffuseLighting1.pdf
inline float shEvaluateDiffuseL1Geomerics_local(const float L0, const float3 L1, const float3 n)
{
    // average energy
    // clamp negative values
    const float R0 = max(L0, 0.0);

    // average light direction
    const float3 R1 = 0.5f * L1;
    const float magR1 = length(R1);
    const float lightDirectionalRatio = magR1 / R0;

    // solve for dynamic range constant a
    const float a = (1.0f - lightDirectionalRatio) / (1.0f + lightDirectionalRatio);

    // angle between normal and directional L1
    float q = 0.5f + 0.5f * dot(normalize(R1), n);
    q = saturate(q);

    // power of q
    const float p = 1.0f + 2.0f * lightDirectionalRatio;
    
    return R0 * (a + (1.0f - a) * (p + 1.0f) * pow(q, p));
}

#endif // HEKKY_COMMON_SAMPLING