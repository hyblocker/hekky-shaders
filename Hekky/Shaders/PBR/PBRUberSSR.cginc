#ifndef PBR_UBER_SSR
#define PBR_UBER_SSR

// Based on https://github.com/Error-mdl/ForwardSSR/blob/master/shaders/SSR.cginc
// This implementation is temporary and most likely going to be massively reworked to work more closely to SSSR

#ifndef HAS_DEPTH_TEXTURE
    #define HAS_DEPTH_TEXTURE
    UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
    float4 _CameraDepthTexture_TexelSize;
#endif

struct SSRData {
	float3 worldPos;
	float3 viewDir;
	float3 reflectDir;
	float3 surfaceNormal;
	float2 screenParams;
	float blur;
	float roughness;
	float hitRadius;
	float edgeFade;
	int maxSteps;
};

float3 sampleGrabPassBlurred(const float2 texelSize, const float2 uv, const float blur) {

	float2	pixelSize		= 2.f / texelSize;
	float	center			= floor(blur * .5f);
	float3	reflectTotal	= float3(0, 0, 0);

	for (int i = 0; i < floor(blur); i++) {
		for (int j = 0; j < floor(blur); j++) {
			float4 reflectionSample = HEKKY_SAMPLE_TEX2D_SCREENSPACE(_GrabTexture, float4(uv.x + pixelSize.x * (i - center), uv.y + pixelSize.y * (j - center), 0, 0));
			reflectTotal += reflectionSample;
		}
	}

	return reflectTotal / (floor(blur) * floor(blur));
}

float perspectiveScaledStep(const float3 rayOrigin, const float3 rayDir, const float maxIterations) {

	float TWO_TAN_HALF_FOV = (-2.f / UNITY_MATRIX_P._m11);
	float screenLength = length(rayDir - rayOrigin * (rayDir.z / rayOrigin.z));
	float distScale = TWO_TAN_HALF_FOV / (maxIterations * max(screenLength, 0.05f));
	distScale = min(distScale, _ProjectionParams.z / maxIterations);
	return max(distScale * (-rayOrigin.z), 0.01f);
}

float4 reflectRay(in float3 rayOrigin, in float3 rayDir, const float hitRadius, const float noise, const float FdotR, const float maxIterations) {

	// In VR we don't want to let the ray move into the other eye.
#if UNITY_SINGLE_PASS_STEREO
	half minX				= 0.5f * unity_StereoEyeIndex;
	half maxX				= 0.5f * unity_StereoEyeIndex + 0.5f;
#else
	half minX				= 0.f;
	half maxX				= 1.f;
#endif

	rayOrigin				= mul(UNITY_MATRIX_V, float4(rayOrigin.xyz, 1));
	rayDir					= mul((float3x3)UNITY_MATRIX_V, rayDir.xyz);

	int totalIterations		= 0;
	float direction			= 1.f;
	float3 finalPos			= float3(0,0,0);
	float stepNoise			= mad(noise, 0.01f, 0.05f);

	float dynamicStep		= perspectiveScaledStep(rayOrigin, rayDir, maxIterations) * 0.f + 0.09f;
	float smallHitRadius	= mad(noise, hitRadius, hitRadius) * 0.f + 0.02f;
	float largeHitRadius	= mad(noise, 2.f * dynamicStep, dynamicStep) * 0.f + 0.2f;

	float3 reflectedRay		= rayOrigin + rayDir * largeHitRadius;

	[loop]
	for (float i = 0; i < maxIterations; i++) {
		totalIterations = i;

		float4 screenspacePos = ComputeGrabScreenPos(mul(UNITY_MATRIX_P, reflectedRay));

		float2 uvDepth = screenspacePos.xy / screenspacePos.w;

		// If the ray is outside the view frustum, early exit
		if (uvDepth.x > maxX || uvDepth.x < minX || uvDepth.y > 1 || uvDepth.y < 0 || -reflectedRay.z > _ProjectionParams.z) {
			break;
		}

		float rawDepth = DecodeFloatRG(SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(uvDepth, 0, 0)));
		float linearDepth = Linear01Depth(rawDepth);
		// Clears a lot of random specks from false positives
		linearDepth = linearDepth > 0.999999f ? 2000.f : linearDepth;

		float sampleDepth = -reflectedRay.z;
		float realDepth = linearDepth * _ProjectionParams.z;

		float depthDifference = abs(sampleDepth - realDepth);

		if (depthDifference < largeHitRadius) {
			if (direction == 1) {
				if (sampleDepth > realDepth - smallHitRadius) {
					if (sampleDepth < realDepth + smallHitRadius) {
						finalPos = reflectedRay;
						break;
					}

					direction = -1.f;
					dynamicStep = max(.5f * dynamicStep, smallHitRadius);
					largeHitRadius = max(.5f * largeHitRadius, smallHitRadius);
				}
			}
			else {
				if (sampleDepth < realDepth + smallHitRadius) {

					direction = 1.f;
					dynamicStep = max(.5f * dynamicStep, smallHitRadius);
					largeHitRadius = max(.5f * largeHitRadius, smallHitRadius);
				}
			}
		}

		reflectedRay = mad(rayDir, direction * dynamicStep * largeHitRadius, reflectedRay);

		float oldStepSize = dynamicStep;
		dynamicStep = perspectiveScaledStep(reflectedRay, rayDir, maxIterations);
		float stepIncrease = dynamicStep / oldStepSize;

		largeHitRadius = largeHitRadius * stepIncrease;
		smallHitRadius = smallHitRadius * stepIncrease;
	}

	return float4(finalPos, totalIterations);
}

