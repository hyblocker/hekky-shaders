#ifndef HEKKY_PBR_UBER_LIGHTING_INDIRECT
#define HEKKY_PBR_UBER_LIGHTING_INDIRECT

#include "PBRUberLightingLTCGI.cginc"

// Unity Baked Lighting stuff

// =====================================================
//                         UTILS
// =====================================================
inline float3 getReflectedVector(const ShadingData shading, const PixelParams pixel)
{
    float3 r;
    // Anisotropy
    UNITY_BRANCH
    // 1 == ANISOTROPIC
    if (_SpecularMode == 1 && pixel.aniso > 0.01) {
        const float3 anisotropicDirection = pixel.aniso >= 0.0 ? shading.binormal : shading.tangent;
        const float3 anisotropicTangent = cross(anisotropicDirection, shading.view);
        const float3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
        const float3 bentNormal = normalize(lerp(shading.normal, anisotropicNormal, pixel.aniso));
        r = reflect(-shading.view, bentNormal);
    } else {
        r = shading.reflected;
    }
    return lerp(r, shading.normal, pixel.roughness * pixel.roughness);
}

// =====================================================
//                          DFG
// =====================================================
inline float3 PrefilteredDFG_LUT(const float lod, const float NdotV)
{
    return HEKKY_SAMPLE_TEX2D(_DFG, float2(NdotV, lod));
}

inline float2 prefilteredDFG(const float perceptualRoughness, const float NdotV)
{
    return PrefilteredDFG_LUT(perceptualRoughness, NdotV).xy;
}

inline float3 specularDFG(const PixelParams pixel)
{
    return lerp(pixel.dfg.xxx, pixel.dfg.yyy, pixel.f0);
}

// =======================================================================================
//                                LIGHT SPECULAR SAMPLING
// =======================================================================================
inline float3 DecodeDirectionalLightmapSpecular(half3 color, half4 dirTex, half3 normalWorld, out Light derivedLight)
{
    derivedLight = (Light) 0;
    derivedLight.colorIntensity = float4(color, 1.f);
    derivedLight.l = dirTex.xyz * 2.f - 1.f;

    // the length of the light direction represents the light's 'directionality'.
    // this means 1 for all light coming from this direction, and lower values as the light becomes more "ambient"
    half directionality = max(0.001f, length(derivedLight.l));
    derivedLight.l /= directionality;

    half3 ambient = derivedLight.colorIntensity * (1.f - directionality);
    derivedLight.colorIntensity *= directionality;
    derivedLight.attenuation = directionality;
    
    derivedLight.NdotL = saturate(dot(normalWorld, derivedLight.l));
    
    return ambient;
}

// =======================================================================================
//                                          BAKERY
// =======================================================================================

