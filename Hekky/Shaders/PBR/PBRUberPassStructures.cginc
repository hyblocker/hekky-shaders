#ifndef HEKKY_PBR_UBER_PASS_STRUCTURES
#define HEKKY_PBR_UBER_PASS_STRUCTURES

#if FORWARD_BASE || FORWARD_ADD

struct appdata
{
    float4 vertex   : POSITION;
    float4 color    : COLOR;
    half3 normal    : NORMAL;
    float2 uv       : TEXCOORD0;
    float2 uv1      : TEXCOORD1;
    float2 uv2      : TEXCOORD3;
    float2 uv3      : TEXCOORD4;
        
    half4 tangent   : TANGENT;
        
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    UNITY_POSITION(pos);
    float4 color                            : COLOR_centroid;
    float4 uv                               : TEXCOORD0;            // UV 0, 1
    float4 uv1                              : TEXCOORD1;            // UV 2, 3
    half4 ambientOrLightmapUV               : TEXCOORD2_centroid;   // SH or Lightmap UV
        
    float4 eyeVec                           : TEXCOORD3;            // eyeVector.xyz | fogCoord
    float4 tangentToWorldAndPackedData[3]   : TEXCOORD4;            //
    // float3 normal                           : TEXCOORD4;
    // float4 tangent                          : TEXCOORD5;
    // float3 binormal                         : TEXCOORD6;
    UNITY_LIGHTING_COORDS(7, 8)
        
    // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
    float3 posWorld                         : TEXCOORD9;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#endif

// Simplified vertex attributes for shadow pass
#if SHADOW_CASTER

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{ 
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD1;
    UNITY_SHADOW_COORDS(0)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#endif


#endif // HEKKY_PBR_UBER_PASS_STRUCTURES
