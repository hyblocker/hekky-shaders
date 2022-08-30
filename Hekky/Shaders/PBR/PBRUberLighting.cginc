#ifndef HEKKY_PBR_UBER_LIGHTING_CORE
#define HEKKY_PBR_UBER_LIGHTING_CORE

#include "PBRUberLightingIndirect.cginc"
#include "PBRUberLightingDirectional.cginc"
#include "PBRUberLightingPunctual.cginc"

inline float computeDielectricF0(float reflectance)
{
    return 0.16 * reflectance * reflectance;
}

inline float3 computeF0(float3 baseColor, float metallic, float reflectance)
{
    return (baseColor.rgb * metallic) + (reflectance * (1.0 - metallic));
}

PixelParams getPixelParams(const ShadingData shading, const MaterialData material)
{
    PixelParams pixel;

    const float invMetallic = (1.0 - material.metallic);

    pixel.diffuseColor = material.baseColor * invMetallic;
    // Specular metallic reflections take away energy left for the diffuse component
    pixel.metallic = material.metallic;
    pixel.reflectance = material.reflectance;

    const float perceptualRoughness = normalFiltering(material.roughness, shading.geometricNormal);
    // minimum roughness, as 0 roughness breaks GGX 
    pixel.perceptualRoughness = max(perceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS);
    pixel.roughness = pixel.perceptualRoughness * pixel.perceptualRoughness;

    pixel.aniso = material.aniso;
    
    pixel.thickness = material.subsurface.thickness;
    pixel.subsurfaceColor = material.subsurface.color;
    pixel.subsurfaceIntensity = material.subsurface.intensity;

    const float reflectance = computeDielectricF0(material.reflectance);
    pixel.f0 = computeF0(material.baseColor, material.metallic, reflectance);
    pixel.dfg = prefilteredDFG(pixel.perceptualRoughness, shading.NdotV);
    // Multiple-Scattering Microfacet BSDFs with the Smith Model
    pixel.energyConservation = 1.0 + pixel.f0 * (1.0 / pixel.dfg.yyy - 1.0);

    return pixel;
}

float4 evaluateLights(const ShadingData shading, const MaterialData material)
{
    PixelParams pixel = getPixelParams(shading, material);
    float3 color = 0.0;

    #if FORWARD_BASE
    color.rgb += evaluateIBL(shading, material, pixel);
    #endif

    #if LIGHT_DIRECTIONAL
    color.rgb += evaluateDirectionalLight(shading, material, pixel);
    #endif

    #if LIGHT_DYNAMIC
    color.rgb += evaluatePunctualLights(shading, material, pixel);
    #endif

    // Apply matcap
    color = blendMatcap(color, shading.matcapColor, _MatcapMultiplyBlend * shading.matcapBlend, _MatcapAddBlend * shading.matcapBlend,
                        _MatcapDifferenceBlend * shading.matcapBlend, _MatcapReplaceBlend * shading.matcapBlend,
                        _MatcapOverlayBlend * shading.matcapBlend);

    return float4(color, material.alpha);
}


// Handles emissive materials
inline void addEmissive(const MaterialData material, inout float4 color)
{
    float3 emission = material.emission.color.rgb;
    const float emissionIntensity = material.emission.intensity;
    color.rgb += emission.rgb * emissionIntensity * color.a;
}

/*
 * Computes the surface color of a material
 * Returns a color in HDR color space
 */
inline float4 evaluateMaterial(const ShadingData shading, const MaterialData material)
{
    float4 color = evaluateLights(shading, material);
    addEmissive(material, color);
    return color;
}

#endif // HEKKY_PBR_UBER_LIGHTING_CORE