#if BAKERY_ENABLED
// Adapted from Bakery.cginc
inline float3 DecodeRNMLightmap(half3 color, half2 lightmapUV, half3 normalTangent, float3x3 tangentToWorld, float3 normal,
    out Light derivedLight)
{
    // From Bakery shaders
    const float3 rnmBasis0 = float3(0.816496580927726f, 0, 0.5773502691896258f);
    const float3 rnmBasis1 = float3(-0.4082482904638631f, 0.7071067811865475f, 0.5773502691896258f);
    const float3 rnmBasis2 = float3(-0.4082482904638631f, -0.7071067811865475f, 0.5773502691896258f);

    float3 irradiance;
    derivedLight = (Light)0;

    #ifdef SHADER_API_D3D11
        float width, height;
        _RNM0.GetDimensions(width, height);
        const float4 rnm_TexelSize = float4(width, height, 1.0 / width, 1.0 / height);
    
        float3 rnm0 = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM(_RNM0, sampler_RNM0 ), lightmapUV, rnm_TexelSize ));
        float3 rnm1 = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM(_RNM1, sampler_RNM0 ), lightmapUV, rnm_TexelSize ));
        float3 rnm2 = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM(_RNM2, sampler_RNM0 ), lightmapUV, rnm_TexelSize ));
    #else
        float3 rnm0 = DecodeLightmap( HEKKY_SAMPLE_TEX2D_SAMPLER( _RNM0, sampler_RNM0, lightmapUV ));
        float3 rnm1 = DecodeLightmap( HEKKY_SAMPLE_TEX2D_SAMPLER( _RNM1, sampler_RNM0, lightmapUV ));
        float3 rnm2 = DecodeLightmap( HEKKY_SAMPLE_TEX2D_SAMPLER( _RNM2, sampler_RNM0, lightmapUV ));
    #endif

    normalTangent.g *= -1;

    irradiance =  saturate(dot(rnmBasis0, normalTangent)) * rnm0
                + saturate(dot(rnmBasis1, normalTangent)) * rnm1
                + saturate(dot(rnmBasis2, normalTangent)) * rnm2;

    // Specular
    UNITY_BRANCH
    if (BAKED_SPECULAR_ENABLED)
    {
        float3 dominantDirT = rnmBasis0 * luminosity(rnm0) +
                              rnmBasis1 * luminosity(rnm1) +
                              rnmBasis2 * luminosity(rnm2);

        float3 dominantDirTN = normalize(dominantDirT);
        float3 specColor = saturate(dot(rnmBasis0, dominantDirTN)) * rnm0 +
                           saturate(dot(rnmBasis1, dominantDirTN)) * rnm1 +
                           saturate(dot(rnmBasis2, dominantDirTN)) * rnm2;

        // the length of the light direction represents the light's 'directonality'.
        // this means 1 for all light coming from this direction, and lower values as the light becomes more "ambient"
        derivedLight.l = normalize(mul(tangentToWorld, dominantDirT));
        half directionality = max(0.001, length(derivedLight.l));
        derivedLight.l /= directionality;

        derivedLight.colorIntensity = float4(specColor * directionality, 1.f);
        derivedLight.attenuation = directionality;
        derivedLight.NdotL = saturate(dot(normal, derivedLight.l));
    }
    
    return irradiance;
}

inline half3 DecodeSHLightmap(half3 L0, half2 lightmapUV, half3 normal, out Light derivedLight)
{
    float3 irradiance;
    derivedLight = (Light)0;

    #ifdef SHADER_API_D3D11
        float width, height;
        _RNM0.GetDimensions(width, height);
        const float4 rnm_TexelSize = float4( width, height, 1.0 / width, 1.0 / height );
    
        float3 nL1x = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM( _RNM0, sampler_RNM0 ), lightmapUV, rnm_TexelSize )) * 2 - 1;
        float3 nL1y = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM( _RNM1, sampler_RNM0 ), lightmapUV, rnm_TexelSize )) * 2 - 1;
        float3 nL1z = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM( _RNM2, sampler_RNM0 ), lightmapUV, rnm_TexelSize )) * 2 - 1;
    #else
        float3 nL1x = DecodeLightmap( HEKKY_SAMPLE_TEX2D_SAMPLER( _RNM0, sampler_RNM0, lightmapUV )) * 2 - 1;
        float3 nL1y = DecodeLightmap( HEKKY_SAMPLE_TEX2D_SAMPLER( _RNM1, sampler_RNM0, lightmapUV )) * 2 - 1;
        float3 nL1z = DecodeLightmap( HEKKY_SAMPLE_TEX2D_SAMPLER( _RNM2, sampler_RNM0, lightmapUV )) * 2 - 1;
    #endif
    
    float3 L1x = nL1x * L0 * 2;
    float3 L1y = nL1y * L0 * 2;
    float3 L1z = nL1z * L0 * 2;
    
    #if BAKERY_SHNONLINEAR
        float lumaL0 = dot(L0, 1);
        float lumaL1x = dot(L1x, 1);
        float lumaL1y = dot(L1y, 1);
        float lumaL1z = dot(L1z, 1);
        float lumaSH = shEvaluateDiffuseL1Geomerics_local(lumaL0, float3(lumaL1x, lumaL1y, lumaL1z), normal);

        irradiance = L0 + normal.x * L1x + normal.y * L1y + normal.z * L1z;
        float regularLumaSH = dot(sh, 1);
        irradiance *= lerp(1, lumaSH / regularLumaSH, saturate(regularLumaSH*16));
    #else
        irradiance = L0 + normal.x * L1x + normal.y * L1y + normal.z * L1z;
    #endif

    // Specular
    UNITY_BRANCH
    if (BAKED_SPECULAR_ENABLED)
    {
        float3 dominantDir = float3(luminosity(nL1x), luminosity(nL1y), luminosity(nL1z));

        // the length of the light direction represents the light's 'directonality'.
        // this means 1 for all light coming from this direction, and lower values as the light becomes more "ambient"
        derivedLight.l = dominantDir;
        half directionality = max(0.001, length(derivedLight.l));
        derivedLight.l /= directionality;

        derivedLight.colorIntensity = float4(irradiance * directionality, 1.f);
        derivedLight.attenuation = directionality;
        derivedLight.NdotL = saturate(dot(normal, derivedLight.l));
    }
    
    return irradiance;
}