float4 computeSSRColor(SSRData data) {

	// To know if the reflected ray will go beneath the surface
	const float FdotR = saturate(dot(data.reflectDir, data.surfaceNormal));

	UNITY_BRANCH
	if (FdotR < 0 || isInMirror() || isReflectionProbe()) {
		return 0;
	}
	else {

		float4 screenUV = UNITY_PROJ_COORD(ComputeGrabScreenPos(mul(UNITY_MATRIX_VP, data.worldPos)));
		screenUV.xy = screenUV.xy / screenUV.w;

		// Offset the ray's hit detection range randomly by a blue noise texture to minimise artifacts such as banding
		float4 noiseUV = screenUV;
		noiseUV.xy = noiseUV.xy * data.screenParams;
		noiseUV.xy += frac(_Time.y) * data.screenParams;
		noiseUV.xy = fmod(noiseUV.xy, _BlueNoise_TexelSize.xy);
		float4 noiseTex = _BlueNoise.Load(float4(noiseUV.xy, 0, 0));
		float noise = noiseTex.r;

		float4 finalPos = reflectRay(data.worldPos, data.reflectDir, data.hitRadius, noise, FdotR, data.maxSteps);
		float totalIterations = finalPos.w;
		finalPos.w = 1.f;

		// If XYZ components are 0, the reflected ray went off-screen
		if (!any(finalPos)) {
			return float4(0, 0, 0, 0);
		}

		float4 uv;
		uv = UNITY_PROJ_COORD(ComputeGrabScreenPos(mul(UNITY_MATRIX_P, finalPos)));
		uv.xy = uv.xy / uv.w;

		// Compute a fade factor
		// We want to fade the SSR away near edges of the screen, as the ray will end up outside of the framebuffer
		// In VR we don't want to fade SSR away near edges of the screen or we'll have inconsistent fading between eyes, which can be
		// nauseating
#if UNITY_SINGLE_PASS_STEREO
		float xFade = 1.f;
#else
		float xFade = smoothstep(0.f, data.edgeFade, uv.x) * smoothstep(1.f, 1.f - data.edgeFade, uv.x);
#endif
		float yFade = smoothstep(0.f, data.edgeFade, uv.y) * smoothstep(1.f, 1.f - data.edgeFade, uv.y);
		xFade = pow(xFade, 0.25f);
		yFade = pow(yFade, 0.25f);
		float fade = xFade * yFade;

		// Fake roughness?
		float blurFactor = max(1, min(12, 12 * (data.roughness) * 2));
		float4 reflection = float4(sampleGrabPassBlurred(data.screenParams, uv.xy, blurFactor), 1);

		reflection.a = lerp(0, reflection.a, fade * fade * fade * FdotR);

		return max(0, reflection);

	}
}

#endif // PBR_UBER_SSR