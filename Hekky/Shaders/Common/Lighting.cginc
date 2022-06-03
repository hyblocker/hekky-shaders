#ifndef HEKKY_LIGHTING
#define HEKKY_LIGHTING

// Some functions in this file are taken from Standard Shader CGIncludes. Those are licensed under the MIT license

inline fixed4 SampleShadowMaskBicubic(float2 uv)
{
    #ifdef SHADER_API_D3D11
    float width, height;
    unity_ShadowMask.GetDimensions(width, height);

    const float4 unity_ShadowMask_TexelSize = float4(width, height, 1.0 / width, 1.0 / height);

    return SampleTexture2DBicubicFilter(TEXTURE2D_PARAM(unity_ShadowMask, samplerunity_ShadowMask),
                                        uv, unity_ShadowMask_TexelSize);
    #else
        return SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_ShadowMask, uv);
        return HEKKY_SAMPLE_TEX2D_SAMPLER(unity_ShadowMask, uv, samplerunity_ShadowMask);
    #endif
}

inline fixed UnitySampleBakedOcclusionBicubic(float2 lightmapUV, float3 worldPos)
{
    #if defined (SHADOWS_SHADOWMASK) || 1
    #if defined(LIGHTMAP_ON)
    fixed4 rawOcclusionMask = SampleShadowMaskBicubic(lightmapUV.xy);
    #else
    fixed4 rawOcclusionMask = fixed4(1.0, 1.0, 1.0, 1.0);
    #if UNITY_LIGHT_PROBE_PROXY_VOLUME
    if (unity_ProbeVolumeParams.x == 1.0)
        rawOcclusionMask = LPPV_SampleProbeOcclusion(worldPos);
    else
        rawOcclusionMask = SampleShadowMaskBicubic(lightmapUV.xy);
    #else
    rawOcclusionMask = SampleShadowMaskBicubic(lightmapUV.xy);
    #endif
    #endif
    return saturate(dot(rawOcclusionMask, unity_OcclusionMaskSelector));

    #else

    //In forward dynamic objects can only get baked occlusion from LPPV, light probe occlusion is done on the CPU by attenuating the light color.
    fixed atten = 1.0f;
    #if defined(UNITY_INSTANCING_ENABLED) && defined(UNITY_USE_SHCOEFFS_ARRAYS)
    // ...unless we are doing instancing, and the attenuation is packed into SHC array's .w component.
    atten = unity_SHC.w;
    #endif

    #if UNITY_LIGHT_PROBE_PROXY_VOLUME && !defined(LIGHTMAP_ON) && !UNITY_STANDARD_SIMPLE
    fixed4 rawOcclusionMask = atten.xxxx;
    if (unity_ProbeVolumeParams.x == 1.0)
        rawOcclusionMask = LPPV_SampleProbeOcclusion(worldPos);
    return saturate(dot(rawOcclusionMask, unity_OcclusionMaskSelector));
    #endif

    return atten;
    #endif
}

inline void GetBakedAttenuation(inout float atten, float2 lightmapUV, float3 worldPos)
{
    // Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
    #if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
        half bakedAtten = UnitySampleBakedOcclusionBicubic(lightmapUV.xy, worldPos);
        float zDist = dot(_WorldSpaceCameraPos - worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(worldPos, zDist);
        atten = UnityMixRealtimeAndBakedShadows(atten, bakedAtten, UnityComputeShadowFade(fadeDist));
    #endif
}

#endif // HEKKY_LIGHTING