inline half3 DecodeMonoSHLightmap(half3 L0, half3 dominantDir, half2 lightmapUV, half3 normal, out Light derivedLight)
{
    float3 irradiance;
    derivedLight = (Light)0;

    // float3 dominantDir = bakedDirTex;
    
    // #ifdef SHADER_API_D3D11
    //     float width, height;
    //     unity_Lightmap.GetDimensions(width, height);
    //     const float4 unity_Lightmap_TexelSize = float4( width, height, 1.0 / width, 1.0 / height );
    // 
    //     float3 dominantDir = SampleTexture2DBicubicFilter( TEXTURE2D_PARAM(unity_LightmapInd, samplerunity_Lightmap), lightmapUV, unity_Lightmap_TexelSize ).xyz;
    //     float3 L0 = DecodeLightmap( SampleTexture2DBicubicFilter( TEXTURE2D_PARAM( unity_Lightmap, samplerunity_Lightmap), lightmapUV, unity_Lightmap_TexelSize ) );
    // #else
    //     float3 dominantDir = HEKKY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, lightmapUV, samplerunity_Lightmap).xyz;
    //     float3 L0 = DecodeLightmap(HEKKY_SAMPLE_TEX2D_SAMPLER(unity_Lightmap, lightmapUV, samplerunity_Lightmap));
    // #endif

    float3 nL1 = dominantDir * 2 - 1;
    float3 L1x = nL1.x * L0 * 2;
    float3 L1y = nL1.y * L0 * 2;
    float3 L1z = nL1.z * L0 * 2;
    
    #if BAKERY_SHNONLINEAR
        float lumaL0 = dot(L0, 1);
        float lumaL1x = dot(L1x, 1);
        float lumaL1y = dot(L1y, 1);
        float lumaL1z = dot(L1z, 1);
        float lumaSH = shEvaluateDiffuseL1Geomerics_local(lumaL0, float3(lumaL1x, lumaL1y, lumaL1z), normal);

        irradiance = L0 + normal.x * L1x + normal.y * L1y + normal.z * L1z;
        float regularLumaSH = dot(irradiance, 1);
        irradiance *= lerp(1, lumaSH / regularLumaSH, saturate(regularLumaSH*16));
    #else
        irradiance = L0 + normal.x * L1x + normal.y * L1y + normal.z * L1z;
    #endif

    // Specular
    UNITY_BRANCH
    if (BAKED_SPECULAR_ENABLED)
    {
        // the length of the light direction represents the light's 'directionality'.
        // this means 1 for all light coming from this direction, and lower values as the light becomes more "ambient"
        derivedLight.l = nL1;
        half directionality = max(0.001, length(derivedLight.l));
        derivedLight.l /= directionality;

        derivedLight.colorIntensity = float4(irradiance * directionality, 1.f);
        derivedLight.attenuation = directionality;
        derivedLight.NdotL = saturate(dot(normal, derivedLight.l));
    }

    return irradiance;
}
#endif

// ==============================================================================================================
//                                               IRRIDIANCE LIGHTMAPS 
// ==============================================================================================================

