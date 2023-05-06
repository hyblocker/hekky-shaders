#ifndef HEKKY_PBR_UBER_PASSES
#define HEKKY_PBR_UBER_PASSES

#if FORWARD_BASE

v2f vertBase(appdata v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    
    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            o.tangentToWorldAndPackedData[0].w = posWorld.x;
            o.tangentToWorldAndPackedData[1].w = posWorld.y;
            o.tangentToWorldAndPackedData[2].w = posWorld.z;
        #else
            o.posWorld = posWorld.xyz;
        #endif
    #endif
    o.eyeVec.xyz = posWorld.xyz - _WorldSpaceCameraPos;
    
    #if _INFINITEFAR_ON
        // This is a hack to force the far plane to infinity regardless of what the user does. This effictively is a hack since unity does not
        // support infinite perspective matrices since it ends up dividing by zero and crashing
        float4x4 INF_PERSPECTIVE = UNITY_MATRIX_P;
        if (INF_PERSPECTIVE._m20 == 0 && INF_PERSPECTIVE._m21 == 0) {
            // Regular perspective projection matrix
            INF_PERSPECTIVE._m22 = 0.f;
            INF_PERSPECTIVE._m23 = _ProjectionParams.y;
        };
        o.pos = mul(INF_PERSPECTIVE, mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0))));
    #else
        o.pos = UnityObjectToClipPos(v.vertex);
    #endif
    
    // Transform UVs
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv1, _MainTex);
    o.uv1.xy = TRANSFORM_TEX(v.uv2, _MainTex);
    o.uv1.zw = TRANSFORM_TEX(v.uv3, _MainTex);
    
    v.normal = lerp(v.normal, normalize(v.vertex), lerp(0, 0.967, _NormalReprojBlend * LIGHTING_NORMAL_REPROJECTION));

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];

    // Required to receive shadows
    UNITY_TRANSFER_LIGHTING(o, v.uv1);
    o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
    
    #ifdef _TANGENT_TO_WORLD
        // TODO: Normal map self shadow
    #endif

    #if defined(HAS_ATTRIBUTE_COLOR)
        o.color = v.color;
    #endif
    
    UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o,o.pos);
    return o;
}

fixed4 fragBase(v2f i, bool frontFace : SV_IsFrontFace) : SV_Target
{
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    // Extract shader params into a data structure
    INIT_SHADING_DATA(shadingData);
    MATERIAL_SETUP(material, shadingData)
    
    prepareMaterial(material, shadingData, frontFace);

    if (_Mode == 1) {
        clip(material.alpha - _AlphaClip);
    }
    float4 finalCol = evaluateMaterial(shadingData, material);
    
    UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
    UNITY_APPLY_FOG(_unity_fogCoord, finalCol.rgb);

    // return float4(shadingData.normal, 1);

    // HekkyPresent(finalCol, i);
    // #pragma multi_compile _ UNITY_HDR_ON

    // and then check for HDR with
    // #ifdef UNITY_HDR_ON
    // ...
    // #endif

    return finalCol;
}

#endif

#if FORWARD_ADD

v2f vertAdd(appdata v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            o.tangentToWorldAndPackedData[0].w = posWorld.x;
            o.tangentToWorldAndPackedData[1].w = posWorld.y;
            o.tangentToWorldAndPackedData[2].w = posWorld.z;
        #else
            o.posWorld = posWorld.xyz;
        #endif
    #endif
    o.eyeVec.xyz = posWorld.xyz - _WorldSpaceCameraPos;
    
    #if _INFINITEFAR_ON
        // This is a hack to force the far plane to infinity regardless of what the user does. This effictively is a hack since unity does not
        // support infinite perspective matrices since it ends up dividing by zero and crashing
        float4x4 INF_PERSPECTIVE = UNITY_MATRIX_P;
        if (INF_PERSPECTIVE._m20 == 0 && INF_PERSPECTIVE._m21 == 0) {
            // Regular perspective projection matrix
            INF_PERSPECTIVE._m22 = 0.f;
            INF_PERSPECTIVE._m23 = _ProjectionParams.y;
        };
        o.pos = mul(INF_PERSPECTIVE, mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0))));
    #else
        o.pos = UnityObjectToClipPos(v.vertex);
    #endif
    
    // Transform UVs
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv1, _MainTex);
    o.uv1.xy = TRANSFORM_TEX(v.uv2, _MainTex);
    o.uv1.zw = TRANSFORM_TEX(v.uv3, _MainTex);

    v.normal = lerp(v.normal, normalize(v.vertex), lerp(0, 0.967, _NormalReprojBlend * LIGHTING_NORMAL_REPROJECTION));

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
    
   // // Required to receive shadows
   // UNITY_TRANSFER_LIGHTING(o, v.uv1);
    o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
    
    #ifdef _TANGENT_TO_WORLD
        // TODO: Normal map self shadow
    #endif

    #if defined(HAS_ATTRIBUTE_COLOR)
        o.color = v.color;
    #endif

    UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o,o.pos);
    return o;
}

