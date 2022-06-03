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

inline float3 rotate (const float3 p, const float angle, const float3 N)
{
    float cosang, sinang;
    sincos (angle, sinang, cosang);
    const float cosang1 = 1.0 - cosang;

    const float3 N2 = N * N;

    // original is a 3x3 matrix cast into a 4x4, thus reduce the memory footprint
    float3x3 M = float3x3 (
        N2.x            + (1.0 - N2.x) * cosang,
        N2.y * cosang1  + N.z * sinang,
        N2.z * cosang1  - N.y * sinang,

        N2.y * cosang1  - N.z * sinang,
        N2.y            + (1.0 - N2.y) * cosang,
        N2.z * cosang1  + N.x * sinang,

        N2.z * cosang1  + N.y * sinang,
        N2.z * cosang1  - N.x * sinang,
        N2.z            + (1.0 - N2.z) * cosang);
    return mul (M, p);
}

// ABOVE IS OPTIMIZED FORM OF THIS
/*

inline float3 rotate (float3 p, float angle, float3 b)
{
    const float3 a = float3(0,0,0);
    float3 axis = normalize (b - a);
    float cosang, sinang;
    sincos (angle, sinang, cosang);
    float cosang1 = 1.0 - cosang;
    float x = axis[0], y = axis[1], z = axis[2];
    
    float4x4 M = float4x4 ( x * x + (1.0 - x * x) * cosang,
                            x * y * cosang1 + z * sinang,
                            x * z * cosang1 - y * sinang,
                            0.0,
                            x * y * cosang1 - z * sinang,
                            y * y + (1.0 - y * y) * cosang,
                            y * z * cosang1 + x * sinang,
                            0.0,
                            x * z * cosang1 + y * sinang,
                            y * z * cosang1 - x * sinang,
                            z * z + (1.0 - z * z) * cosang,
                            0.0,
                            0.0, 0.0, 0.0, 1.0);
    return mul (M, p-a) + a;
}
*/

#endif // HEKKY_PBR_UBER_UTILS