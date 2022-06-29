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
    o.pos = UnityObjectToClipPos(v.vertex);
    o.eyeVec.xyz = normalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    
    // Transform UVs
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv1, _MainTex);
    o.uv1.xy = TRANSFORM_TEX(v.uv2, _MainTex);
    o.uv1.zw = TRANSFORM_TEX(v.uv3, _MainTex);
    
    v.normal = lerp(v.normal, normalize(v.vertex), lerp(0, 0.967, _NormalReprojBlend * LIGHTING_NORMAL_REPROJECTION));

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = mul(unity_ObjectToWorld, v.tangent);
    tangentWorld.w = v.tangent.w;
    float3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w;
    
    o.normal = normalWorld.xyz;
    o.tangent = tangentWorld;
    o.binormal = binormalWorld.xyz;
    o.worldPos = posWorld.xyz;

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

    // Extract shader params into a data structure
    MATERIAL_SETUP(material)
    
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	PATCH_INPUT_DATA(i, frontFace);

    INIT_SHADING_DATA(shadingData);
    
    prepareMaterial(material, shadingData);
    float4 finalCol = evaluateMaterial(shadingData, material);
    
    UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
    UNITY_APPLY_FOG(_unity_fogCoord, finalCol.rgb);

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

    o.pos = UnityObjectToClipPos(v.vertex);
    o.eyeVec.xyz = normalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    
    // Transform UVs
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv1, _MainTex);
    o.uv1.xy = TRANSFORM_TEX(v.uv2, _MainTex);
    o.uv1.zw = TRANSFORM_TEX(v.uv3, _MainTex);

    v.normal = lerp(v.normal, normalize(v.vertex), lerp(0, 0.967, _NormalReprojBlend * LIGHTING_NORMAL_REPROJECTION));

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = mul(unity_ObjectToWorld, v.tangent);
    tangentWorld.w = v.tangent.w;
    float3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w;
    
    o.normal = normalWorld.xyz;
    o.tangent = tangentWorld;
    o.binormal = binormalWorld.xyz;
    o.worldPos = posWorld.xyz;

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

fixed4 fragAdd(v2f i, bool frontFace : SV_IsFrontFace) : SV_Target
{
    float4 finalCol = 0;
    
    UNITY_BRANCH
    if (!LIGHTING_MODE_UNLIT)
    {
        UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

        // Extract shader params into a data structure
        MATERIAL_SETUP(material)
    
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

		PATCH_INPUT_DATA(i, frontFace);

        INIT_SHADING_DATA(shadingData);
    
        // float4 finalCol = 0;
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

    o.eyeVec.xyz = normalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    
    // Transform UVs
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv1, _MainTex);
    o.uv1.xy = TRANSFORM_TEX(v.uv2, _MainTex);
    o.uv1.zw = TRANSFORM_TEX(v.uv3, _MainTex);

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    float3 binormalWorld = cross(normalWorld, tangentWorld) * (v.tangent.w * unity_WorldTransformParams.w);
    
    o.normal = normalWorld.xyz;
    o.tangent = tangentWorld;
    o.binormal = binormalWorld.xyz;
    o.worldPos = posWorld.xyz;

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

        // Extract shader params into a data structure
        MATERIAL_SETUP(material)
    
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        INIT_SHADING_DATA(shadingData);

        prepareMaterial(material, shadingData);
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
