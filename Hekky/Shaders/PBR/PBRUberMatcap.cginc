#ifndef HEKKY_PBR_UBER_MATCAPS
#define HEKKY_PBR_UBER_MATCAPS

inline float2 getMatcapUV_ViewSpace(const float3 worldPos, const float3 normal)
{
    const float3 worldSpaceViewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
    float3 up = mul((float3x3)UNITY_MATRIX_I_V, float3(0, 1, 0));
    const float3 right = normalize(cross(up, worldSpaceViewDir));
    up = cross(worldSpaceViewDir, right); // ensure orthogonal
    const float2 matcapUV = mul(float3x3(right, up, worldSpaceViewDir), normal).xy;

    // remap to 0 - 1 space
    return matcapUV * 0.5 + 0.5;
}

inline float3 blendMatcap(float3 sourceColor, const float3 matcapColor, const float multiply, const float add,
                          const float difference, const float replace, const float overlay)
{
    sourceColor *= lerp(1, matcapColor, multiply);
    sourceColor += matcapColor * add;
    sourceColor -= matcapColor * difference;
    sourceColor = lerp(sourceColor, matcapColor, replace);
    return lerp(sourceColor, BlendOverlay(sourceColor, matcapColor), overlay);
}

#endif // HEKKY_PBR_UBER_MATCAPS