inline half getExposureOcclusionBias()
{
    return 1.0 / (_ExposureOcclusion);
}

inline float IrradianceToExposureOcclusion(float3 irradiance)
{
    return saturate(length(irradiance + EPSILON) * getExposureOcclusionBias());
}

// Returns light probes or lightmap
inline float3 UnityGI_Irradiance(const ShadingData shading, const float3 tangentNormal, out float occlusion,
                          out Light derivedLight)
{
    float3 irradiance = shading.ambient;
    float3 AOIrradiance;
    occlusion = 1.0;
    derivedLight = (Light)0;

    // Light probes
    #if UNITY_SHOULD_SAMPLE_SH
        irradiance = Irradiance_SphericalHarmonicsUnity(shading.normal, shading.ambient, shading.position, derivedLight);
    #endif

    AOIrradiance = irradiance;

    #if SAMPLE_LIGHTMAP

        // Baked lightmaps
        half4 bakedColorTex = SampleLightmapBicubic(shading.lightmapUV.xy);
        half3 bakedColor = DecodeLightmap(bakedColorTex);

        #if defined(DIRLIGHTMAP_COMBINED)

            fixed4 bakedDirTex = SampleLightmapDirBicubic (shading.lightmapUV.xy);
            #if BAKERY_ENABLED && defined(_BAKERY_MONOSH)
                irradiance += DecodeMonoSHLightmap (bakedColor, bakedDirTex, shading.lightmapUV.xy, shading.normal, derivedLight);
                AOIrradiance = irradiance;
            #else
                irradiance += DecodeDirectionalLightmap (bakedColor, bakedDirTex, shading.normal);
                AOIrradiance = irradiance;

                UNITY_BRANCH
                if (BAKED_SPECULAR_ENABLED)
                {
                    irradiance = DecodeDirectionalLightmapSpecular(bakedColor, bakedDirTex, shading.normal, derivedLight);
                }
            #endif
            
        #else
            // Not a directional lightmap

            // Special case: Bakery RNM and SH lightmaps, for increased visual fidelity
            #if BAKERY_ENABLED
                #if defined(_BAKERY_RNM)
                    irradiance = DecodeRNMLightmap(bakedColor, shading.lightmapUV.xy, tangentNormal, shading.tangentToWorld, shading.normal, derivedLight);
                #endif
                
                #if defined(_BAKERY_SH)
                    irradiance = DecodeSHLightmap(bakedColor, shading.lightmapUV.xy, shading.normal, derivedLight);
                #endif

                AOIrradiance = irradiance;
            #else
                irradiance += bakedColor;
                AOIrradiance = irradiance;
            #endif
    
        #endif

        // Shadow mixing
        #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
            irradiance = SubtractMainLightWithRealtimeAttenuationFromLightmap(irradiance, shading.attenuation, bakedColorTex, shading.normal);
        #endif
    #endif

    #if SAMPLE_DYNAMICLIGHTMAP

        // Dynamic lightmaps
        half4 realtimeColorTex = SampleDynamicLightmapBicubic(shading.lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap(realtimeColorTex);

        AOIrradiance += realtimeColor;

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = SampleDynamicLightmapDirBicubic(shading.lightmapUV.zw);
            irradiance += DecodeDirectionalLightmap(realtimeColor, realtimeDirTex, shading.normal);
        #else
            irradiance += realtimeColor;
        #endif

    #endif

    occlusion = IrradianceToExposureOcclusion(AOIrradiance);

    return irradiance;
}

// =======================================================================================
//                                      REFLECTIONS
// =======================================================================================

inline half3 Unity_GlossyEnvironment_local(UNITY_ARGS_TEXCUBE(tex), half4 hdr, Unity_GlossyEnvironmentData glossIn)
{
    half perceptualRoughness = glossIn.roughness;

    float roughnessAdjustment = 1 - perceptualRoughness;
    roughnessAdjustment = 0.045 * roughnessAdjustment * roughnessAdjustment;
    perceptualRoughness = perceptualRoughness - roughnessAdjustment;

    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    const half mip = perceptualRoughnessToMipmapLevel(perceptualRoughness);
    const half3 R = glossIn.reflUVW;
    const half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, R, mip);

    return DecodeHDR(rgbm, hdr);
}

