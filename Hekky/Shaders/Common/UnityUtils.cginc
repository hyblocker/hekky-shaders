#ifndef HEKKY_COMMON_UNITY_UTILS
#define HEKKY_COMMON_UNITY_UTILS

#define PI 3.14159265358979323846
#define ONE_ON_PI 0.3183098861837907

#define EPSILON 1e-5
#define czm_epsilon7 0.0000001f
#define DEG2RAD (6.28318530718f / 360.f)
#define RAD2DEG (360.f * 0.15915494309f)

#define glslMod(x,y) (x - y * floor(x / y))

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

#ifndef COMPUTE_SHADER

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

inline bool IsOrtho()
{
    return unity_OrthoParams.w == 1 || UNITY_MATRIX_P[3][3] == 1;
}

inline bool isReflectionProbe()
{
    return UNITY_MATRIX_P[0][0] == 1 && unity_CameraProjection._m11 == 1;
}

#endif

inline float invLerp(float a, float b, float v) {
    return (v - a) / (b - a);
}
inline float invLerp(float2 a, float2 b, float2 v) {
    return dot((v - a) / (b - a), 1.f/2.f);
}
inline float invLerp(float3 a, float3 b, float3 v) {
    return dot((v - a) / (b - a), 1.f/3.f);
}
inline float invLerp(float4 a, float4 b, float4 v) {
    return dot((v - a) / (b - a), 1.f/4.f);
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

inline float3x3 rotationAlign( const float3 d, const float3 z )
{
    const float3  v = cross( z, d );
    const float c = dot( z, d );
    const float k = 1.0f/(1.0f+c);

    return float3x3( v.x*v.x*k + c,     v.y*v.x*k - v.z,    v.z*v.x*k + v.y,
                     v.x*v.y*k + v.z,   v.y*v.y*k + c,      v.z*v.y*k - v.x,
                     v.x*v.z*k - v.y,   v.y*v.z*k + v.x,    v.z*v.z*k + c   );
}

inline float3 rotate (const float3 p, const float angle, const float3 N)
{
    float cosang, sinang;
    sincos (angle, sinang, cosang);
    const float cosang1 = 1.0 - cosang;

    const float3 N2 = N * N;

    // original is a 3x3 matrix cast into a 4x4, thus reduce the memory footprint
    float3x3 M = float3x3 (
        N2.x            + (1.0 - N2.x) * cosang,
        N2.y * cosang1  + N.z * sinang,
        N2.z * cosang1  - N.y * sinang,

        N2.y * cosang1  - N.z * sinang,
        N2.y            + (1.0 - N2.y) * cosang,
        N2.z * cosang1  + N.x * sinang,

        N2.z * cosang1  + N.y * sinang,
        N2.z * cosang1  - N.x * sinang,
        N2.z            + (1.0 - N2.z) * cosang);
    return mul (M, p);
}

// ABOVE IS OPTIMIZED FORM OF THIS
/*

inline float3 rotate (float3 p, float angle, float3 b)
{
    const float3 a = float3(0,0,0);
    float3 axis = normalize (b - a);
    float cosang, sinang;
    sincos (angle, sinang, cosang);
    float cosang1 = 1.0 - cosang;
    float x = axis[0], y = axis[1], z = axis[2];
    
    float4x4 M = float4x4 ( x * x + (1.0 - x * x) * cosang,
                            x * y * cosang1 + z * sinang,
                            x * z * cosang1 - y * sinang,
                            0.0,
                            x * y * cosang1 - z * sinang,
                            y * y + (1.0 - y * y) * cosang,
                            y * z * cosang1 + x * sinang,
                            0.0,
                            x * z * cosang1 + y * sinang,
                            y * z * cosang1 - x * sinang,
                            z * z + (1.0 - z * z) * cosang,
                            0.0,
                            0.0, 0.0, 0.0, 1.0);
    return mul (M, p-a) + a;
}
*/

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

// TONEMAPPING FUNCTIONS

inline float3 reinhard(const float3 v)
{
    return v / (1.0f + v);
}

inline float3 reinhard_extended(const float3 v, const float max_white)
{
    const float3 numerator = v * (1.0f + (v / (max_white * max_white)));
    return numerator / (1.0f + v);
}

inline float3 change_luminosity(const float3 c_in, const float l_out)
{
    const float l_in = luminosity(c_in);
    return c_in * (l_out / l_in);
}

inline float3 reinhard_extended_luminance(const float3 v, float max_white_l)
{
    const float l_old = luminosity(v);
    const float numerator = l_old * (1.0f + (l_old / (max_white_l * max_white_l)));
    const float l_new = numerator / (1.0f + l_old);
    return change_luminosity(v, l_new);
}

inline float3 reinhard_jodie(const float3 v)
{
    const float l = luminosity(v);
    const float3 tv = v / (1.0f + v);
    return lerp(v / (1.0f + l), tv, tv);
}

inline float3 uncharted2_tonemap_partial(const float3 x)
{
    const float A = 0.15f;
    const float B = 0.50f;
    const float C = 0.10f;
    const float D = 0.20f;
    const float E = 0.02f;
    const float F = 0.30f;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

inline float3 uncharted2_filmic(const float3 v)
{
    const float exposure_bias = 2.0f;
    const float3 curr = uncharted2_tonemap_partial(v * exposure_bias);

    const float3 W = 11.2f;
    const float3 white_scale = 1.0f / uncharted2_tonemap_partial(W);
    return curr * white_scale;
}

static const float3x3 aces_input_matrix =
{
    0.59719f, 0.35458f, 0.04823f,
    0.07600f, 0.90834f, 0.01566f,
    0.02840f, 0.13383f, 0.83777f
};

static const float3x3 aces_output_matrix =
{
     1.60475f, -0.53108f, -0.07367f,
    -0.10208f,  1.10813f, -0.00605f,
    -0.00327f, -0.07276f,  1.07602f
};

inline float3 rtt_and_odt_fit(float3 v)
{
    const float3 a = v * (v + 0.0245786f) - 0.000090537f;
    const float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

inline float3 aces_fitted(float3 v)
{
    v = mul(aces_input_matrix, v);
    v = rtt_and_odt_fit(v);
    return mul(aces_output_matrix, v);
}

inline float3 aces_approx(float3 v)
{
    v *= 0.6f;
    const float a = 2.51f;
    const float b = 0.03f;
    const float c = 2.43f;
    const float d = 0.59f;
    const float e = 0.14f;
    return saturate((v*(a*v+b))/(v*(c*v+d)+e));
}

inline float3 aces_approx_clamped(float3 v)
{
    return saturate(aces_approx(v));
}

inline float3 optmized_cineon(float3 color)
{
    color = max(float3(0,0,0), color - 0.004);
    return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), float3( 2.2,2.2,2.2 ));
}

// COLOUR SPACE CONVERSIONS
// Thanks poiyomi!

float3 HUEtoRGB(in float H)
{
    const float R = abs(H * 6 - 3) - 1;
    const float G = 2 - abs(H * 6 - 2);
    const float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R,G,B));
}

