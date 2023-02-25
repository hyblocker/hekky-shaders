#ifndef HEKKY_PBR_UBER_SETUPS

#define HEKKY_PBR_UBER_SETUPS

#define MATERIAL_SETUP(x, s) MaterialData x = MaterialSetup(i, s);

MaterialData MaterialSetup(const v2f i, const ShadingData shadingData)
{
    MaterialData data;

    float2 inputUV = handlePom(i.uv.xy, shadingData);

    float4 albedo = HEKKY_SAMPLE_TEX2D(_MainTex, inputUV);
    data.baseColor = albedo.rgb * _Color * 0.8039216f;
    data.alpha = albedo.a * _Color.a;

    // Default tangent normal
    #ifdef _NORMALMAP
    data.normal = UnpackScaleNormal(HEKKY_SAMPLE_TEX2D_SAMPLER(_BumpMap, inputUV, sampler_MainTex), _BumpScale);
    #else
        data.normal = half3(0,0, _BumpScale);
    #endif

    // TODO: Fetch metalness, either from MetalTex.r or MetallicPackedTex[MetalChannel]
    // Probably should have some #define for sampling from either a normal texture or a packed texture
    data.metallic = _Metallic * HEKKY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, inputUV, sampler_MainTex).r;
    data.roughness = _Glossiness * HEKKY_SAMPLE_TEX2D_SAMPLER(_SpecGlossMap, inputUV, sampler_MainTex).r;
    data.roughness = (_InvertGlossiness - 1) * -data.roughness + _InvertGlossiness -_InvertGlossiness * data.roughness;
    data.reflectance = 0.5;

    // Specular

    // Aniso
    // TODO: Move to sampling
    // float4 anisoMap = HEKKY_SAMPLE_TEX2D(_AnisoMap, inputUV);
    float4 anisoMap = SampleTexture2DEdgePreserving( TEXTURE2D_PARAM( _AnisoMap, sampler_MainTex ), inputUV, _AnisoMap_TexelSize );
    
    data.aniso = anisoMap.r * _AnisoStrength;
    data.anisoAngle = anisoMap.g + _AnisoAngleOffset;

    data.subsurface = (SubsurfaceData)0;
    
    #if SUBSURFACE_SCATTERING

    data.subsurface.color = _SSSColor;
    data.subsurface.thickness = HEKKY_SAMPLE_TEX2D_SAMPLER(_SSSMap, inputUV, sampler_MainTex).r * _SSSVisibility;
    data.subsurface.intensity = _SSSIntensity;

    #endif
    
    data.emission.color = _EmissionColor.rgb * HEKKY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, inputUV, sampler_MainTex);
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
    
    data.ambientOcclusion = Occlusion(inputUV, sampler_MainTex);

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

    shadingData.geometricTangent        = i.tangentToWorldAndPackedData[0].xyz;
    shadingData.binormal                = i.tangentToWorldAndPackedData[1].xyz;
    shadingData.geometricNormal         = i.tangentToWorldAndPackedData[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        // Taken from unity standard shader, this excerpt is licensed under MIT
        shadingData.geometricNormal = NormalizePerPixelNormal(shadingData.geometricNormal);

        // ortho-normalize Tangent
        tangent = normalize (shadingData.geometricTangent - shadingData.geometricNormal * dot(shadingData.geometricTangent, shadingData.geometricNormal));

        // recalculate Binormal
        half3 newB = cross(shadingData.geometricNormal, shadingData.geometricTangent);
        shadingData.binormal = newB * sign (dot (newB, shadingData.binormal));
    #endif
    
    // Extract TBN matrix
    float3x3 tangentToWorld;
    tangentToWorld[0] = shadingData.geometricTangent;
    tangentToWorld[1] = shadingData.binormal;
    tangentToWorld[2] = shadingData.geometricNormal;
    shadingData.tangentToWorld = transpose(tangentToWorld);

    shadingData.normalizedViewportCoord = i.pos.xy * (0.5 / i.pos.w) + 0.5;
    shadingData.normal = shadingData.geometricNormal;
    shadingData.tangent = shadingData.geometricTangent;
    shadingData.position = float3(i.tangentToWorldAndPackedData[0].w, i.tangentToWorldAndPackedData[1].w, i.tangentToWorldAndPackedData[2].w);
    shadingData.view = -normalize(i.eyeVec);
    shadingData.viewDistance = length(i.eyeVec);
    // shadingData.reflected = reflect(-shadingData.view, shadingData.normal);

    fixed atten  = UNITY_SHADOW_ATTENUATION(i, shadingData.position);
    // Fix screen space shadow artifacts from MSAA
    #if defined(SHADOWS_SCREEN) && defined(UNITY_PASS_FORWARDBASE)
        atten = SSDirectionalShadowAA(i._ShadowCoord, atten);
    #endif
    // if (LIGHTING_SHADOWS_ENABLED == 0) atten = 1.f;
    atten = LIGHTING_SHADOWS_ENABLED * atten + (1.f - LIGHTING_SHADOWS_ENABLED);

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
        shadingData.matcapColor = HEKKY_SAMPLE_TEX2D(_MatcapTex, matcapUV).rgb * _MatcapColor;
        
        shadingData.matcapBlend = HEKKY_SAMPLE_TEX2D_SAMPLER(_MatcapMask, i.uv, sampler_MatcapTex).r * _DoMatcap;
    }
    
    return shadingData;
}

void prepareMaterial(const MaterialData material, inout ShadingData shading, const bool isFrontFace)
{
    float normalSign = isFrontFace ? 1 : -1;
    shading.normal = normalize(mul(shading.tangentToWorld, material.normal));
    shading.normal *= normalSign;

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