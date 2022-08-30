#ifndef HEKKY_PBR_UBER_LIGHTING_DIRECTIONAL
#define HEKKY_PBR_UBER_LIGHTING_DIRECTIONAL

inline float3 sampleSunAreaLight(const float3 lightDirection, const ShadingData shading) {
    // Replaced frameUniforms.sun
    #if defined(SUN_AS_AREA_LIGHT)
    // cos(sunAngle), sin(sunAngle), 1/(sunAngle*HALO_SIZE-sunAngle), HALO_EXP
    const float sunAngle = 0.00951f;
    const float sunHaloSize = 10.0f;
    const float sunHaloFalloff = 80.0f;
    const float4 sunParameters = float4(cos(sunAngle), sin(sunAngle), 1/(sunAngle*sunHaloSize-sunAngle), sunHaloFalloff);
    if (sunParameters.w >= 0.0) {
        // simulate sun as disc area light
        float LoR = dot(lightDirection, shading.reflected);
        float d = sunParameters.x;
        float3 s = shading.reflected - LoR * lightDirection;
        return LoR < d ?
                normalize(lightDirection * d + normalize(s) * sunParameters.y) : shading.reflected;
    }
    #endif
    return lightDirection;
}

float4 UnityLight_ColorIntensitySeperated() {
    // float3 normalizedColor = normalize(_LightColor0.xyz);
    // float lightIntensity = _LightColor0.x / normalizedColor.x;
    // return float4(normalizedColor, lightIntensity);
    return float4(_LightColor0.xyz, 1.0);
}

inline Light getDirectionalLight(const ShadingData shading) {
    Light light;
    // note: lightColorIntensity.w is always premultiplied by the exposure
    light.colorIntensity = UnityLight_ColorIntensitySeperated();
    light.l = sampleSunAreaLight(_WorldSpaceLightPos0.xyz, shading);
    light.NdotL = saturate(dot(shading.normal, light.l));
    light.attenuation = 1.0;
    return light;
}

float3 evaluateDirectionalLight(const ShadingData shading, const MaterialData material, const PixelParams pixel)
{
    const Light light = getDirectionalLight(shading);

    float visibility = 1.0;

    #if SHADOWS_ENABLED
    
    if (any(light.NdotL))
    {
        #ifdef HEKKY_UBER_TOON
            visibility *= toonify(shading.attenuation, _ToonMathGradientDiffuse, -1, 1);
        #else
            visibility *= shading.attenuation;
        #endif
    }
    
    #endif
    
    float3 color = surfaceShading(shading, pixel, light, visibility);
    
    return color;
}


#endif // HEKKY_PBR_UBER_LIGHTING_DIRECTIONAL