inline half3 UnityGI_prefilteredRadiance(const UnityGIInput giData, const float perceptualRoughness, const float3 reflectionDir, const ShadingData shading)
{
    half3 specular;

    Unity_GlossyEnvironmentData glossIn = (Unity_GlossyEnvironmentData)0;
    glossIn.roughness = perceptualRoughness;
    glossIn.reflUVW = reflectionDir;

    float4 SSRColor = float4(0,0,0,0);
    #if SSR
        SSRData ssrData         = (SSRData)0;
        ssrData.worldPos        = giData.worldPos;
        ssrData.viewDir         = giData.worldViewDir;
        ssrData.reflectDir      = reflectionDir;
        ssrData.surfaceNormal   = shading.normal;
        ssrData.roughness       = perceptualRoughness;
        ssrData.screenParams    = _GrabTexture_TexelSize.zw;
        ssrData.hitRadius       = _SSRAccuracy;
        ssrData.maxSteps        = _SSRMaxSteps;
        ssrData.blur            = _SSRBlur;
        ssrData.edgeFade        = _SSREdgeFade;
        SSRColor = computeSSRColor(ssrData);
    #endif

    #if (defined(UNITY_SPECCUBE_BOX_PROJECTION) && defined(_REFLECTIONSFORCEDMODE_DEFAULT)) || defined(_REFLECTIONSFORCEDMODE_BOX_PROJECTION)
        // we will tweak reflUVW in glossIn directly (as we pass it to Unity_GlossyEnvironment twice for probe0 and probe1), so keep original to pass into BoxProjectedCubemapDirection
        const half3 originalReflUVW = glossIn.reflUVW;
        glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, giData.worldPos, giData.probePosition[0], giData.boxMin[0], giData.boxMax[0]);
    #endif

    const half3 env0 = Unity_GlossyEnvironment_local(UNITY_PASS_TEXCUBE(unity_SpecCube0), giData.probeHDR[0], glossIn);

    #ifdef UNITY_SPECCUBE_BLENDING
        const float kBlendFactor = 0.99999;
        const float blendLerp = giData.boxMin[0].w;
        UNITY_BRANCH
        if (blendLerp < kBlendFactor)
        {
            #if (defined(UNITY_SPECCUBE_BOX_PROJECTION) && defined(_REFLECTIONSFORCEDMODE_DEFAULT)) || defined(_REFLECTIONSFORCEDMODE_BOX_PROJECTION)
                glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, giData.worldPos, giData.probePosition[1], giData.boxMin[1], giData.boxMax[1]);
            #endif

            const half3 env1 = Unity_GlossyEnvironment_local (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), giData.probeHDR[1], glossIn);
            specular = lerp(env1, env0, blendLerp);
        }
        else
        {
            specular = env0;
        }
    #else // No reflection probe blending
        specular = env0;
    #endif

    // "alpha-blend" the SSR colour and the reflection probe colour together, so that areas with no information for SSR still have
    // convincing reflections
    specular = lerp(specular, SSRColor.rgb, min(1, SSRColor.a * 4.f));
    return lerp(specular, shading.matcapColor, _MatcapReflectionBlend * _DoMatcap);
}

inline UnityGIInput InitialiseUnityGIInput(const ShadingData shading, const PixelParams pixel)
{
    UnityGIInput d;
    d.worldPos = shading.position;
    d.worldViewDir = -shading.view;
    d.probeHDR[0] = unity_SpecCube0_HDR;
    d.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
        d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        d.boxMax[0] = unity_SpecCube0_BoxMax;
        d.probePosition[0] = unity_SpecCube0_ProbePosition;
        d.boxMax[1] = unity_SpecCube1_BoxMax;
        d.boxMin[1] = unity_SpecCube1_BoxMin;
        d.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif
    return d;
}

// IBL Evaluation

