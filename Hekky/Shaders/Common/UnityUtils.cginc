#ifndef HEKKY_COMMON_UNITY_UTILS
#define HEKKY_COMMON_UNITY_UTILS

#define EPSILON 1e-5

//invert function from https://answers.unity.com/questions/218333/shader-inversefloat4x4-function.html, thank you d4rk
inline float4x4 inverse(float4x4 input)
{
    #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
    //determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))

    const float4x4 cofactors = float4x4(
        minor(_22_23_24, _32_33_34, _42_43_44),
        -minor(_21_23_24, _31_33_34, _41_43_44),
        minor(_21_22_24, _31_32_34, _41_42_44),
        -minor(_21_22_23, _31_32_33, _41_42_43),

        -minor(_12_13_14, _32_33_34, _42_43_44),
        minor(_11_13_14, _31_33_34, _41_43_44),
        -minor(_11_12_14, _31_32_34, _41_42_44),
        minor(_11_12_13, _31_32_33, _41_42_43),

        minor(_12_13_14, _22_23_24, _42_43_44),
        -minor(_11_13_14, _21_23_24, _41_43_44),
        minor(_11_12_14, _21_22_24, _41_42_44),
        -minor(_11_12_13, _21_22_23, _41_42_43),

        -minor(_12_13_14, _22_23_24, _32_33_34),
        minor(_11_13_14, _21_23_24, _31_33_34),
        -minor(_11_12_14, _21_22_24, _31_32_34),
        minor(_11_12_13, _21_22_23, _31_32_33)
    );
    #undef minor
    return transpose(cofactors) / determinant(input);
}

inline float4x4 worldToView()
{
    return UNITY_MATRIX_V;
}

inline float4x4 viewToWorld()
{
    return UNITY_MATRIX_I_V;
}

inline float4x4 viewToClip()
{
    return UNITY_MATRIX_P;
}

inline float4x4 clipToView()
{
    return inverse(UNITY_MATRIX_P);
}

inline float4x4 worldToClip()
{
    return UNITY_MATRIX_VP;
}

inline float4x4 clipToWorld()
{
    return inverse(UNITY_MATRIX_VP);
}

inline float invLerp(float a, float b, float v) {
    return (v - a) / (b - a);
}
inline float invLerp(float2 a, float2 b, float2 v) {
    return (v - a) / (b - a);
}
inline float invLerp(float3 a, float3 b, float3 v) {
    return (v - a) / (b - a);
}
inline float invLerp(float4 a, float4 b, float4 v) {
    return (v - a) / (b - a);
}

inline float remap(float iMin, float iMax, float oMin, float oMax, float v) {
    float t = invLerp( iMin, iMax, v );
    return lerp( oMin, oMax, t );
}
inline float2 remap(float2 iMin, float2 iMax, float2 oMin, float2 oMax, float v) {
    float t = invLerp( iMin, iMax, v );
    return lerp( oMin, oMax, t );
}
inline float3 remap(float3 iMin, float3 iMax, float3 oMin, float3 oMax, float v) {
    float t = invLerp( iMin, iMax, v );
    return lerp( oMin, oMax, t );
}
inline float4 remap(float4 iMin, float4 iMax, float4 oMin, float4 oMax, float v) {
    float t = invLerp( iMin, iMax, v );
    return lerp( oMin, oMax, t );
}

inline bool IsOrtho()
{
    return unity_OrthoParams.w == 1 || UNITY_MATRIX_P[3][3] == 1;
}

bool isReflectionProbe()
{
    return UNITY_MATRIX_P[0][0] == 1 && unity_CameraProjection._m11 == 1;
}

// A pair of functions to either take per-vertex normals or per-pixel normals
inline half3 normalizePerVertexNormal (float3 n) // takes float to avoid overflow
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

inline float3 normalizePerPixelNormal (float3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize((float3)n); // takes float to avoid overflow
    #endif
}

inline half luminosity(const half3 color)
{
    // luma co-efficients for BT.709-1
    const half3 lumaWeight = half3(0.2125, 0.7154, 0.0721);
    return dot(color, lumaWeight);
}

#endif // HEKKY_COMMON_UNITY_UTILS