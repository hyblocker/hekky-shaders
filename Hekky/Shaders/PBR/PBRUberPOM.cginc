#ifndef HEKKY_PBR_UBER_POM
#define HEKKY_PBR_UBER_POM

inline float2 handlePom(float2 inputUV, const ShadingData shadingData) {
	
#if PARALLAX_OCCLUSION_MAPPING
	float scaledParallax = _Parallax * 0.02f;

	const float dx = ddx(inputUV);
	const float dy = ddy(inputUV);

	const int MAX_ITERATIONS = 128;

	const float MIN_SAMPLES = 8.f;
	const float MAX_SAMPLES = 16.f;
	float layerCount = lerp(MAX_SAMPLES, MIN_SAMPLES, saturate(dot(shadingData.view, shadingData.geometricNormal)));
	float layerDepth = 1.f / layerCount;

	float3 viewTangentSpace = mul(shadingData.view, shadingData.tangentToWorld).xyz;
	float2 pt = viewTangentSpace.xy / viewTangentSpace.z * scaledParallax;
	float2 deltaCoords = pt / layerCount;

	float depth = 0.f;
	float2 uvCoord = inputUV;
	float height = (1.f - HEKKY_SAMPLE_GRAD_TEX2D_SAMPLER(_ParallaxMap, uvCoord, sampler_MainTex, dx, dy).r);

	int iter = 0;
	UNITY_LOOP
	while (depth < height) {
		uvCoord -= deltaCoords;
		height = (1.f - HEKKY_SAMPLE_GRAD_TEX2D_SAMPLER(_ParallaxMap, uvCoord, sampler_MainTex, dx, dy).r);
		depth += layerDepth;
		if (++iter > MAX_ITERATIONS) break;
	}

	float2 originalCoords = uvCoord + deltaCoords;

	float furthestDepth = height - depth;
	float originalDepth = (1.f - HEKKY_SAMPLE_GRAD_TEX2D_SAMPLER(_ParallaxMap, originalCoords, sampler_MainTex, dx, dy).r) - depth + layerDepth;

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