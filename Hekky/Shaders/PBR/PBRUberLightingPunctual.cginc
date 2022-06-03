#ifndef HEKKY_PBR_UBER_LIGHTING_PUNCTUAL
#define HEKKY_PBR_UBER_LIGHTING_PUNCTUAL

float4 UnityLight_ColorIntensitySeperated_Punctual()
{
    // float3 normalizedColor = normalize(_LightColor0.xyz);
    // float lightIntensity = _LightColor0.x / normalizedColor.x;
    // return float4(normalizedColor, lightIntensity);
    return float4(_LightColor0.xyz, 1.0);
}

Light getLight(const ShadingData shading)
{
    Light light;
    // position-to-light vector
    const float3 posToLight = _WorldSpaceLightPos0.xyz - shading.position;
    
    // note: lightColorIntensity.w is always premultiplied by the exposure
    light.colorIntensity = UnityLight_ColorIntensitySeperated_Punctual();
    light.attenuation = shading.attenuation;
    light.l = normalize(posToLight);
    light.NdotL = saturate(dot(shading.normal, light.l));
    light.worldPosition = _WorldSpaceLightPos0.xyz;
    light.distance = distance(_WorldSpaceLightPos0.xyz, shading.position);
    
    return light;
}

float3 evaluatePunctualLights(const ShadingData shading, const MaterialData material, const PixelParams pixel)
{
    Light light = getLight(shading);

    // Try using EA's Punctual light formula?
    
    // float phi = PI * light.attenuation;
    // float3 color = light.colorIntensity * light.attenuation;
 
    // if (light.NoL <= 0.0)
    //     return 0;
    
    return surfaceShading(shading, pixel, light, 1);
}


#endif // HEKKY_PBR_UBER_LIGHTING_PUNCTUAL