fixed4 fragAdd(v2f i, bool frontFace : SV_IsFrontFace) : SV_Target
{
    float4 finalCol = 0;
    
    UNITY_BRANCH
    if (!LIGHTING_MODE_UNLIT)
    {
        UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        // Extract shader params into a data structure
        INIT_SHADING_DATA(shadingData);
        MATERIAL_SETUP(material, shadingData)
        
        prepareMaterial(material, shadingData, frontFace);
        if (_Mode == 1) {
            clip(material.alpha - _AlphaClip);
        }
        finalCol = evaluateMaterial(shadingData, material);
    
        UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
        UNITY_APPLY_FOG_COLOR(_unity_fogCoord, finalCol.rgb, half4(0,0,0,0));

    } else {
        clip(-1);
    }

    return finalCol;
}

#endif

#if OUTLINE

v2f vertOutline(appdata v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);

    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            o.tangentToWorldAndPackedData[0].w = posWorld.x;
            o.tangentToWorldAndPackedData[1].w = posWorld.y;
            o.tangentToWorldAndPackedData[2].w = posWorld.z;
        #else
            o.posWorld = posWorld.xyz;
        #endif
    #endif
    o.eyeVec.xyz = posWorld.xyz - _WorldSpaceCameraPos;
    
    #if _INFINITEFAR_ON
        // This is a hack to force the far plane to infinity regardless of what the user does. This effictively is a hack since unity does not
        // support infinite perspective matrices since it ends up dividing by zero and crashing
        float4x4 INF_PERSPECTIVE = UNITY_MATRIX_P;
        if (INF_PERSPECTIVE._m20 == 0 && INF_PERSPECTIVE._m21 == 0) {
            // Regular perspective projection matrix
            INF_PERSPECTIVE._m22 = 0.f;
            INF_PERSPECTIVE._m23 = _ProjectionParams.y;
        };
        o.pos = mul(INF_PERSPECTIVE, mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0))));
    #else
        o.pos = UnityObjectToClipPos(v.vertex);
    #endif
    
    
    // Transform UVs
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv1, _MainTex);
    o.uv1.xy = TRANSFORM_TEX(v.uv2, _MainTex);
    o.uv1.zw = TRANSFORM_TEX(v.uv3, _MainTex);

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];

    // Required to receive shadows
    UNITY_TRANSFER_LIGHTING(o, v.uv1);
    o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
    
    #ifdef _TANGENT_TO_WORLD
        // TODO: Normal map self shadow
    #endif

    #if defined(HAS_ATTRIBUTE_COLOR)
        o.color = v.color;
    #endif

    o.pos = UnityObjectToClipPos(v.vertex);
    // UnityObjecToClipPos doesn't work for normals, so we have to multiple by a simplified MVP matrix ourselves.
    float3 normalClipSpace = normalize(mul((float3x3) UNITY_MATRIX_IT_MV, v.normal));
    normalClipSpace.x *= UNITY_MATRIX_P[0][0];
    normalClipSpace.y *= UNITY_MATRIX_P[1][1];
    o.pos.xy += normalClipSpace.xy * _OutlineWidth * 0.001f;
    
    UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o,o.pos);
    return o;
}

fixed4 fragOutline(v2f i, bool frontFace : SV_IsFrontFace) : SV_Target
{
    float4 finalCol = 0;
    
    UNITY_BRANCH
    if (OUTLINE_ENABLED)
    {
        UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        // Extract shader params into a data structure
        INIT_SHADING_DATA(shadingData);
        MATERIAL_SETUP(material, shadingData)

        prepareMaterial(material, shadingData, frontFace);
        if (_Mode == 1) {
            clip(material.alpha - _AlphaClip);
        }
        finalCol = evaluateOutline(shadingData, material);
    
        UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
        UNITY_APPLY_FOG(_unity_fogCoord, finalCol.rgb);

    } else {
        clip(-1);
    }
    return finalCol;
}

#endif

#if SHADOW_CASTER
            
v2f vertShadow(appdata v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    TRANSFER_SHADOW_CASTER(o)
    return o;
}
            
float4 fragShadow(v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    SHADOW_CASTER_FRAGMENT(i)
}

#endif

#endif // HEKKY_PBR_UBER_PASSES