float3 evaluateIBL(const ShadingData shading, const MaterialData material, const PixelParams pixel)
{
    const float ssao = 1.0; // TODO: Impl SSAO
    float lightmapAO = 1.0; // TODO: Expose as a param?
    Light derivedLight = (Light)0;
    const float3 tangentNormal = float3(0, 0, 1);

    // Gather Unity GI data
    const UnityGIInput unityData = InitialiseUnityGIInput(shading, pixel);
    const float3 unityIrradiance = UnityGI_Irradiance(shading, tangentNormal, lightmapAO, derivedLight);

    float diffuseAO = min(material.ambientOcclusion, ssao);
    float specularAO = computeSpecularAO(shading.NdotV, diffuseAO * lightmapAO, pixel.roughness);

    float3 Fr;
    float3 specularEnergyConpensation = specularDFG(pixel);
    float3 r = getReflectedVector(shading, pixel);
    Fr = specularEnergyConpensation * UnityGI_prefilteredRadiance(unityData, pixel.perceptualRoughness, r, shading);

    #if LTCGI_ENABLED

    // Eval LTCGI
    float3 ltcgiDiffuse = 0;
    float3 ltcgiSpecular = 0;
    float ltcgiSpecularIntensity = 0;

    LTCGI_Contribution(
        /* in */ shading.position / _LTCGI_Scale.xyz, 
        /* in */ shading.normal, 
        /* in */ shading.view, 
        /* in */ pixel.perceptualRoughness, 
        /* in */ (shading.lightmapUV.xy - unity_LightmapST.zw) / unity_LightmapST.xy,

        /* out */ ltcgiDiffuse,
        /* out */ ltcgiSpecular,
        /* out */ ltcgiSpecularIntensity
    );

    // Mix LTCGI spec in
    Fr = lerp(Fr, specularEnergyConpensation * ltcgiSpecular * max(_LTCGI_Intensity.y, 0.01), saturate(ltcgiSpecularIntensity));
    
    #endif
    
    Fr *= singleBounceAO(specularAO) * pixel.energyConservation * _BakedSpecularTint;

    float3 diffuseIrridiance = unityIrradiance;

    UNITY_BRANCH
    if (LIGHTING_MODE_TOON) {
        // hack to preserve high luminosity
        float originalLumExtra = max(0.0, luminosity(diffuseIrridiance) - (_ToonMathGradientBrightness.y - _ToonMathGradientBrightness.x));
        float steppedIrridiance = smoothstep(0, 0.01, diffuseIrridiance);
        diffuseIrridiance = lerp (
            max(_ToonMathGradientBrightness.x, 0.05) * steppedIrridiance,
            max(_ToonMathGradientBrightness.y, 1.0) * steppedIrridiance,
            toonify(diffuseIrridiance, _ToonMathGradientDiffuse) )
        + originalLumExtra;
    }
    #if LTCGI_ENABLED
    diffuseIrridiance += ltcgiDiffuse * _LTCGI_Intensity.x;
    #endif

    float diffuseBRDF = singleBounceAO(diffuseAO);

    float3 Fd = pixel.diffuseColor * diffuseIrridiance * (1 - specularEnergyConpensation) * (diffuseBRDF);

    float3 color = Fd + Fr;

    UNITY_BRANCH
    if (_LightmapSpecular == 1)
    {
        PixelParams pixelForBakedSpecular = pixel;

        pixelForBakedSpecular.roughness = remap(0,1,
            1.f - min(_LightmapSpecularMaxSmoothness * 0.9f, 1.f),
            saturate(1.f - min(_LightmapSpecularMaxSmoothness * 0.9f, 1.f) + MIN_ROUGHNESS),
            pixelForBakedSpecular.roughness);

        if (any(derivedLight.NdotL))
        {
            color += surfaceShading(shading, pixelForBakedSpecular, derivedLight, 
                                    computeMicroShadowing(derivedLight.NdotL, material.ambientOcclusion * min(diffuseAO, specularAO))
            );
        }
    }

    return color;
}

#endif // HEKKY_PBR_UBER_LIGHTING_INDIRECT
