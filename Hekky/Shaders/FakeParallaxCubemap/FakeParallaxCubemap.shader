Shader "Hekky/Fake Parallax Cubemap"
{
    Properties
    {
        // ==================== CORE ====================
        
        [HideInInspector]_Manifest("__;title('Hekky Fake Parallax Cubemap');docsURL('https://docs.hyblocker.dev/en/shaders/hekky-fake-parallax-cubemap/reference')", Float) = 0
        [HideInInspector]_Version("__;version(1.0);", Float) = 1
        
        _Header("__;doHeader;spacing;spacing;", Float) = 0
        _MiscView("__;doTextureFixCollection;", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 2
        _initSpacing("__;spacing;", Int) = 0
        
        // ==================== DATA ====================
        
        _MainTex ("Texture", Cube) = "white" {}
        _Radius ("Radius", Float) = 128
        _Scale ("Scale", Float) = 1
        _CapturePoint ("Capture Point", Vector) = (0,0.9,0,0)
        [ToggleUI] _AltitudeOnly ("Only altitude", Float) = 0
        
        // ==================== FOOTER ====================
        
        _Footer("__;spacing;doRenderQueueField;doInstancingField;doDoubleSidedGIField;doFooter;", Float) = 0
    }
    SubShader
    {
        Tags {
            "Queue"="Background"
            "RenderType"="Background"
            "PerformanceChecks"="False"
            "PreviewType"="Skybox"
            "DisableBatching"="True"
        }
        LOD 300
        Cull [_CullMode]

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 viewDir : TEXCOORD0;
                float3 origin : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            samplerCUBE _MainTex;
            float4 _MainTex_ST;
            float4 _CapturePoint;
            float _Radius;
            float _Scale;
            float _AltitudeOnly;
            
            v2f vert (appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.pos = UnityObjectToClipPos(v.vertex);
                const float3 posWorld = mul(unity_ObjectToWorld, v.vertex);
                const float3 posOrigin = mul(unity_ObjectToWorld, float4(0,0,0,1));
                const float3 eyeDir = posWorld.xyz - _WorldSpaceCameraPos;
                OUT.viewDir = eyeDir;
                OUT.origin = posOrigin;
                return OUT;
            }

            struct HemisphereProjectionParams {
                float3 view;
                float3 cameraPosition;
                float radius;
                float scale;
            };

            float3 getProjectedSkyCoord(HemisphereProjectionParams params)
            {
                params.cameraPosition.xz = params.cameraPosition.xz / params.radius * 0.1f;
                params.cameraPosition.y = min(params.cameraPosition.y, -1.f) * params.scale;
                const float3 planeNormal = float3(0.f, 1.f, 0.f);
                const float rayLength = dot(params.cameraPosition, planeNormal) / dot(params.view, planeNormal);
                const float3 intersectPoint = params.cameraPosition + params.view * rayLength;
                const float3 finalView = normalize(intersectPoint);
                return lerp(finalView, params.view, params.view.y > 0.f);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                const float3 view = normalize(i.viewDir);

                // Compute camera position with capture point offset taken into account
                const float3 cameraPos = (_CapturePoint - _WorldSpaceCameraPos - i.origin) * lerp(1.f, float3(0.f, 1.f, 0.f), _AltitudeOnly);

                HemisphereProjectionParams projectParams = (HemisphereProjectionParams)0;
                projectParams.view              = view;
                projectParams.cameraPosition    = cameraPos;
                projectParams.radius            = _Radius;
                projectParams.scale             = _Scale * 0.01f;

                // Project it onto the floor
                float3 adjustedView = getProjectedSkyCoord(projectParams);
                
                // sample the texture
                return texCUBE(_MainTex, adjustedView);
            }
            ENDCG
        }
    }
    
    CustomEditor "Hekky.HekkyDynamicEditorGUI"
}
