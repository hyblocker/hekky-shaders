#ifndef HEKKY_LIGHTING
#define HEKKY_LIGHTING

#include "UnityShadowLibrary.cginc"
#include "../Common/Sampling.cginc"

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

        a = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_ShadowMapTexture, screenUV + uvOffsets[lowest]).r * shadow;
    }
    return a;
}
#endif

// ====================================================================
//                            LIGHTING DATA
// ====================================================================

// A singular Unity Light
struct Light {
    // rgb, pre-exposed intensity
    float4 colorIntensity;
    float3 l; // L
    float NdotL;
    float attenuation;
    float3 worldPosition;
    float distance; // Pre-computed distance between light and pixel
};

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

// ==============================================================================================================
//                                                  LIGHT PROBES 
// ==============================================================================================================

inline float3 Irradiance_SphericalHarmonics(const float3 normal, const bool useL2, out Light outLight)
{
    float3 finalSH = 0;

    const float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w)
        + float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / 3.0;
    finalSH.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, normal);
    finalSH.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, normal);
    finalSH.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, normal);
    // Quadratic polynomials
    if (useL2) finalSH += SHEvalLinearL2(float4(normal, 1));

    // Light based on Light probes
    outLight.l = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
    outLight.worldPosition = 0;
    outLight.colorIntensity = 0;
    outLight.NdotL = saturate(dot(normal, outLight.l));
    outLight.distance = 100;
    outLight.attenuation = 1.;

    return finalSH;
}

#if UNITY_LIGHT_PROBE_PROXY_VOLUME

inline half3 Irradiance_SampleProbeVolume(half4 normal, float3 worldPos, out Light outLight)
{
    const float transformToLocal = unity_ProbeVolumeParams.y;
    const float texelSizeX = unity_ProbeVolumeParams.z;

    //The SH coefficients textures and probe occlusion are packed into 1 atlas.
    //-------------------------
    //| ShR | ShG | ShB | Occ |
    //-------------------------

    float3 position = (transformToLocal == 1.0f) ? mul(unity_ProbeVolumeWorldToObject, float4(worldPos, 1.0)).xyz : worldPos;
    float3 texCoord = (position - unity_ProbeVolumeMin.xyz) * unity_ProbeVolumeSizeInv.xyz;
    texCoord.x = texCoord.x * 0.25f;

    // We need to compute proper X coordinate to sample.
    // Clamp the coordinate otherwize we'll have leaking between RGB coefficients
    float texCoordX = clamp(texCoord.x, 0.5f * texelSizeX, 0.25f - 0.5f * texelSizeX);

    // sampler state comes from SHr (all SH textures share the same sampler)
    texCoord.x = texCoordX;
    half4 SHAr = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);

    texCoord.x = texCoordX + 0.25f;
    half4 SHAg = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);

    texCoord.x = texCoordX + 0.5f;
    half4 SHAb = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);

    // Linear + constant polynomial terms
    half3 x1;

    x1.r = shEvaluateDiffuseL1Geomerics_local(SHAr.w, SHAr.rgb, normal);
    x1.g = shEvaluateDiffuseL1Geomerics_local(SHAg.w, SHAg.rgb, normal);
    x1.b = shEvaluateDiffuseL1Geomerics_local(SHAb.w, SHAb.rgb, normal);

    // Light based on Light probes
    outLight.l = normalize(SHAr.rgb + SHAg.rgb + SHAb.rgb);
    outLight.worldPosition = 0;
    outLight.colorIntensity = 0;
    outLight.NdotL = saturate(dot(normal, outLight.l));
    outLight.distance = 100;
    outLight.attenuation = 1.;

    return x1;
}

#endif

inline float3 Irradiance_SphericalHarmonicsUnity(float3 normal, float3 ambient, float3 position, out Light outLight)
{
    half3 ambient_contrib = 0.0;

#if UNITY_SAMPLE_FULL_SH_PER_PIXEL
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
    if (unity_ProbeVolumeParams.x == 1.0)
        ambient_contrib = Irradiance_SampleProbeVolume(half4(normal, 1.0), position, outLight);
    else
        ambient_contrib = Irradiance_SphericalHarmonics(normal, true, outLight);
#else
    ambient_contrib = Irradiance_SphericalHarmonics(normal, true, outLight);
#endif

    ambient += max(half3(0, 0, 0), ambient_contrib);
#else
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
    if (unity_ProbeVolumeParams.x == 1.0)
        ambient_contrib = Irradiance_SampleProbeVolume(half4(normal, 1.0), position, outLight);
    else
        ambient_contrib = Irradiance_SphericalHarmonics(normal, false, outLight);
#else
    ambient_contrib = Irradiance_SphericalHarmonics(normal, false, outLight);
#endif

    ambient = max(half3(0, 0, 0), ambient + ambient_contrib);     // include L2 contribution in vertex shader before clamp.
#endif // UNITY_SAMPLE_FULL_SH_PER_PIXEL

#ifdef UNITY_COLORSPACE_GAMMA
    ambient = LinearToGammaSpace(ambient);
#endif

    outLight.colorIntensity = float4(ambient, 0);

    return ambient;
}

#endif // HEKKY_LIGHTING
