#ifndef HEKKY_PBR_UBER_SETUPS
#define HEKKY_PBR_UBER_SETUPS

#define MATERIAL_SETUP(x) MaterialData x = MaterialSetup(i);

MaterialData MaterialSetup(const v2f i)
{
    MaterialData data;

    float4 albedo = HEKKY_SAMPLE_TEX2D(_MainTex, i.uv.xy);
    data.baseColor = albedo.rgb * _Color;
    data.alpha = albedo.a * _Color.a;

    // Default tangent normal
    data.normal = UnpackScaleNormal(HEKKY_SAMPLE_TEX2D(_BumpMap, i.uv.xy), _BumpScale);

    // TODO: Fetch metalness, either from MetalTex.r or MetallicPackedTex[MetalChannel]
    // Probably should have some #define for sampling from either a normal texture or a packed texture
    data.metallic = _Metallic * HEKKY_SAMPLE_TEX2D(_MetallicGlossMap, i.uv.xy).r;
    data.roughness = _Glossiness * HEKKY_SAMPLE_TEX2D(_SpecGlossMap, i.uv.xy).r;
    data.roughness = (_InvertGlossiness - 1) * -data.roughness + _InvertGlossiness -_InvertGlossiness * data.roughness;
    data.reflectance = 0.5;

    // Specular

    // Aniso
    // TODO: Move to sampling
    // float4 anisoMap = HEKKY_SAMPLE_TEX2D(_AnisoMap, i.uv.xy);
    float4 anisoMap = SampleTexture2DEdgePreserving( TEXTURE2D_PARAM( _AnisoMap, sampler_AnisoMap ), i.uv.xy, _AnisoMap_TexelSize );
    
    data.aniso = anisoMap.r * _AnisoStrength;
    data.anisoAngle = anisoMap.g + _AnisoAngleOffset;

    // TODO: More props
    data.subsurface.color = (float3) 0;
    data.subsurface.thickness = 1.0;
    
    data.emission.color = _EmissionColor.rgb * HEKKY_SAMPLE_TEX2D(_EmissionMap, i.uv.xy);
    data.emission.intensity = _EmissionIntensity;

    #if defined(_AUDIOLINK)
    
    // AudioLink Emission
    const float al_EmissionMulBand = remap(0,1,_EmissionAudioLinkMultiplyRange.x,_EmissionAudioLinkMultiplyRange.y,getAudioLinkValue(_EmissionAudioLinkMultiplyChannel));
    const float al_EmissionAddBand = remap(0,1,_EmissionAudioLinkAddRange.x,_EmissionAudioLinkAddRange.y,getAudioLinkValue(_EmissionAudioLinkAddChannel));

    if (audioLinkEnabled())
    {
        data.emission.intensity = _EmissionIntensity * al_EmissionMulBand + al_EmissionAddBand;
    }
    
    #endif
    
    data.ambientOcclusion = Occlusion(i.uv.xy);

    return data;
}

#if !SHADOW_CASTER
#define INIT_SHADING_DATA(x) ShadingData x = SetupShadingData(i);

// Unpacking the world position
#if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
        #define IN_WORLDPOS(i) half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w)
    #else
        #define IN_WORLDPOS(i) i.posWorld
    #endif
    #define IN_WORLDPOS_FWDADD(i) i.posWorld
#else
    #define IN_WORLDPOS(i) half3(0,0,0)
    #define IN_WORLDPOS_FWDADD(i) half3(0,0,0)
#endif

ShadingData SetupShadingData(const v2f i)
{
    ShadingData shadingData = (ShadingData) 0;

    // Extract TBN matrix
    float3x3 tangentToWorld;
    tangentToWorld[0] = i.tangent.xyz;
    tangentToWorld[1] = i.binormal.xyz;
    tangentToWorld[2] = i.normal.xyz;
    shadingData.tangentToWorld = transpose(tangentToWorld);

    shadingData.normalizedViewportCoord = i.pos.xy * (0.5 / i.pos.w) + 0.5;
    shadingData.geometricNormal = normalize(i.normal.xyz);
    shadingData.normal = shadingData.geometricNormal;
    shadingData.geometricTangent = normalize(i.tangent.xyz);
    shadingData.tangent = shadingData.geometricTangent;
    shadingData.binormal = normalize(i.binormal.xyz);
    shadingData.position = i.worldPos;
    shadingData.view = -normalizePerPixelNormal(i.eyeVec);
    // shadingData.reflected = reflect(-shadingData.view, shadingData.normal);

    fixed atten = 1;
    
    UNITY_BRANCH
    if (LIGHTING_SHADOWS_ENABLED)
    {
        atten = UNITY_SHADOW_ATTENUATION(i, shadingData.position);
    }

    #if HAS_LIGHTMAP
    GetBakedAttenuation(atten, i.ambientOrLightmapUV.xy, shadingData.position);
    #endif
    
    shadingData.attenuation = atten;

    #if HAS_LIGHTMAP
        shadingData.ambient = 0;
        shadingData.lightmapUV = i.ambientOrLightmapUV;
    #else
        shadingData.ambient = i.ambientOrLightmapUV.rgb;
        shadingData.lightmapUV = 0;
    #endif

    UNITY_BRANCH
    if (_DoMatcap)
    {
        float2 matcapUV = getMatcapUV_ViewSpace(shadingData.position, shadingData.normal);
        matcapUV.x = remap( 0, 1, _MatcapBorder, 1.f - _MatcapBorder, matcapUV.x );
        matcapUV.y = remap( 0, 1, _MatcapBorder, 1.f - _MatcapBorder, matcapUV.y );
        shadingData.matcapColor = HEKKY_SAMPLE_TEX2D(_MatcapTex, matcapUV).rgb;
        
        shadingData.matcapBlend = HEKKY_SAMPLE_TEX2D(_MatcapMask, i.uv).r * _DoMatcap;
    }
    
    return shadingData;
}

// A collection of handy #defines to have "inline functions" for gathering data from texture maps
#define CALC_NORMAL(material, shading) normalize(mul(shading.tangentToWorld, material.normal))

void prepareMaterial(const MaterialData material, inout ShadingData shading)
{
    shading.normal = CALC_NORMAL(material, shading);

    UNITY_BRANCH
    if (_SpecularMode == 1 && abs(material.aniso) > 0.1)
    {
        // convert rotation to direction
        const float anisoAngleInRad = material.anisoAngle * 2 * PI;
        shading.tangent = rotate(shading.tangent, anisoAngleInRad, shading.normal);
        shading.binormal = normalize(cross(shading.normal, shading.tangent));
        shading.tangent = cross(shading.binormal, shading.normal);
    }
    shading.NdotV = saturate(dot(shading.normal, shading.view));
    shading.reflected = reflect(-shading.view, shading.normal);
}

#endif // SHADOW_CASTER

#endif // HEKKY_PBR_UBER_SETUPS