float3 RGBtoHCV(float3 rgb)
{
    // Based on work by Sam Hocevar and Emil Persson
    const float4 p = (rgb.g < rgb.b) ? float4(rgb.bg, -1.0, 2.0 / 3.0) : float4(rgb.gb, 0.0, -1.0 / 3.0);
    const float4 q = (rgb.r < p.x) ? float4(p.xyw, rgb.r) : float4(rgb.r, p.yzx);
    const float c = q.x - min(q.w, q.y);
    const float h = abs((q.w - q.y) / (6.f * c + czm_epsilon7) + q.z);
    return float3(h, c, q.x);
}
            
float3 RGBToHSL(in float3 RGB)
{
    const float3 HCV = RGBtoHCV(RGB);
    const float L = HCV.z - HCV.y * 0.5f;
    const float S = HCV.y / (1.f - abs(L * 2.f - 1.f) + EPSILON);
    return float3(HCV.x, S, L);
}

float3 HSLtoRGB(in float3 HSL)
{
    const float3 RGB = HUEtoRGB(HSL.x);
    const float C = (1.f - abs(2.f * HSL.z - 1.f)) * HSL.y;
    return (RGB - 0.5f) * C + HSL.z;
}
            
float3 CMYKtoRGB(float4 color)
{
    const float r = ( 1.f - color.x) * ( 1.f - color.w);
    const float g = ( 1.f - color.y) * ( 1.f - color.w);
    const float b = ( 1.f - color.z) * ( 1.f - color.w);
    return float3(r,g,b);
}

float4 RGBtoCMYK(float3 color)
{
    const float k = min(1.f - color.x, min(1.f - color.y, 1.f - color.z));
    const float c = (1.f - color.x - k) / (1.f - k);
    const float m = (1.f - color.y - k) / (1.f - k);
    const float y = (1.f - color.z - k) / (1.f - k);

    return float4(c, m, y, k);
}
float3 hsv2rgb(float x, float y, float z) {    
    return z + z * y * ( clamp ( abs ( fmod ( x * 6.f + float3 ( 0.f, 4.f, 2.f ), 6.f) - 3.f ) - 1.f, 0.f, 1.f ) - 1.f );
}
float3 rgb2hsv(float3 c)
{
    const float4 K = float4(0.f, -1.f / 3.f, 2.f / 3.f, -1.f);
    const float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    const float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    const float d = q.x - min(q.w, q.y);
    const float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.f * d + e)), d / (q.x + e), q.x);
}

#endif // HEKKY_COMMON_UNITY_UTILS