#ifndef PBR_UBER_OUTLINE
#define PBR_UBER_OUTLINE

float4 evaluateOutline(const ShadingData shadingData, const MaterialData material)
{
    return float4(_OutlineColor, 1);
}

#endif // PBR_UBER_OUTLINE