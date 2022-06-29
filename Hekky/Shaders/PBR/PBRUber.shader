﻿Shader "Hekky/PBR Uber/Standard"
{
    Properties
    {
        // ==================== CORE ====================
        
        [HideInInspector]_Manifest("__;title('Hekky PBR Uber');docsURL('https://docs.hyblocker.dev/en/shaders/hekky-pbr/reference')", Float) = 0
        [HideInInspector]_Version("__;version(1.1);", Float) = 1
        
        _Header("__;doHeader;spacing;spacing;", Float) = 0
        _MiscView("__;doTextureFixCollection;", Float) = 0
        _BlendModes("Rendering Mode;doBlendMode;", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 2
        _initSpacing("__;spacing;", Int) = 0
        
        // ==================== MAIN ====================
        
        _FoldoutMainBegin("Main; beginFoldout", Float) = 0.0
        
            _Color ("Color; hide; showAlong(_MainTex)", Color) = (1,1,1)
            _MainTex ("Texture; doScaleOffset", 2D) = "white" {}

            [Gamma]_Metallic ("Metal; hide; showAlong(_MetallicGlossMap)", Range(0.0, 1.0)) = 0
            _MetallicGlossMap("Metal Mask; linear", 2D) = "white" {}
            
            _Glossiness ("Roughness; hide; showAlong(_SpecGlossMap)", Range(0.0, 1.0)) = 1
            _SpecGlossMap("Roughness Map; linear", 2D) = "white" {}
            [Toggle(_InvertGlossiness)] _InvertGlossiness("Invert Roughness", Int) = 0

            _BumpScale("Scale; hide; showAlong(_BumpMap)", Range(0.0, 2.0)) = 1.0
            [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        
        _FoldoutMainEnd("__; endFoldout", Float) = 0.0
        
        // ==================== LIGHTING ====================
        
        _FoldoutLightingBegin("Lighting; beginFoldout", Float) = 0.0

            // Enums are numeric, and start from 0 up to N. Default value is obviously default enum value ; enumDefine is a
            // variant of enum which throws the current value as a #define during the pre-optimisation pass like a keyword,
            // without emitting an actual keyword (so as to not add to the global shader keyword limit)
            [Enum(Realistic, 0, Toon, 1, Unlit, 2)]_LightingMode("Lighting Mode", Float) = 0.0
            // _LightingShadowStyleTint("Tint; hideIfNot(_LightingMode, 1); hide; showAlong(_LightingShadowStyleTex)", Color) = (1,1,1)
            // _LightingShadowStyleTex("Shadow Style; hideIfNot(_LightingMode, 1); linear", 2D) = "white" {}
            // Possibly a more verbose variant?
            // _LightingShadowStyleTint("Tint; showAlong(_LightingShadowStyleTex); dependsOn(_LightingMode, 2)", Color) = (1,1,1)
        
            // ==================== TOON LIGHTING ====================

            _FoldoutToonBegin("Toon; hideIfNot(_LightingMode, 1); beginFoldout", Float) = 0.0
            
                _MathGradientStart ("Math Gradient Start; hideIfNot(_LightingMode, 1)", Range(0.0, 1.0)) = 0.0
                _MathGradientEnd ("Math Gradient End; hideIfNot(_LightingMode, 1)", Range(0.0, 1.0)) = 1.0
        
                _ToonMathGradientMinBrightness ("Min Brightness; hideIfNot(_LightingMode, 1)", Range(0, 1.0)) = 0
                _ToonMathGradientMaxBrightness ("Max Brightness; hideIfNot(_LightingMode, 1)", Range(0, 1.0)) = 1

// TODO: Figure out how to make this toggle on/off with toon automagically , im just lazy as shit rn lol
				[ToggleUI] _LightingShadows ("Receive Shadows; hideIfNot(_LightingMode, 1)", Float) = 1

				_FoldoutNormalReprojectionBegin("Normal Reprojection; hideIfNot(_LightingMode, 1); beginFoldout", Float) = 0.0

					[ToggleUI] _EnableNormalReproj ("Enable Normal Reprojection; hideIfNot(_LightingMode, 1)", Float) = 0.0
					_NormalReprojBlend ("Base Normal Blend; hideIfNot(_LightingMode, 1); disableIfNot(_EnableNormalReproj)", Range(0.0, 1.0)) = 1.0

				_FoldoutNormalReprojectionEnd("__; hideIfNot(_LightingMode, 1); endFoldout", Float) = 0.0

            _FoldoutToonEnd("__; hideIfNot(_LightingMode, 1); endFoldout", Float) = 0.0
        
            // ==================== SPECULAR ====================

            _FoldoutSpecularBegin("Specular; beginFoldout", Float) = 0.0
            
                _Specular("Specular", Range(0.0, 1.0)) = 0
                _SpecularTint("Specular Tint", Color) = (1,1,1,1)
        
                _FoldoutAdvancedBegin("Advanced; beginFoldout", Float) = 0.0
                    [ToggleUI]_LightmapSpecular("Baked specular", Float) = 1.0
                _FoldoutAdvancedEnd("__; endFoldout", Float) = 0.0

            _FoldoutSpecularEnd("__; endFoldout", Float) = 0.0
        
            // ==================== REFLECTIONS ====================

            _FoldoutReflectionsBegin("Reflections; beginFoldout", Float) = 0.0
            
                [KeywordEnum(Default, Spherical Projection, Box Projection)]_ReflectionsForcedMode("Force reflections mode", Float) = 0

            _FoldoutReflectionsEnd("__; endFoldout", Float) = 0.0
        
            // ==================== EMISSION ====================

            _FoldoutEmissionBegin("Emission; beginFoldout", Float) = 0.0
            
                [HDR]_EmissionColor ("Emission; hide; showAlong(_EmissionMap)", Color) = (0,0,0)
                _EmissionMap("Emission", 2D) = "white" {}
                _EmissionIntensity("Intensity", Range(0.0, 10.0)) = 1.0 
            
                _FoldoutEmissionAudioLinkBegin("AudioLink; beginFoldout", Float) = 0.0
            
                    [Enum(Hekky.AudioLinkChannels)] _EmissionAudioLinkMultiplyChannel("Multiply Channel; hideIfNot(_AudioLink); requireAudioLink", Float) = 0.0
                    _EmissionAudioLinkMultiplyRange ("Range; slider(X, 0, 10, Min Multiply Emission); slider(Y, 0, 10, Max Multiply Emission); hideIfNot(_AudioLink); requireAudioLink", Vector) = (0,1,0,0)
                    [Enum(Hekky.AudioLinkChannels)] _EmissionAudioLinkAddChannel("Add Channel; hideIfNot(_AudioLink); requireAudioLink", Float) = 0.0
                    _EmissionAudioLinkAddRange ("Range; slider(X, 0, 50, Min Add Emission); slider(Y, 0, 50, Max Add Emission); hideIfNot(_AudioLink); requireAudioLink", Vector) = (0,0,0,0)
            
                _FoldoutEmissionAudioLinkEnd("__; endFoldout", Float) = 0.0

            _FoldoutEmissionEnd("__; endFoldout", Float) = 0.0
        
            // ==================== MATCAP ====================

            _FoldoutMatcapBegin("Matcap; beginFoldout", Float) = 0.0
            
                [ToggleUI]_DoMatcap("Enable Matcap", Int) = 0
                _MatcapTex("Texture; linear; hideIfNot(_DoMatcap)", 2D) = "white" {}
                _MatcapMask("Mask; linear; hideIfNot(_DoMatcap)", 2D) = "white" {}
                _MatcapBorder("Border; hideIfNot(_DoMatcap)", Range(0.0,0.5)) = 0
        
                _MatcapReplaceBlend("Replace; hideIfNot(_DoMatcap)", Range(0.0,1.0)) = 1
                _MatcapAddBlend("Add; hideIfNot(_DoMatcap)", Range(0.0,1.0)) = 0
                _MatcapDifferenceBlend("Difference; hideIfNot(_DoMatcap)", Range(0.0,1.0)) = 0
                _MatcapMultiplyBlend("Multiply; hideIfNot(_DoMatcap)", Range(0.0,1.0)) = 0
                _MatcapOverlayBlend("Overlay; hideIfNot(_DoMatcap)", Range(0.0,1.0)) = 0
                _MatcapReflectionBlend("Reflection Blend; hideIfNot(_DoMatcap)", Range(0.0,1.0)) = 1

            _FoldoutMatcapEnd("__; endFoldout", Float) = 0.0
        
        _FoldoutLightingEnd("__; endFoldout", Float) = 0.0
        
        // ==================== OCCLUSION ====================

        _FoldoutOcclusionBegin("Occlusion; beginFoldout", Float) = 0.0
        
            _OcclusionStrength("Strength; hide; showAlong(_OcclusionMap)", Range(0.0, 1.0)) = 1.0
            _OcclusionMap ("Ambient Occlusion; linear", 2D) = "white" {}
            _ExposureOcclusion ("Exposure Occlusion", Range(0.0, 1.0)) = 0.2

        _FoldoutOcclusionEnd("__; endFoldout", Float) = 0.0
        
        // ==================== OUTLINE ====================

        _FoldoutOutlineBegin("Outline; beginFoldout", Float) = 0.0
            
            [ToggleUI]_DoOutline("Enable Outline;pass(OUTLINE)", Int) = 0
            _OutlineWidth("Outline Width", Range(0.0, 1.0)) = 0
            _OutlineColor("Outline Color", Color) = (0,0,0)

        _FoldoutOutlineEnd("__; endFoldout", Float) = 0.0
        
        // ==================== AUDUIOLINK DEBUG ====================
        _FoldoutAudioLinkDebugBegin("AudioLink Debug; beginFoldout", Float) = 0.0
            
            [ToggleUI] _AudioLinkDebug("Enable Debug Mode; disableIfNot(_AudioLink); hideIfNot(_AudioLink); requireAudioLink", float) = 0
            _AudioLinkDebugBass("Bass; disableIfNot(_AudioLinkDebug); disableIfNot(_AudioLink); hideIfNot(_AudioLink); requireAudioLink", Range(0.0, 1.0)) = 0
            _AudioLinkDebugLowMid("Low Mid; disableIfNot(_AudioLinkDebug); disableIfNot(_AudioLink); hideIfNot(_AudioLink); requireAudioLink", Range(0.0, 1.0)) = 0
            _AudioLinkDebugHighMid("High Mid; disableIfNot(_AudioLinkDebug); disableIfNot(_AudioLink); hideIfNot(_AudioLink); requireAudioLink", Range(0.0, 1.0)) = 0
            _AudioLinkDebugTreble("Treble; disableIfNot(_AudioLinkDebug); disableIfNot(_AudioLink); hideIfNot(_AudioLink); requireAudioLink", Range(0.0, 1.0)) = 0
            
        _FoldoutAudioLinkDebugEnd("__; endFoldout", Float) = 0.0
        
        // ==================== EXTERNALS ====================
        
        _FoldoutExternalModulesBegin("Other modules; beginFoldout", Float) = 0.0
         
            [Enum(None, 0, SH, 1, RNM, 2)] _Bakery ("Bakery Mode; requireBakery", Int) = 0
                _RNM0("RNM0; requireBakery; disable", 2D) = "black" {}
                _RNM1("RNM1; requireBakery; disable", 2D) = "black" {}
                _RNM2("RNM2; requireBakery; disable", 2D) = "black" {}

            [Toggle(_LTCGI)] _LTCGI ("LTCGI; requireLTCGI", Int) = 0
            [Toggle(_AUDIOLINK)] _AudioLink ("AudioLink; requireAudioLink", Int) = 0
            
            [NonModifiableTextureData][NoScaleOffset][HideInInspector] _DFG("DFG", 2D) = "white" {}

        _FoldoutExternalModulesEnd("__; endFoldout", Float) = 0.0
        
        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _ZTest ("__zt", Float) = 1.0
        
        // ==================== FOOTER ====================
        
        _Footer("__;spacing;doRenderQueueField;doInstancingField;doDoubleSidedGIField;doFooter;", Float) = 0
    }
    
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "PerformanceChecks"="False"
            "LTCGI" = "_LTCGI"
        }
        
        LOD 300
        Cull [_CullMode]

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode"="ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 5.0
            
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SPECGLOSSMAP
            #pragma shader_feature_local _PARALLAXMAP
            
            #pragma shader_feature_local _ _BAKERY_RNM _BAKERY_SH
            #pragma shader_feature_local _LTCGI
            #pragma shader_feature_local _AUDIOLINK
            #pragma shader_feature_local _REFLECTIONSFORCEDMODE_DEFAULT _REFLECTIONSFORCEDMODE_SPHERICAL_PROJECTION _REFLECTIONSFORCEDMODE_BOX_PROJECTION
            
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            // #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "PBRUberDefines.cginc"
            
            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode"="ForwardAdd" }

            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 5.0

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SPECGLOSSMAP
            #pragma shader_feature_local _PARALLAXMAP
            
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            // #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "PBRUberDefines.cginc"
            
            ENDCG
        }

        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode"="ForwardBase" }
            Cull Front
            ZWrite Off

            CGPROGRAM
            #pragma target 5.0

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SPECGLOSSMAP
            #pragma shader_feature_local _PARALLAXMAP
            
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            // #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertOutline
            #pragma fragment fragOutline

            #define OUTLINE 1
            
            #include "PBRUberDefines.cginc"
            
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On ZTest LEqual
            
            CGPROGRAM
            #pragma target 3.0
            
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SPECGLOSSMAP
            #pragma shader_feature_local _PARALLAXMAP
            
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #include "PBRUberDefines.cginc"
            ENDCG
        }
        
        // Deferred not implemented
        UsePass "Standard/DEFERRED"

        // Meta not implemented
        UsePass "Standard/META"
    }
    
    CustomEditor "Hekky.HekkyDynamicEditorGUI"
}