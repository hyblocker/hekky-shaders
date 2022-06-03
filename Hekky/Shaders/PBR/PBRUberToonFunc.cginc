#ifndef HEKKY_PBR_UBER_TOON_FUNCS
#define HEKKY_PBR_UBER_TOON_FUNCS

inline float toonify( float shadowTerm, const float rangeMin = 0, const float rangeMax = 1 )
{
    float t = invLerp( _MathGradientRemapped.x, _MathGradientRemapped.y, shadowTerm );
    return saturate( lerp( rangeMin, rangeMax, saturate ( t )) );
}

inline float3 toonify( float3 shadowTerm, const float rangeMin = 0, const float rangeMax = 1 )
{
    float t = invLerp( _MathGradientRemapped.x, _MathGradientRemapped.y, shadowTerm );
    return saturate( lerp( rangeMin, rangeMax, saturate ( t )) );
}

#endif // HEKKY_PBR_UBER_TOON_FUNC