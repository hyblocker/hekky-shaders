Shader "Hidden/Hekky/Scene View Studio Mode"
{
    Properties {}
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 clipPos          : SV_POSITION;
                float3 viewSpaceNormal : TEXCOORD0;
                float3 worldSpacePos    : TEXCOORD1;
                float2 uv               : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata_full v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.viewSpaceNormal =  mul((float3x3)UNITY_MATRIX_V, UnityObjectToWorldNormal(v.normal));
                o.worldSpacePos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            struct Light
            {
                float3 diffuse;
                float3 specular;
                float smoothness;
                float3 direction;
            };

            // very simplified lighting functionm not physically based, designed solely to make telling geometry apart easier
            float3 lighting(Light light, float3 N, float3 V)
            {
                const float3 H = normalize(light.direction + V);
    
                const float NdotV = saturate(dot(N, V));
                const float NdotL = saturate(dot(N, light.direction));
                const float NdotH = saturate(dot(N, H));
                const float LdotH = saturate(dot(light.direction, H));
                
                const float attenuation = NdotL;
                const float specAttenuation = pow(NdotH, 1.f - light.smoothness);

                const float3 Fr = (light.specular * specAttenuation);
                const float3 Fd = (light.diffuse * attenuation);

                return Fd + Fr;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // declare lights::
                Light Light0 = (Light)0;
                Light0.diffuse = float3(0.033, 0.033, 0.033);
                Light0.specular = float3(0.267, 0.267, 0.267);
                Light0.direction = normalize(float3(0.474, -0.881, -0.005));
                Light0.smoothness = 0.527;
                
                Light Light1 = (Light)0;
                Light1.diffuse = float3(0.447, 0.447, 0.447);
                Light1.specular = float3(0.511, 0.511, 0.511);
                Light1.direction = normalize(float3(-0.407, 0.847, 0.342));
                Light1.smoothness = 0;

                // "BRDF"
                float3 lightColor   = 0;
                lightColor   +=  lighting(Light0, i.viewSpaceNormal, float3(0,0,1));
                lightColor          += lighting(Light1, i.viewSpaceNormal, float3(0,0,1));
                
                const float4 col = tex2D(_MainTex, i.uv); // literally only to grab the alpha channel
                return float4(lightColor * 0.8, col.a);
            }
            ENDCG
        }
    }
}
