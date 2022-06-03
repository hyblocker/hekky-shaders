#ifndef HEKKY_PBR_UBER_AMBIENT_OCCLUSION
#define HEKKY_PBR_UBER_AMBIENT_OCCLUSION

inline float SpecularAO_Lagarde(const float NdotV, const float visibility, const float roughness) {
    // "Moving Frostbite to PBR" - Specular AO term
    // TODO: More physically based approach? If possible of course
    return saturate(pow(NdotV + visibility, exp2(-16.0 * roughness - 1.0)) - 1.0 + visibility);
}

inline float3 gtaoMultiBounce(float visibility, float3 term)
{
    // TODO: Multibounce AO
    return 0;
}

inline float singleBounceAO(const float visibility)
{
    return visibility;
}

inline float multiBounceAO(const float visibility, const float3 albedo)
{
    return visibility;
}

inline float multiBounceSpecularAO(const float visibility, const float3 f0)
{
    return visibility;
}

inline float computeSpecularAO(const float NdotV, const float AO, const float roughness)
{
    return SpecularAO_Lagarde(NdotV, AO, roughness);
}

inline float Occlusion(const float2 uv)
{
    const half occlusion = HEKKY_SAMPLE_TEX2D(_OcclusionMap, uv);
    return LerpOneTo(occlusion, _OcclusionStrength);
}

#endif // HEKKY_PBR_UBER_AMBIENT_OCCLUSION