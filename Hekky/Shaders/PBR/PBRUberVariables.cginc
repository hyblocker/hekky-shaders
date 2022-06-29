#ifndef HEKKY_PBR_UBER_VARS
#define HEKKY_PBR_UBER_VARS

// Variables are currently separated into a single file

// DFG
HEKKY_DECLARE_TEX2D(_DFG);

// Albedo
HEKKY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST, _MainTex_TexelSize;
float4 _Color;

HEKKY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
float _BumpScale;

float _Metallic;
// Metal Mask
HEKKY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap);

float _Glossiness;
int _InvertGlossiness;
// Roughness map
HEKKY_DECLARE_TEX2D_NOSAMPLER(_SpecGlossMap);

float _ExposureOcclusion;

// Emission
float4 _EmissionColor;
HEKKY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
float _EmissionIntensity;

float _OcclusionStrength;
HEKKY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);

// Lighting
int _LightingMode = 0; // 0 => Realistic ; 1 => Toon ; 2 => Unlit
int _LightingShadows = 0; // 0 => Off ; 1 => On

// Specular
int _SpecularMode = 0; // 0 => Isotropic ; 1 => Anisotropic
int _LightmapSpecular = 0; // Baked lighting specular
float _Specular;
float4 _SpecularTint;
float _AnisoStrength; // aniso XY
HEKKY_DECLARE_TEX2D_NOSAMPLER(_AnisoMap); // aniso tex ; RG => XY
float4 _AnisoMap_TexelSize;
float _AnisoAngleOffset;

// Outlines
#if OUTLINE
    int _DoOutline;
    float _OutlineWidth;
    float3 _OutlineColor;
#endif

// Toon
float _MathGradientStart, _MathGradientEnd;
// Remapped
static float2 _MathGradientRemapped = float2(
    // Lerp bc if we don't remap the start and end to start at some delta,
    // parts which are lit would have specular lighting instead of just being lit
            lerp( 0.033, 1.0, _MathGradientStart),
            lerp( 0.033, 1.0, _MathGradientEnd )
        );
float _ToonMathGradientMaxBrightness, _ToonMathGradientMinBrightness;
static float2 _ToonMathGradientBrightnessRemapped = float2 ( _ToonMathGradientMinBrightness * 0.5, _ToonMathGradientMaxBrightness * 0.5 );

// Normal reprojection
float _EnableNormalReproj, _NormalReprojBlend;

// Matcaps
int _DoMatcap;
HEKKY_DECLARE_TEX2D(_MatcapTex);
HEKKY_DECLARE_TEX2D_NOSAMPLER(_MatcapMask);
float _MatcapBorder;
float _MatcapReplaceBlend;
float _MatcapAddBlend;
float _MatcapDifferenceBlend;
float _MatcapMultiplyBlend;
float _MatcapOverlayBlend;
float _MatcapReflectionBlend;

// AudioLink
int _EmissionAudioLinkMultiplyChannel;
float2 _EmissionAudioLinkMultiplyRange;
int _EmissionAudioLinkAddChannel;
float2 _EmissionAudioLinkAddRange;

#if BAKERY_ENABLED
// Declare bakery textures
HEKKY_DECLARE_TEX2D(_RNM0);
HEKKY_DECLARE_TEX2D_NOSAMPLER(_RNM1);
HEKKY_DECLARE_TEX2D_NOSAMPLER(_RNM2);
#endif

#endif