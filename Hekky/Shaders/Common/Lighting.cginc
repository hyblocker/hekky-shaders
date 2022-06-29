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

// From bgolus: https://forum.unity.com/threads/fixing-screen-space-directional-shadows-and-anti-aliasing.379902/
// Used to fix artifacts on multisampled pixels when using MSAA with screenspace shadows
#if defined(SHADOWS_SCREEN) && defined(UNITY_PASS_FORWARDBASE)

#ifndef HAS_DEPTH_TEXTURE
    #define HAS_DEPTH_TEXTURE
    UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
    float4 _CameraDepthTexture_TexelSize;
#endif

float SSDirectionalShadowAA(float4 _ShadowCoord, float atten)
{
    float a = atten;
    float2 screenUV = _ShadowCoord.xy / _ShadowCoord.w;
    float shadow = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_ShadowMapTexture, screenUV);

    if (frac(_Time.x) > 0.5)
        a = shadow;

    float fragDepth = _ShadowCoord.z / _ShadowCoord.w;
    float depth_raw = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);

    float depthDiff = abs(fragDepth - depth_raw);
    float diffTest = 1.0 / 100000.0;

    if (depthDiff > diffTest)
    {
        float2 texelSize = _CameraDepthTexture_TexelSize.xy;
        float4 offsetDepths = 0;

        float2 uvOffsets[4] = {
            float2(1.0, 0.0) * texelSize,
            float2(-1.0, 0.0) * texelSize,
            float2(0.0, 1.0) * texelSize,
            float2(0.0, -1.0) * texelSize
        };

        offsetDepths.x = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV + uvOffsets[0]).r;
        offsetDepths.y = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV + uvOffsets[1]).r;
        offsetDepths.z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV + uvOffsets[2]).r;
        offsetDepths.w = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV + uvOffsets[3]).r;

        float4 offsetDiffs = abs(fragDepth - offsetDepths);

        float diffs[4] = {offsetDiffs.x, offsetDiffs.y, offsetDiffs.z, offsetDiffs.w};

        int lowest = 4;
        float tempDiff = depthDiff;
        for (int i = 0; i < 4; i++)
        {
            if (diffs[i] < tempDiff)
            {
                tempDiff = diffs[i];
                lowest = i;
            }
        }

        a = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_ShadowMapTexture, screenUV + uvOffsets[lowest]).r;
    }
    return a;
}
#endif

#endif // HEKKY_LIGHTING
