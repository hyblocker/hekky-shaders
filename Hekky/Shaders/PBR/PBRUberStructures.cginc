#ifndef HEKKY_PBR_UBER_STRUCTS
#define HEKKY_PBR_UBER_STRUCTS

// ====================================================================
//                          PIXEL PARAM DATA
// ====================================================================

struct PixelParams
{
    // PBR Principles
    float3 f0;
    float2 dfg;
    float energyConservation;
    
    // Props
    float3 diffuseColor;
    float perceptualRoughness;
    float roughness;
    float metallic;
    float reflectance;
    
    // SSS
    float thickness;
    float3 subsurfaceColor;
    float subsurfaceIntensity;

    float aniso;
};

// Data required for light composition
struct ShadingData
{
    float3x3 tangentToWorld;    // TBN Matrix
    float3 position;            // World pos
    float3 normal;              // Normal, affected by normal map if available
    float3 tangent;             // Tangent, affected by normal map if available
    float3 binormal;            // Binormal, affected by normal map if available
    float3 geometricNormal;     // Normal
    float3 geometricTangent;    // Tangent
    float3 view;                // View Direction
    float viewDistance;         // Distance between camera and surface
    float3 reflected;           // Reflected Direction
    float NdotV;                // N dot V

    float2 normalizedViewportCoord; // For grab pass stuff

    // Unity params
    float4 lightmapUV;
    float3 ambient;
    float attenuation;
    
    float3 matcapColor;
    float matcapBlend;
};

// ====================================================================
//                             MATERIAL DATA
// ====================================================================


// Emission data
struct EmissionData
{
    float3 color;
    float intensity;
};

// Subsurface scattering data
// Probably going to have to make this use some light scattering phenomena to be physically accurate
struct SubsurfaceData
{
    float3 color;
    float thickness;
    float intensity;
};

// Textures sampled and interpolated for the BRDF composition step
struct MaterialData
{
    float3 baseColor;
    float alpha;
    float metallic;
    float roughness;
    float reflectance;
    float ambientOcclusion;
    half3 normal;      // Tangent space normal
    half3 tangent;     // Tangent map
    float aniso;        // Anisotropy
    float anisoAngle;   // Anisotropic Angle
    SubsurfaceData subsurface;
    EmissionData emission;
};

#endif // HEKKY_PBR_UBER_STRUCTS