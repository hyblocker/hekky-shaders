#ifndef HEKKY_PBR_UBER_AMBIENT_OCCLUSION
#define HEKKY_PBR_UBER_AMBIENT_OCCLUSION

inline float SpecularAO_Lagarde(const float NdotV, const float visibility, const float roughness) {
    // "Moving Frostbite to PBR" - Specular AO term
    // TODO: More physically based approach? If possible of course
    return saturate(pow(NdotV + visibility, exp2(-16.0 * roughness - 1.0)) - 1.0 + visibility);
}

inline float3 gtaoMultiBounce(float visibility, float3 term)
{
    // Jimenez et al. 2016, "Practical Realtime Strategies for Accurate Indirect Occlusion"
    const float3 a =  2.0404 * term - 0.3324;
    const float3 b = -4.7951 * term + 0.6417;
    const float3 c =  2.7552 * term + 0.6903;

    return max(visibility, ((visibility * a + b) * visibility + c) * visibility);
}

inline float singleBounceAO(const float visibility)
{
    return visibility;
}

inline float multiBounceAO(const float visibility, const float3 albedo)
{
    return gtaoMultiBounce(visibility, albedo);;
}

inline float multiBounceSpecularAO(const float visibility, const float3 f0)
{
    return gtaoMultiBounce(visibility, f0);;
}

inline float computeSpecularAO(const float NdotV, const float AO, const float roughness)
{
    return SpecularAO_Lagarde(NdotV, AO, roughness);
}

inline float Occlusion(const float2 uv, SamplerState samplerState)
{
    const half occlusion = HEKKY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, uv, samplerState);
    return LerpOneTo(occlusion, _OcclusionStrength);
}

inline float computeMicroShadowing(const float NdotL, const float visibility)
{
    // "Material Advances in Call of Duty: WWII"
    const float aperture = rsqrt(1.f - visibility);
    const float microShadow = saturate(NdotL * aperture);
    return microShadow * microShadow;
}

#endif // HEKKY_PBR_UBER_AMBIENT_OCCLUSION