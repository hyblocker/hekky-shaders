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

#endif