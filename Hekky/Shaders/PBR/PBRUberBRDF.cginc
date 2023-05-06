#ifndef HEKKY_PBR_UBER_BSDF
#define HEKKY_PBR_UBER_BSDF

// Constant Fresnel incidence for non-metals
#define Fdielectric 0.04

inline float sqr(const float val)
{
    return val * val;
}

inline float3 F_Adobe(in float3 f0, in float f90, in float u, in float t)
{
    // Naty Hoffman 2023, "Generalization of Adobe’s Fresnel Model"
    const float u_max = 1.f / 7.f;
    
    const float u1 = 1.f - u;
    const float u2 = u1 * u1;
    
    const float3 a = (f0 + (f90 - f0) * pow(1.f - u_max, u)) * (1.f - t) / (u_max * pow(1.f - u_max, 6));

    return max(f0 + (f90 - f0) * u2 * u2 * u1 - a * pow(u1, 6), 0.f);
}

inline float3 F_Schlick(in float u)
{
    // f0 = 0,0,0
    // f90 = 1
    float m = clamp(1 - u, 0, 1);
    float m2 = m * m;
    return m2 * m2 * m; // pow(m,5)
}

inline float3 F_Schlick(in float3 f0, in float f90, in float u)
{
    #ifdef _DOADOBEFRESNEL_ON
    return F_Adobe(f0, f90, u, _AdobeFresnelTint);
    #else
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    const float u1 = 1.f - u;
    const float u2 = u1 * u1;
    return f0 + (f90 - f0) * u2 * u2 * u1;
    #endif
}

inline float V_SmithGGXCorrelated(const float NdotL, const float NdotV, const float alphaG)
{
    // Original formulation of G_SmithGGX Correlated
    // lambda_v = ( -1 + sqrt ( alphaG2 * (1 - NdotL2 ) / NdotL2 + 1) ) * 0.5 f ;
    // lambda_l = ( -1 + sqrt ( alphaG2 * (1 - NdotV2 ) / NdotV2 + 1) ) * 0.5 f ;
    // G_SmithGGXCorrelated = 1 / (1 + lambda_v + lambda_l ) ;
    // V_SmithGGXCorrelated = G_SmithGGXCorrelated / (4.0 f * NdotL * NdotV ) ;

    // This is the optimized version
    const float alphaG2 = alphaG * alphaG;
    // Caution: the " NdotL *" and " NdotV *" are explicitly inversed, this is not a mistake.
    const float Lambda_GGXV = NdotL * sqrt((- NdotV * alphaG2 + NdotV) * NdotV + alphaG2);
    const float Lambda_GGXL = NdotV * sqrt((- NdotL * alphaG2 + NdotL) * NdotL + alphaG2);

    // Minimum value of EPSILON as other we'd have a divide by zero breaking the entire BRDF
    // return 0.5f / (Lambda_GGXV + Lambda_GGXL);
    return 0.5f / max((Lambda_GGXV + Lambda_GGXL), EPSILON);
}

inline float V_SmithGGXCorrelated_Anisotropic(const float aT, const float aB, const float TdotV, const float BdotV,
                                       const float TdotL, const float BdotL, const float NdotV, const float NdotL)
{
    const float lambdaV = NdotL * length(float3(aT * TdotV, aB * BdotV, NdotV));
    const float lambdaL = NdotV * length(float3(aT * TdotL, aB * BdotL, NdotL));

    return 0.5 / max(lambdaV * lambdaL, 0.001f);
}

inline float D_GGX(const float NdotH, const float roughness)
{
    // Taken from Google's Filament, as it yields less artifacting than the one from EA's paper
    const float oneMinusNoHSquared = 1.0 - NdotH * NdotH;
    const float a = NdotH * roughness;
    const float k = a / (oneMinusNoHSquared + a * a);
    // Divide by PI is applied later
    return k * k;
}

inline float D_GGX_Anisotropic(const float NdotH, const float BdotH,
        const float TdotH, const float aT, const float aB) {

    const float a2 = aT * aB;
    const float3 d = float3(aB * TdotH, aT * BdotH, a2 * NdotH);
    const float d2 = dot(d, d);
    const float b2 = a2 / d2;
    return a2 * b2 * b2;
}

inline float Fr_DisneyDiffuse(const float NdotV, const float NdotL, const float LdotH, const float linearRoughness)
{
    const float energyBias = lerp(0, 0.5, linearRoughness);
    const float energyFactor = lerp(1.0, 1.0 / 1.51, linearRoughness);
    const float fd90 = energyBias + 2.0 * LdotH * LdotH * linearRoughness;
    const float3 f0 = float3(1.0f, 1.0f, 1.0f);
    const float lightScatter = F_Schlick(f0, fd90, NdotL).r;
    const float viewScatter = F_Schlick(f0, fd90, NdotV).r;
    return lightScatter * viewScatter * energyFactor;
}

inline float subsurfaceLobe(const float NdotV, const float NdotL, const float LdotH, const float linearRoughness)
{
    float FL = F_Schlick(NdotL);
    float FV = F_Schlick(NdotV);
    float Fss90 = LdotH * LdotH * linearRoughness;
    float Fss = lerp(1.f, Fss90, FL) * lerp(1.f, Fss90, FV);
    return 1.25f * (Fss * (1.f / max(NdotL + NdotV, 0.01f) - .5f) + .5f);
}

