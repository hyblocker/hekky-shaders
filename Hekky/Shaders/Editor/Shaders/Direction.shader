Shader "Hidden/PropertyDrawers/Direction"
{
    Properties
    {
        _Direction("Direction", Vector) = (1, 0, 0, 0)
    }
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

            float4 _Direction;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 normal : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal.xyz);
                float3 light = normalize(_Direction.xyz) * float3(1.f, -1.f, 1.f);
                float atten =  saturate(dot(normal, light));
                float4 ambient = float4((0.1f).xxx, 1.f);
                fixed4 color = lerp(ambient, 1.f, atten);
                return color;
            }
            ENDCG
        }
    }
}
