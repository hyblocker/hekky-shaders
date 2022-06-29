#ifndef HEKKY_NOISE
#define HEKKY_NOISE

// PERLIN NOISE
// Adapted from https://github.com/BrianSharpe/GPU-Noise-Lib/blob/master/gpu_noise_lib.glsl

float3 interpolation_c2( float3 x )
{
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

void perlin_hash( float3 gridcell, float s, bool tile,
    out float4 lowz_hash_0,
    out float4 lowz_hash_1,
    out float4 lowz_hash_2,
    out float4 highz_hash_0,
    out float4 highz_hash_1,
    out float4 highz_hash_2 )
{
    const float2 OFFSET = float2( 50.0, 161.0 );
    const float DOMAIN = 69.0;
    const float3 SOMELARGEFLOATS = float3( 635.298681, 682.357502, 668.926525 );
    const float3 ZINC = float3( 48.500388, 65.294118, 63.934599 );

    gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
    float d = DOMAIN - 1.5;
    float3 gridcell_inc1 = step( gridcell, float3( d,d,d ) ) * ( gridcell + 1.0 );

    gridcell_inc1 = tile ? gridcell_inc1 % s : gridcell_inc1;

    float4 P = float4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
    P *= P;
    P = P.xzxz * P.yyww;
    float3 lowz_mod = float3( 1.0 / ( SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz ) );
    float3 highz_mod = float3( 1.0 / ( SOMELARGEFLOATS.xyz + gridcell_inc1.zzz * ZINC.xyz ) );
    lowz_hash_0 = frac( P * lowz_mod.xxxx );
    highz_hash_0 = frac( P * highz_mod.xxxx );
    lowz_hash_1 = frac( P * lowz_mod.yyyy );
    highz_hash_1 = frac( P * highz_mod.yyyy );
    lowz_hash_2 = frac( P * lowz_mod.zzzz );
    highz_hash_2 = frac( P * highz_mod.zzzz );
}

float perlin(float3 P, float s, bool tile)
{
    P *= s;

    const float3 Pi = floor(P);
    const float3 Pi2 = floor(P);
    const float3 Pf = P - Pi;
    const float3 Pf_min1 = Pf - 1.0;

    float4 hashx0, hashy0, hashz0, hashx1, hashy1, hashz1;
    perlin_hash( Pi2, s, tile, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1 );

    const float4 grad_x0 = hashx0 - 0.49999;
    const float4 grad_y0 = hashy0 - 0.49999;
    const float4 grad_z0 = hashz0 - 0.49999;
    const float4 grad_x1 = hashx1 - 0.49999;
    const float4 grad_y1 = hashy1 - 0.49999;
    const float4 grad_z1 = hashz1 - 0.49999;
    const float4 grad_results_0 = rsqrt( grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0 ) * ( float2( Pf.x, Pf_min1.x ).xyxy * grad_x0 + float2( Pf.y, Pf_min1.y ).xxyy * grad_y0 + Pf.zzzz * grad_z0 );
    const float4 grad_results_1 = rsqrt( grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1 ) * ( float2( Pf.x, Pf_min1.x ).xyxy * grad_x1 + float2( Pf.y, Pf_min1.y ).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1 );

    float3 blend = interpolation_c2( Pf );
    const float4 res0 = lerp( grad_results_0, grad_results_1, blend.z );
    float4 blend2 = float4( blend.xy, float2( 1.0 - blend.xy ) );
    float final = dot( res0, blend2.zxzx * blend2.wwyy );
    final *= 1.0 / sqrt(0.75);
    return ((final * 1.5) + 1.0) * 0.5;
}

float perlin(float3 P)
{
    return perlin(P, 1, false);
}

// VORONOI NOISE

float3 voronoi_hash( float3 x, float s)
{
    x = x % s;
    x = float3( dot(x, float3(127.1,311.7, 74.7)),
                dot(x, float3(269.5,183.3,246.1)),
                dot(x, float3(113.5,271.9,124.6)));
				
    return frac(sin(x) * 43758.5453123);
}

float3 voronoi( in float3 x, float s, bool inverted)
{
    x *= s;
    x += 0.5;
    const float3 p = floor(x);
    const float3 f = frac(x);

    float id = 0.0;
    float2 res = float2( 1.0 , 1.0);
    for(int k=-1; k<=1; k++){
        for(int j=-1; j<=1; j++) {
            for(int i=-1; i<=1; i++) {
                float3 b = float3(i, j, k);
                float3 r = float3(b) - f + voronoi_hash(p + b, s);
                float d = dot(r, r);

                if(d < res.x) {
                    id = dot(p + b, float3(1.0, 57.0, 113.0));
                    res = float2(d, res.x);			
                } else if(d < res.y) {
                    res.y = d;
                }
            }
        }
    }

    float2 result = res;
    id = abs(id);

    if (inverted)
        return float3(1.0 - result, id);
    else
        return float3(result, id);
}

// PERLIN-WORLEY NOISE

inline float dilatePerlinWorley(float perlin, float worley, float x)
{
    const float curve = 0.75;
    if(x < 0.5) {
        x = x / 0.5;
        const float n = perlin + worley * x;
        return n * lerp(1, 0.5, pow(x, curve));
    } else {
        x = (x - 0.5) / 0.5;
        const float n = worley + perlin * (1.0 - x);
        return n * lerp(0.5, 1.0, pow(x, 1.0 / curve));
    }
}

#endif // HEKKY_NOISE