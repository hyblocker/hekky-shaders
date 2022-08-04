#ifndef HEKKY_PBR_UBER_PASSES_META
#define HEKKY_PBR_UBER_PASSES_META

#include "UnityStandardMeta.cginc"

Texture2D bestFitNormalMap;
float _IsFlipped;

struct bakeryMetaInput
{
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal : NORMAL;
    #ifndef _TERRAIN_NORMAL_MAP
        float4 tangent : TANGENT;
    #endif
};

struct v2f_bakeryMeta
{
    float4 pos      : SV_POSITION;
    float2 uv       : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float3 tangent  : TEXCOORD2;
    float3 binormal : TEXCOORD3;
};

// Taken from BakeryMetaPass.cginc
// Encodes a normal into a format that Bakery understands
float3 EncodeNormalBestFit(float3 n)
{
    float3 nU = abs(n);
    float maxNAbs = max(nU.z, max(nU.x, nU.y));
    float2 TC = nU.z<maxNAbs? (nU.y<maxNAbs? nU.yz : nU.xz) : nU.xy;
    TC = TC.x<TC.y? TC.yx : TC.xy;
    TC.y /= TC.x;

    n /= maxNAbs;
    float fittingScale = bestFitNormalMap.Load(int3(TC.x*1023, TC.y*1023, 0)).a;
    n *= fittingScale;
    return n*0.5+0.5;
}

float3 TransformNormalMapToWorld(v2f_bakeryMeta i, float3 normal)
{
    float3x3 TBN = float3x3(normalize(i.tangent), normalize(i.binormal), normalize(i.normal));
    return mul(TBN, normal);
}

v2f_bakeryMeta vertBakeryMeta (bakeryMetaInput v)
{
    v2f_bakeryMeta o;
    o.pos = float4(((v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw)*2-1) * float2(1,-1), 0.5, 1);
    o.uv = v.uv0;
    o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal).xyz);

    #ifdef _TERRAIN_NORMAL_MAP
        o.tangent = cross(o.normal, float3(0,0,1));
        o.binormal = cross(o.normal, o.tangent) * -1;
    #else
        o.tangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz).xyz);
        o.binormal = cross(o.normal, o.tangent) * v.tangent.w * _IsFlipped;
    #endif

    return o;
}

float4 fragBakeryMeta (v2f_bakeryMeta i): SV_Target
{
    UnityMetaInput o;
    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
    float4 albedo = tex2D(_MainTex, i.uv);
    o.Albedo = albedo.rgb;

    // Output custom normal to use with Bakery's "Baked Normal Map" mode
    if (unity_MetaFragmentControl.z)
    {
        const float3 normalMap = UnpackNormal(tex2D(_BumpMap, i.uv));
        const float3 customWorldNormal = TransformNormalMapToWorld(i, normalMap);
        return float4(EncodeNormalBestFit(customWorldNormal),1);
    }
    
    // Output custom alpha to Bakery
    if (unity_MetaFragmentControl.w)
    {
        return albedo.a;
    }

    // Regular Unity meta pass
    return UnityMetaFragment(o);
}

#endif // HEKKY_PBR_UBER_PASSES_META