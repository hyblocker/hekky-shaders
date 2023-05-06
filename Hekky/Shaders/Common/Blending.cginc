#ifndef HEKKY_COMMON_BLENDING
#define HEKKY_COMMON_BLENDING

// literally like a lot of blending functions LOL

inline float4 BlendReplace(float4 base, float4 blend)
{
    return base;
}
inline float4 BlendAdd(float4 a, float4 blend)
{
    return a + blend;
}
inline float4 BlendSubtract(float4 a, float4 blend)
{
    return abs(a - blend);
}
inline float4 BlendMultiply(float4 a, float4 blend)
{
    return a * blend;
}
inline float4 BlendScreen(float4 a, float4 blend)
{
    return a + blend - (a * blend);
}

inline float BlendOverlay(float base, float blend)
{
    return (base <= 0.5) ? 2 * base * blend : 1 - 2 * (1 - base) * (1 - blend);
}
inline float3 BlendOverlay(float3 base, float3 blend)
{
    return float3( BlendOverlay(base.r, blend.r), 
                   BlendOverlay(base.g, blend.g), 
                   BlendOverlay(base.b, blend.b) );
}

inline float3 AlphaBlend(float4 base, float4 blend)
{
    return base.rgb * (1 - blend.a) + blend.rgb * blend.a;
}

inline float3 BlendNormals(const float3 base, const float3 detail)
{
    // Detail oriented normal mapping, https://blog.selfshadow.com/publications/blending-in-detail/
    return normalize(base * dot(base, detail) - detail * base.z);
}

inline float3 BlendNormalsWorldSpace(const float3 geom, const float3 base, const float3 detail)
{
    // Detail oriented normal mapping, https://blog.selfshadow.com/publications/blending-in-detail/ ; using eqn. 4
    // Build the shortest-arc quaternion
    float4 quat = float4(cross(geom, base), dot(geom, base) + 1.f) / sqrt(2.f * (dot(geom, base) + 1.f));
    // Rotate the normal
    return normalize(detail * (quat.w * quat.w - dot(quat.xyz, quat.xyz)) + 2.f * quat.xyz * dot(quat.xyz, detail) + 2.f * quat.w * cross(quat.xyz, detail));
}

inline float3 LerpNormals(float3 base, float3 detail, float amount)
{
    // Detail oriented normal mapping, https://blog.selfshadow.com/publications/blending-in-detail/
    amount = clamp(amount, 0.0001f, 1.f);
    base    = normalize(base * (1.f - amount));
    detail  = normalize(detail * amount);
    return base * dot(base, detail) - detail * base.z;
}

// Advanced Terrain Texture Splatting
// TLDR: Blending based on heightmap
// https://www.gamedeveloper.com/programming/advanced-terrain-texture-splatting
inline float3 heightmapBlend(float3 texture1, float height1, float alpha1, float3 texture2, float height2, float alpha2)
{
    const float depth = 0.2;
    const float ma = max(height1 + alpha1, height2 + alpha2) - depth;

    const float b1 = max(height1 + alpha1 - ma, 0);
    const float b2 = max(height2 + alpha2 - ma, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
}
inline float3 heightmapBlend(float3 texture1, float height1, float3 texture2, float height2, float delta)
{
    const float alpha1 = 1.f - delta;
    const float alpha2 = delta;
    
    const float depth = 0.2;
    const float ma = max(height1 + alpha1, height2 + alpha2) - depth;

    const float b1 = max(height1 + alpha1 - ma, 0);
    const float b2 = max(height2 + alpha2 - ma, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
}
inline float4 heightmapBlend(float4 texture1, float height1, float alpha1, float4 texture2, float height2, float alpha2)
{
    const float depth = 0.2;
    const float ma = max(height1 + alpha1, height2 + alpha2) - depth;

    const float b1 = max(height1 + alpha1 - ma, 0);
    const float b2 = max(height2 + alpha2 - ma, 0);

    return (texture1.rgba * b1 + texture2.rgba * b2) / (b1 + b2);
}
inline float4 heightmapBlend(float4 texture1, float height1, float4 texture2, float height2, float delta)
{
    const float alpha1 = 1.f - delta;
    const float alpha2 = delta;
    
    const float depth = 0.2;
    const float ma = max(height1 + alpha1, height2 + alpha2) - depth;

    const float b1 = max(height1 + alpha1 - ma, 0);
    const float b2 = max(height2 + alpha2 - ma, 0);

    return (texture1.rgba * b1 + texture2.rgba * b2) / (b1 + b2);
}

inline float heightmapBlend(float texture1, float height1, float alpha1, float texture2, float height2, float alpha2)
{
    const float depth = 0.2;
    const float ma = max(height1 + alpha1, height2 + alpha2) - depth;

    const float b1 = max(height1 + alpha1 - ma, 0);
    const float b2 = max(height2 + alpha2 - ma, 0);

    return (texture1 * b1 + texture2 * b2) / (b1 + b2);
}

inline float heightmapBlend(float texture1, float height1, float texture2, float height2, float delta)
{
    const float alpha1 = 1.f - delta;
    const float alpha2 = delta;
    
    const float depth = 0.2;
    const float ma = max(height1 + alpha1, height2 + alpha2) - depth;

    const float b1 = max(height1 + alpha1 - ma, 0);
    const float b2 = max(height2 + alpha2 - ma, 0);

    return (texture1 * b1 + texture2 * b2) / (b1 + b2);
}

#endif