inline float diffuseLobe(const PixelParams pixel, float NdotV, float NdotL, float NdotH, float LdotH)
{
    return Fr_DisneyDiffuse(NdotV, NdotL, LdotH, pixel.roughness);
}

inline float3 specularLobe(const ShadingData shading, const PixelParams pixel, const Light light, const float NdotV,
                    const float NdotL, const float NdotH, const float LdotH, const float3 h)
{
    const float f90 = saturate(dot(pixel.f0, (50.0 * 0.33)));

    UNITY_BRANCH
    // 1 == ANISOTROPIC
    if (_SpecularMode == 1 && abs(pixel.aniso) > 0.01) {

        // Compute the stretch in the X, Y axes
        const float aspect = sqrt(1.0 - pixel.aniso * .9);
        const float aX = max(0.01f, (1.0 - pixel.roughness) / aspect);
        const float aY = max(0.01f, (1.0 - pixel.roughness) * aspect);

        const float TdotH = dot(h, shading.tangent);
        const float BdotH = dot(h, shading.binormal);
        const float TdotV = dot(shading.view, shading.tangent);
        const float BdotV = dot(shading.view, shading.binormal);
        const float TdotL = dot(light.l, shading.tangent);
        const float BdotL = dot(light.l, shading.binormal);
        
        const float D = D_GGX_Anisotropic(NdotH, TdotH, BdotH, aX, aY);
        const float V = V_SmithGGXCorrelated_Anisotropic(aX, aY, TdotV, BdotV, TdotL, BdotL, NdotV, NdotL);
        const float3 F = F_Schlick(pixel.f0, f90, LdotH);

        return (D * V) * F
        * saturate(NdotL * NdotL * 8) // not physically based, but results in nicer blending near the edge of NdotL
        ;
    } else {
        // DEFAULT, 0, ISOTROPIC SPECUALAR LOBE!
        const float D = D_GGX(NdotH, pixel.roughness);
        const float V = V_SmithGGXCorrelated(NdotL, NdotV, pixel.roughness);
        const float3 F = F_Schlick(pixel.f0, f90, LdotH);

        return (D * V) * F;
    }
}

inline float3 surfaceShading(const ShadingData shading, const PixelParams pixel, const Light light, float occlusion)
{
    float3 h = normalize(light.l + shading.view);

    const float NdotV = shading.NdotV;
    const float NdotL = light.NdotL;
    const float NdotH = saturate(dot(shading.normal, h));
    const float LdotH = saturate(dot(light.l, h));

    // Normally you would divide the distribution term by PI, but due to us using Unity as a game engine, we have to
    // re-multiply by PI to get the lighting intensities to match other shaders' values.
    // Hence, I've omitted the divide and multiply by PI in the specular lobe.
    float3 Fr = specularLobe(shading, pixel, light, NdotV, NdotL, NdotH, LdotH, h);
    float3 Fd = pixel.diffuseColor * diffuseLobe(pixel, NdotV, NdotL, NdotH, LdotH) * PI;
    
    UNITY_BRANCH
    if (LIGHTING_MODE_TOON) {
        // hack to preserve high luminosity
        float originalLumExtra = max(0.0, luminosity(Fr) - (_ToonMathGradientBrightness.y - _ToonMathGradientBrightness.x));
		float toonFr = toonify(Fr, _ToonMathGradientSpecular);
        Fr = lerp (_ToonMathGradientBrightness.x, _ToonMathGradientBrightness.y, toonFr ) + originalLumExtra * toonFr;
    }

    // Specular tint
    Fr = lerp(Fr, luminosity(Fr) * _SpecularTint.rgb, _Specular);

    #if SUBSURFACE_SCATTERING
    const float3 ss = subsurfaceLobe(NdotV, NdotL, LdotH, pixel.roughness) * pixel.subsurfaceColor;
    const float subsurfFactor = pixel.subsurfaceIntensity * (1.f - pixel.thickness);
    // Fr = lerp(Fr, ss, pixel.subsurfaceIntensity * (1.f - pixel.thickness));
    #endif

    float3 color = Fd + Fr * pixel.energyConservation;

    float shadowTerm = (light.colorIntensity.w * light.attenuation * light.NdotL * occlusion);
    
    UNITY_BRANCH
    if (LIGHTING_MODE_TOON) {
        shadowTerm = lerp (_ToonMathGradientBrightness.x, _ToonMathGradientBrightness.y, toonify(shadowTerm, _ToonMathGradientDiffuse) );
    } else if (LIGHTING_MODE_UNLIT) {
        shadowTerm = 1;
    } else {
        shadowTerm = saturate(shadowTerm);
    }

    float3 finalColor = (color * light.colorIntensity.rgb) * shadowTerm;
    
    #if SUBSURFACE_SCATTERING
    finalColor += pixel.energyConservation * subsurfFactor * ss * ONE_ON_PI * occlusion;
    #endif

    return finalColor;
}

#endif // HEKKY_PBR_UBER_BSDF
