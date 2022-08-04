#ifndef HEKKY_PBR_UBER_UTILS
#define HEKKY_PBR_UBER_UTILS

// GSAA
inline float normalFiltering(float perceptualRoughness, const float3 worldNormal) {
    // Kaplanyan 2016, "Stable specular highlights"
    // Tokuyoshi 2017, "Error Reduction and Simplification for Shading Anti-Aliasing"
    // Tokuyoshi and Kaplanyan 2019, "Improved Geometric Specular Antialiasing"

    // This implementation is meant for deferred rendering in the original paper but
    // we use it in forward rendering as well (as discussed in Tokuyoshi and Kaplanyan
    // 2019). The main reason is that the forward version requires an expensive transform
    // of the half vector by the tangent frame for every light. This is therefore an
    // approximation but it works well enough for our needs and provides an improvement
    // over our original implementation based on Vlachos 2015, "Advanced VR Rendering".


    // TODO: Expose params
    float _specularAntiAliasingVariance = 0.15;
    float _specularAntiAliasingThreshold = 0.25;
    
    float3 du = ddx(worldNormal);
    float3 dv = ddy(worldNormal);

    float variance = _specularAntiAliasingVariance * (dot(du, du) + dot(dv, dv));

    // float roughness = perceptualRoughnessToRoughness(perceptualRoughness);
    float roughness = perceptualRoughness * perceptualRoughness;
    float kernelRoughness = min(2.0 * variance, _specularAntiAliasingThreshold);
    float squareRoughness = saturate(roughness * roughness + kernelRoughness);

    return sqrt(sqrt(squareRoughness));
    // return roughnessToPerceptualRoughness(sqrt(squareRoughness));
}

#endif // HEKKY_PBR_UBER_UTILS