#ifndef HEKKY_PBR_UBER_VARS
#define HEKKY_PBR_UBER_VARS

// Variables are currently separated into a single file

// DFG
HEKKY_DECLARE_TEX2D(_DFG);

// Access the current blendmode
float _Mode;

// Albedo
HEKKY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST, _MainTex_TexelSize;
float4 _Color;
float _AlphaClip;

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

#if PARALLAX_OCCLUSION_MAPPING
    float _Parallax;
    HEKKY_DECLARE_TEX2D_NOSAMPLER(_ParallaxMap);
#endif

// Lighting
int _LightingMode = 0; // 0 => Realistic ; 1 => Toon ; 2 => Unlit
int _LightingShadows = 0; // 0 => Off ; 1 => On

// Specular
int _SpecularMode = 0; // 0 => Isotropic ; 1 => Anisotropic
int _LightmapSpecular = 0; // Baked lighting specular
float _LightmapSpecularMaxSmoothness = 0; // Baked lighting max specular smoothness
float _Specular;
float _AdobeFresnelTint;
float4 _BakedSpecularTint;
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
float2 _ToonMathGradientDiffuse;
float2 _ToonMathGradientSpecular;
float2 _ToonMathGradientBrightness;

// Normal reprojection
float _EnableNormalReproj, _NormalReprojBlend;

// Matcaps
int _DoMatcap;
float3 _MatcapColor;
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

#if SUBSURFACE_SCATTERING

float _SSSVisibility;
HEKKY_DECLARE_TEX2D_NOSAMPLER(_SSSMap);
float3 _SSSColor;
float _SSSIntensity;

#endif

#if SSR

HEKKY_DECLARE_TEX2D_SCREENSPACE(_GrabTexture);
float4 _GrabTexture_TexelSize;
Texture2D _BlueNoise;
float4 _BlueNoise_TexelSize;
float _SSRBlur;
float _SSRAccuracy;
float _SSREdgeFade;
int _SSRMaxSteps;

#endif

#if BAKERY_ENABLED
// Declare bakery textures
HEKKY_DECLARE_TEX2D(_RNM0);
HEKKY_DECLARE_TEX2D_NOSAMPLER(_RNM1);
HEKKY_DECLARE_TEX2D_NOSAMPLER(_RNM2);
#endif

// LTCGI
float3 _LTCGI_Scale;
float2 _LTCGI_Intensity;

#endif