#ifndef HEKKY_PBR_UBER_POM
#define HEKKY_PBR_UBER_POM

inline float2 handlePom(float2 inputUV, const ShadingData shadingData) {
	
#if PARALLAX_OCCLUSION_MAPPING
	float scaledParallax = _Parallax * 0.02f;

	const float dx = ddx(inputUV);
	const float dy = ddy(inputUV);

	const int MAX_ITERATIONS = 32;

	// Range of acceptable step counts
	const float MIN_SAMPLES = 1.f;
	const float MAX_SAMPLES = 32.f;
	
	// Optimisation 1.
	// Use more layers if the eye is parallel to the surface, and less if the eye is perpendicular to the surface 
	float angleBias = 1.f - saturate(dot(shadingData.view, shadingData.geometricNormal));
	
	// Optimisation 2.
	// Use more layers if the eye is closer to the point being shaded, and fallback to normal mapping from afar.
	float distBias = shadingData.viewDistance;
	distBias = saturate(distBias * 0.09f); // Tune distance attenuation
	distBias = 1.f - pow(distBias, 0.45f); // Adjust fall-off, and invert
	
	float layerCount = lerp(MIN_SAMPLES, MAX_SAMPLES, angleBias * distBias);
	float layerDepth = 1.f / layerCount;

	float3 viewTangentSpace = mul(shadingData.view, shadingData.tangentToWorld).xyz;
	float2 pt = viewTangentSpace.xy / viewTangentSpace.z * scaledParallax;
	float2 deltaCoords = pt / layerCount;

	float depth = 0.f;
	float2 uvCoord = inputUV;
	float height = (1.f - HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(_ParallaxMap, uvCoord, sampler_MainTex, dx, dy).r);

	int iter = 0;
	UNITY_LOOP
	while (depth < height) {
		uvCoord -= deltaCoords;
		height = (1.f - HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(_ParallaxMap, uvCoord, sampler_MainTex, dx, dy).r);
		depth += layerDepth;
		if (++iter > MAX_ITERATIONS) break;
	}

	float2 originalCoords = uvCoord + deltaCoords;

	float furthestDepth = height - depth;
	float originalDepth = (1.f - HEKKY_SAMPLE_TEX2D_SAMPLER_GRAD(_ParallaxMap, originalCoords, sampler_MainTex, dx, dy).r) - depth + layerDepth;

	float sampleWeight = furthestDepth / (furthestDepth - originalDepth);
	inputUV = originalCoords * sampleWeight + uvCoord * (1.f - sampleWeight);

	#if POM_CLIPPING
		if (inputUV.x < 0.f || inputUV.x > 1.f || inputUV.y < 0.f || inputUV.y > 1.f) {
			// @FIXME: Appararently this crashes AMD users and kills the entire driver
			discard;
		}
	#endif
#endif

	return inputUV;
}

#endif // HEKKY_PBR_UBER_POM