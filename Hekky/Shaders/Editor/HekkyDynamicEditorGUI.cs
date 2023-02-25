using log4net.Filter;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace Hekky {
    /// <summary>
    /// A shader GUI conforming to the spec outlined in ShaderEditorSpec.md
    /// </summary>
    public class HekkyDynamicEditorGUI : ShaderGUI {
        private const char PROPERTY_SEPARATOR = ';';

        #region External Module Detection

        // I don't use the #defines as due to how hacky setting them is they don't get removed if the user deletes a package
        // So instead we query the asset database for the existence of some crucial file and assume the whole package is present if that's the case

        /// <summary>
        /// Whether Bakery is found in the current project
        /// </summary>
        private bool BAKERY_AVAILABLE => HGUI.BakeryImported;

        /// <summary>
        /// Whether LTCGI is found in the current project
        /// </summary>
        private bool LTCGI_AVAILABLE => HGUI.LTCGIImported;

        /// <summary>
        /// Whether AudioLink is found in the current project
        /// </summary>
        private bool AUDIOLINK_AVAILABLE => HGUI.AudioLinkImported;

        #endregion

        #region UI Textures

        private Texture2D iconPatreonDark   = HekkyUtil.FetchTexture2DByName("btn-patreon-dark");
        private Texture2D iconDocsDark      = HekkyUtil.FetchTexture2DByName("btn-docs-dark");
        private Texture2D iconDiscordDark   = HekkyUtil.FetchTexture2DByName("btn-discord-dark");
        private Texture2D iconSearchDark    = HekkyUtil.FetchTexture2DByName("btn-search-dark");

        private Texture2D iconPatreonLight   = HekkyUtil.FetchTexture2DByName("btn-patreon-light");
        private Texture2D iconDocsLight      = HekkyUtil.FetchTexture2DByName("btn-docs-light");
        private Texture2D iconDiscordLight   = HekkyUtil.FetchTexture2DByName("btn-discord-light");
        private Texture2D iconSearchLight    = HekkyUtil.FetchTexture2DByName("btn-search-light");

        private Texture2D iconPatreon   { get { return EditorGUIUtility.isProSkin ? iconPatreonLight : iconPatreonDark; } }
        private Texture2D iconDocs      { get { return EditorGUIUtility.isProSkin ? iconDocsLight : iconDocsDark; } }
        private Texture2D iconDiscord   { get { return EditorGUIUtility.isProSkin ? iconDiscordLight : iconDiscordDark; } }
        private Texture2D iconSearch    { get { return EditorGUIUtility.isProSkin ? iconSearchLight : iconSearchDark; } }

        #endregion

        private Dictionary<string, HekkyShaderPropertyContainer> propertyMap;

        // private Dictionary<string, MaterialProperty> propertyMap;
        private HekkyMaterialProperty[] hekkyProps;
        private string version, title, docsURL;
        private MaterialProperty BlendModeUnityProp;
        private MaterialEditor materialEditor;
        private Material material;
        private Queue<HekkyShaderFoldout> foldoutQueue = new Queue<HekkyShaderFoldout>();
        private int foldoutsToClose;

        private Dictionary<int, MaterialProperty> incorrectlyConfiguredTextureCount =
            new Dictionary<int, MaterialProperty>();

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
            // TODO: Cache parsed props if possible
            // TODO: Multi-material edit

            propertyMap = RawPropsToLut(properties);
            version = "";
            material = ( Material ) materialEditor.target;
            title = material.shader.name;
            this.materialEditor = materialEditor;
            foldoutQueue.Clear();
            foldoutsToClose = 0;
            incorrectlyConfiguredTextureCount.Clear();

            hekkyProps = ParsePropertiesToFoldout(properties).materialProperties;
            BlendModeUnityProp = FindProperty("_Mode", properties, false);

            for ( int i = 0; i < hekkyProps.Length; i++ ) {
                if ( hekkyProps[i].properties == null )
                    Debug.LogError(
                        $"Prop {hekkyProps[i].displayName} {hekkyProps[i].unityInternalProperty.displayName} was null!");
                for ( int j = 0; j < hekkyProps[i].properties.Length; j++ ) {
                    // Shorthands
                    var currentProp = hekkyProps[i];
                    var currentToken = currentProp.properties[j];

                    try {
                        switch ( hekkyProps[i].properties[j].propertyType ) {
                            case HekkyShaderProperty.Title:
                                title = currentToken.values[0] as string;
                                break;
                            case HekkyShaderProperty.DocsURL:
                                docsURL = currentToken.values[0] as string;
                                break;
                            case HekkyShaderProperty.Version:
                                version = currentToken.values[0] as string;
                                break;
                        }
                    } catch ( Exception err ) {
                        Debug.LogError(
                            $"Failed to parse property \"{currentToken.propertyRaw}\" in {currentProp.unityInternalProperty.name}!");
                        Debug.LogException(err);
                    }
                }
            }

            RenderPropsRecursive(hekkyProps);

#if HEKKY_DBG
            if ( HGUI.CollapsingHeader("Default inspector") ) {
                HGUI.BeginGroup();
                base.OnGUI(materialEditor, properties);
                HGUI.EndGroup();
            }
#endif
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader) {
            // // Some shaders store emission color in the _Emission prop
            // if (material.HasProperty("_Emission"))
            // {
            //     material.SetColor("_EmissionColor", material.GetColor("_Emission"));
            // }
            // 
            base.AssignNewShaderToMaterial(material, oldShader, newShader);
            // 
            // // Detect if the shader is using metallic roughness workflow
            // // TODO: Autodetect
            // 
            // 
            // // Preserve blend mode
            // HGUI.BlendMode blendmode = HGUI.BlendMode.Opaque;
            // 
            // UpdateKeywords(material);
            // SetBlendMode(material, (HGUI.BlendMode)material.GetFloat("_Mode"), true);

            // @HACK: Until I rewrite this later to work agnostically and not be hardcoded
            if ( material.HasProperty("_SSREnabled") ) {
                material.GetFloat("_SSREnabled");
            }
        }

        #region Render GUI

        private void DoGroupedWarningsContainer() {
            if ( incorrectlyConfiguredTextureCount.Count > 0 ) {
                if ( HGUI.TextureImportWarningBox(incorrectlyConfiguredTextureCount.Count == 1
                    ? "There is a texture with incorrect import settings on this material."
                    : "There are multiple textures with incorrect import settings on this material."
                ) ) {
                    for ( int i = 0; i < incorrectlyConfiguredTextureCount.Count; i++ ) {
                        var prop = incorrectlyConfiguredTextureCount[i];
                        string texPath = AssetDatabase.GetAssetPath(prop.textureValue);
                        var importer = AssetImporter.GetAtPath(texPath) as TextureImporter;

                        // if the texture type is NORMAL MAP
                        if ( HekkyUtil.TestBitwiseFlag(prop.flags, MaterialProperty.PropFlags.Normal) ) {
                            if ( importer != null && importer.textureType != TextureImporterType.NormalMap ) {
                                importer.textureType = TextureImporterType.NormalMap;
                                importer.SaveAndReimport();
                            }
                        } else {
                            // Assume it's linear
                            if ( importer != null && importer.sRGBTexture ) {
                                importer.sRGBTexture = false;
                                importer.SaveAndReimport();
                            }
                        }
                    }
                }

                // Small amount of padding to make the UI look clean
                HGUI.Spacing();
            }
        }

        private void DoHeader() {
            HGUI.Title(title);
            HGUI.Version(version);
        }

        private void DoFooter() {
            HGUI.Footer();
            DoSocialButtons();
        }

        private void DoSocialButtons() {
            HGUI.Spacing();
            GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();

            if ( GUILayout.Button(new GUIContent(iconPatreon, "Patreon"), HGUI.IconButton) ) {
                Process.Start(HekkyConstants.PatreonURL);
            }

            if ( GUILayout.Button(new GUIContent(iconDocs, "Documentation"), HGUI.IconButton) ) {
                // Process.Start(HekkyConstants.DocumentationURL);
                Process.Start(docsURL);
            }

            if ( GUILayout.Button(new GUIContent(iconDiscord, "Discord Server"), HGUI.IconButton) ) {
                Process.Start(HekkyConstants.DiscordURL);
            }

            GUILayout.FlexibleSpace();
            GUILayout.EndHorizontal();
        }

        private void DoBlendMode(MaterialProperty blendModeProp, string displayName) {
            EditorGUI.BeginChangeCheck();
            bool blendModeChanged = BlendModePopup(blendModeProp, displayName);
            if ( EditorGUI.EndChangeCheck() ) {
                foreach ( var obj in blendModeProp.targets ) {
                    var currMaterial = ( Material ) obj;
                    SetBlendMode(currMaterial, ( HGUI.BlendMode ) currMaterial.GetFloat(Mode), blendModeChanged);
                }
            }

            UpdateKeywords(material);
        }

        private float DoSlider(string name, float value, float min, float max) {
            // GUILayoutOption clickArea = GUILayout.MaxWidth(EditorGUIUtility.labelWidth);
            Rect clickRect = GUILayoutUtility.GetRect(EditorGUIUtility.labelWidth, 18f);
            return EditorGUI.Slider(clickRect, name, value, min, max);
            // EditorGUI.Slider(Rect position, string label, float value, float leftValue, float rightValue);
            // materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent(prop.displayName), prop.unityInternalProperty);
        }

        private void LinearWarning(MaterialProperty prop) {
            string sRGBWarning = "This texture is marked as sRGB, but should be linear";
            string texPath = AssetDatabase.GetAssetPath(prop.textureValue);
            var importer = AssetImporter.GetAtPath(texPath) as TextureImporter;
            if ( importer != null && importer.sRGBTexture && HGUI.TextureImportWarningBox(sRGBWarning) ) {
                importer.sRGBTexture = false;
                importer.SaveAndReimport();
            }
        }

        private bool EnsureFoldoutIsRendered() {
            if ( foldoutQueue.Count > 0 ) {
                var foldout = foldoutQueue.Peek();
                bool doFoldout = HGUI.CollapsingHeader(foldout.displayName);
                foldout.unityInternalProperty.floatValue = doFoldout ? 1 : 0;
                if ( foldout.unityInternalProperty.floatValue == 1.0f ) {
                    foldoutQueue.Dequeue();
                    HGUI.BeginGroup();
                    foldoutsToClose++;
                }

                return !doFoldout;
            }

            return false;
        }
        
        private void DrawTextureWithOtherProp(GUIContent content, MaterialProperty textureProp, HekkyMaterialProperty inlineProp) {
            
            EditorGUILayout.BeginHorizontal();
            // If this texture is a normal map, FUCK
            if ( ( textureProp.flags & MaterialProperty.PropFlags.Normal ) != 0 ) {
                materialEditor.TexturePropertySingleLine(content, textureProp, inlineProp.unityInternalProperty);
            } else {
                materialEditor.TexturePropertySingleLine(content, textureProp, inlineProp.unityInternalProperty);
            }
            var mainRect = GUILayoutUtility.GetLastRect();
            var rect = EditorGUILayout.GetControlRect(GUILayout.Width(14), GUILayout.Height(11), GUILayout.ExpandHeight(true));
            rect.y = mainRect.yMax - rect.height;
            if (GUI.Button(rect, HGUI.UndoArrowContent, HGUI.UndoButton)) {
                materialEditor.RegisterPropertyChangeUndo("Reset value");
                switch ( inlineProp.unityInternalProperty.type ) {
                    case MaterialProperty.PropType.Vector:
                        Vector4 defaultVector = material.shader.GetPropertyDefaultVectorValue(inlineProp.index);
                        inlineProp.unityInternalProperty.vectorValue = defaultVector;
                        break;
                    case MaterialProperty.PropType.Color:
                        Vector4 defaultColor = material.shader.GetPropertyDefaultVectorValue(inlineProp.index);
                        inlineProp.unityInternalProperty.colorValue = new Color(defaultColor.x, defaultColor.y, defaultColor.z, defaultColor.w);
                        break;
                    case MaterialProperty.PropType.Range:
                    case MaterialProperty.PropType.Float:
                        float defaultValue = material.shader.GetPropertyDefaultFloatValue(inlineProp.index);
                        inlineProp.unityInternalProperty.floatValue = defaultValue;
                        break;
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        // Thanks orels1 for the reset button!
        private bool DrawPropInternal(HekkyMaterialProperty prop) {
            bool ignoreProp = HekkyUtil.TestBitwiseFlag(prop.unityInternalProperty.flags,
                MaterialProperty.PropFlags.HideInInspector);
            ignoreProp |= HekkyUtil.TestBitwiseFlag(prop.unityInternalProperty.flags,
                MaterialProperty.PropFlags.NonModifiableTextureData);

            bool disabled = false;
            bool doUVScaleOffsetBlock = false;
            bool doLinearProp = false;

            float lastValue_Float = 0.0f;
            Vector4 lastValue_Vec4 = Vector4.zero;
            Color lastValue_Color = Color.black;
            Texture lastValue_Texture = null;
            bool valueChanged = false;

            // Range slider
            byte sliderCount = 0;
            byte[] sliderComponent = new byte[4];
            string[] sliderNames = {"", "", "", ""};
            Vector2[] sliderRange = new Vector2[4];

            // Min max
            Vector2 minMaxRange = Vector2.zero;
            bool doMinMax = false;

            string toggleTypeSignature = string.Empty;
            string toggleMethodSignature = string.Empty;

            for ( int i = 0; i < prop.properties.Length; i++ ) {
                switch ( prop.properties[i].propertyType ) {
                    case HekkyShaderProperty.Hide:
                        ignoreProp = true;
                        break;
                    case HekkyShaderProperty.HideIfNot:
                        // Check args, and hide if not true
                        if ( !( Math.Abs(propertyMap[( string ) prop.properties[i].values[0]].property.floatValue -
                                         float.Parse(( string ) prop.properties[i].values[1])) < 0.01f ) )
                            ignoreProp = true;
                        break;
                    case HekkyShaderProperty.DisableIfNot:
                        // Check args, and disable if not true
                        if ( !( Math.Abs(propertyMap[( string ) prop.properties[i].values[0]].property.floatValue -
                                         float.Parse(( string ) prop.properties[i].values[1])) < 0.01f ) )
                            disabled = true;
                        break;
                    case HekkyShaderProperty.Disable:
                        disabled = true;
                        break;
                    case HekkyShaderProperty.DoScaleOffset:
                        doUVScaleOffsetBlock = true;
                        break;
                    case HekkyShaderProperty.LinearWarning:
                        doLinearProp = true;
                        break;
                    case HekkyShaderProperty.Slider:

                        // Convert X,Y,Z,W into an index
                        byte knownComponentIndex = 255;
                        switch ( ( ( string ) prop.properties[i].values[0] ).ToLowerInvariant() ) {
                            case "x":
                                knownComponentIndex = 0;
                                break;
                            case "y":
                                knownComponentIndex = 1;
                                break;
                            case "z":
                                knownComponentIndex = 2;
                                break;
                            case "w":
                                knownComponentIndex = 3;
                                break;
                        }

                        if ( knownComponentIndex == 255 ) {
                            Debug.LogError($"Unknown vector component {( ( string ) prop.properties[i].values[0] )}!");
                        }

                        sliderComponent[sliderCount] = knownComponentIndex;

                        float sliderMin = 0;
                        float sliderMax = 1;

                        // Has min
                        if ( prop.properties[i].values.Length > 1 ) {
                            sliderMin = float.Parse(( string ) prop.properties[i].values[1]);
                        }

                        // Has max
                        if ( prop.properties[i].values.Length > 2 ) {
                            sliderMax = float.Parse(( string ) prop.properties[i].values[2]);
                        }

                        // Has custom name
                        if ( prop.properties[i].values.Length > 3 ) {
                            sliderNames[i] = prop.properties[i].values[3].ToString().Trim();
                        }

                        sliderRange[sliderCount] = new Vector2(sliderMin, sliderMax);

                        sliderCount++;
                        break;

                    case HekkyShaderProperty.MinMax:
                        doMinMax = true;

                        float minVal = 0;
                        float maxVal = 1;

                        float.TryParse(( string ) prop.properties[i].values[0], out minVal);
                        float.TryParse(( string ) prop.properties[i].values[1], out maxVal);

                        minMaxRange = new Vector2(minVal, maxVal);

                        break;
                    case HekkyShaderProperty.OnToggle:
                        toggleTypeSignature = ( string ) prop.properties[i].values[0];
                        toggleMethodSignature = ( string ) prop.properties[i].values[1];
                        break;
                }
            }

            if ( !ignoreProp ) {
                if ( EnsureFoldoutIsRendered() ) {
                    return true;
                }

                if ( disabled ) {
                    EditorGUI.BeginDisabledGroup(true);
                }

                // Get props to show on the same line
                if ( propertyMap[prop.unityInternalProperty.name].sameLine != null &&
                     propertyMap[prop.unityInternalProperty.name].sameLine.unityInternalProperty != null ) {
                    var sameLineUnityInternalProp =
                        propertyMap[prop.unityInternalProperty.name].sameLine.unityInternalProperty;

                    if ( sameLineUnityInternalProp.type == MaterialProperty.PropType.Texture ) {

                        lastValue_Float = propertyMap[prop.unityInternalProperty.name].sameLine.unityInternalProperty.floatValue;
                        lastValue_Texture = sameLineUnityInternalProp.textureValue;

                        DrawTextureWithOtherProp(EditorGUIUtility.TrTextContent(prop.displayName),
                            sameLineUnityInternalProp, propertyMap[prop.unityInternalProperty.name].sameLine);

                        valueChanged =
                            ( lastValue_Texture != sameLineUnityInternalProp.textureValue ) ||
                            ( lastValue_Float != propertyMap[prop.unityInternalProperty.name].sameLine.unityInternalProperty.floatValue );

                        if ( doLinearProp ) {
                            LinearWarning(prop.unityInternalProperty);
                        }
                    } else if ( prop.unityInternalProperty.type == MaterialProperty.PropType.Texture ) {

                        lastValue_Float = propertyMap[prop.unityInternalProperty.name].sameLine.unityInternalProperty.floatValue;
                        lastValue_Texture = prop.unityInternalProperty.textureValue;

                        DrawTextureWithOtherProp(EditorGUIUtility.TrTextContent(prop.displayName),
                            prop.unityInternalProperty, propertyMap[prop.unityInternalProperty.name].sameLine);

                        valueChanged =
                            ( lastValue_Texture != prop.unityInternalProperty.textureValue ) ||
                            ( lastValue_Float != propertyMap[prop.unityInternalProperty.name].sameLine.unityInternalProperty.floatValue );

                        if ( doLinearProp ) {
                            LinearWarning(prop.unityInternalProperty);
                        }
                    } else {
                        lastValue_Float = prop.unityInternalProperty.floatValue;

                        materialEditor.ShaderProperty(prop.unityInternalProperty, prop.displayName);

                        valueChanged = lastValue_Float != prop.unityInternalProperty.floatValue;
                    }

                } else {
                    Rect mainRect;
                    Rect rect;
                    switch ( prop.unityInternalProperty.type ) {
                        case MaterialProperty.PropType.Texture:
                            lastValue_Texture = prop.unityInternalProperty.textureValue;

                            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent(prop.displayName),
                                prop.unityInternalProperty);

                            valueChanged = lastValue_Texture != prop.unityInternalProperty.textureValue;

                            if ( doLinearProp )
                                LinearWarning(prop.unityInternalProperty);
                            break;

                        case MaterialProperty.PropType.Vector:

                            lastValue_Vec4 = prop.unityInternalProperty.vectorValue;

                            if ( sliderCount > 0 ) {
                                Vector4 vecVal = prop.unityInternalProperty.vectorValue;
                                Vector4 defaultVector = material.shader.GetPropertyDefaultVectorValue(prop.index);

                                for ( int i = 0; i < sliderCount; i++ ) {
                                    EditorGUILayout.BeginHorizontal();

                                    vecVal[i] = DoSlider(
                                        sliderNames[i].Length == 0
                                            ? $"{prop.displayName} {IndexToVecComponentString(sliderComponent[i])}"
                                            : sliderNames[i],
                                        vecVal[i], sliderRange[i].x, sliderRange[i].y);

                                    mainRect = GUILayoutUtility.GetLastRect();
                                    rect = EditorGUILayout.GetControlRect(GUILayout.Width(14), GUILayout.Height(11), GUILayout.ExpandHeight(true));
                                    rect.y = mainRect.yMax - rect.height;
                                    if ( GUI.Button(rect, HGUI.UndoArrowContent, HGUI.UndoButton) ) {
                                        materialEditor.RegisterPropertyChangeUndo("Reset value");
                                        vecVal[i] = defaultVector[i];
                                    }
                                    EditorGUILayout.EndHorizontal();
                                }

                                prop.unityInternalProperty.vectorValue = vecVal;
                            } else if (doMinMax) {
                                EditorGUILayout.BeginHorizontal();

                                float minVal = prop.unityInternalProperty.vectorValue.x;
                                float maxVal = prop.unityInternalProperty.vectorValue.y;

                                EditorGUILayout.MinMaxSlider(prop.displayName, ref minVal, ref maxVal, minMaxRange.x, minMaxRange.y);

                                Vector4 newMinMaxValue = new Vector4(minVal, maxVal, 0, 0);
                                prop.unityInternalProperty.vectorValue = newMinMaxValue;

                                mainRect = GUILayoutUtility.GetLastRect();
                                rect = EditorGUILayout.GetControlRect(GUILayout.Width(14), GUILayout.Height(11), GUILayout.ExpandHeight(true));
                                rect.y = mainRect.yMax - rect.height;
                                if ( GUI.Button(rect, HGUI.UndoArrowContent, HGUI.UndoButton) ) {
                                    materialEditor.RegisterPropertyChangeUndo("Reset value");
                                    Vector4 defaultVector = material.shader.GetPropertyDefaultVectorValue(prop.index);
                                    prop.unityInternalProperty.vectorValue = defaultVector;
                                }
                                EditorGUILayout.EndHorizontal();
                            } else {
                                EditorGUILayout.BeginHorizontal();
                                materialEditor.ShaderProperty(prop.unityInternalProperty, prop.displayName);
                                mainRect = GUILayoutUtility.GetLastRect();
                                rect = EditorGUILayout.GetControlRect(GUILayout.Width(14), GUILayout.Height(11), GUILayout.ExpandHeight(true));
                                rect.y = mainRect.yMax - rect.height;
                                if ( GUI.Button(rect, HGUI.UndoArrowContent, HGUI.UndoButton) ) {
                                    materialEditor.RegisterPropertyChangeUndo("Reset value");
                                    Vector4 defaultVector = material.shader.GetPropertyDefaultVectorValue(prop.index);
                                    prop.unityInternalProperty.vectorValue = defaultVector;
                                }
                                EditorGUILayout.EndHorizontal();
                            }

                            valueChanged = lastValue_Vec4 != prop.unityInternalProperty.vectorValue;

                            break;
                        case MaterialProperty.PropType.Color:

                            lastValue_Color = prop.unityInternalProperty.colorValue;

                            EditorGUILayout.BeginHorizontal();
                            materialEditor.ShaderProperty(prop.unityInternalProperty, prop.displayName);
                            mainRect = GUILayoutUtility.GetLastRect();
                            rect = EditorGUILayout.GetControlRect(GUILayout.Width(14), GUILayout.Height(11), GUILayout.ExpandHeight(true));
                            rect.y = mainRect.yMax - rect.height;
                            if (GUI.Button(rect, HGUI.UndoArrowContent, HGUI.UndoButton)) {
                                materialEditor.RegisterPropertyChangeUndo("Reset value");
                                Vector4 defaultColor = material.shader.GetPropertyDefaultVectorValue(prop.index);
                                prop.unityInternalProperty.colorValue = new Color(defaultColor.x, defaultColor.y, defaultColor.z, defaultColor.w);
                            }

                            valueChanged = lastValue_Color != prop.unityInternalProperty.colorValue;
                            EditorGUILayout.EndHorizontal();
                            break;
                        
                        case MaterialProperty.PropType.Range:
                        case MaterialProperty.PropType.Float:

                            lastValue_Float = prop.unityInternalProperty.floatValue;

                            EditorGUILayout.BeginHorizontal();
                            materialEditor.ShaderProperty(prop.unityInternalProperty, prop.displayName);
                            mainRect = GUILayoutUtility.GetLastRect();
                            rect = EditorGUILayout.GetControlRect(GUILayout.Width(14), GUILayout.Height(11), GUILayout.ExpandHeight(true));
                            rect.y = mainRect.yMax - rect.height;
                            if (GUI.Button(rect, HGUI.UndoArrowContent, HGUI.UndoButton)) {
                                materialEditor.RegisterPropertyChangeUndo("Reset value");
                                float defaultValue = material.shader.GetPropertyDefaultFloatValue(prop.index);
                                prop.unityInternalProperty.floatValue = defaultValue;
                            }
                            EditorGUILayout.EndHorizontal();

                            valueChanged = lastValue_Float != prop.unityInternalProperty.floatValue;

                            break;

                        // TODO: More props
                        default:
                            lastValue_Float = prop.unityInternalProperty.floatValue;

                            materialEditor.ShaderProperty(prop.unityInternalProperty, prop.displayName);

                            valueChanged = lastValue_Float != prop.unityInternalProperty.floatValue;
                            break;
                    }

                    // if (prop.unityInternalProperty.type == MaterialProperty.PropType.Texture)
                    //     materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent(prop.displayName), prop.unityInternalProperty);
                    // else
                    //     materialEditor.ShaderProperty(prop.unityInternalProperty, prop.displayName);
                }

                if ( doUVScaleOffsetBlock ) {
                    materialEditor.TextureScaleOffsetProperty(prop.unityInternalProperty);
                }

                // @TODO: Only if change
                if ( valueChanged && toggleTypeSignature.Length > 0 && toggleMethodSignature.Length > 0 ) {
                    var type = Assembly.GetExecutingAssembly().GetType(toggleTypeSignature);
                    if ( type != null ) {
                        var method = type.GetMethod(toggleMethodSignature);
                        if ( method != null ) {
                            method.Invoke(null, new object[] { ( prop.unityInternalProperty.floatValue == 1.0f ), prop, materialEditor, material });
                        } else {
                            Debug.LogWarning($"Failed to find method {toggleMethodSignature}!");
                        }
                    } else {
                        Debug.LogWarning($"Failed to find type {toggleTypeSignature}!");
                    }
                }

                if ( disabled ) {
                    EditorGUI.EndDisabledGroup();
                }
            }

            return false;
        }

        private bool DrawProp(HekkyMaterialProperty prop) {
            bool stopRenderingRoot = false;

            if ( prop.GetType() == typeof(HekkyShaderFoldout) ) {
                var foldout = ( HekkyShaderFoldout ) prop;

                // TODO: Foldout stack so that empty foldouts don't render
                foldoutQueue.Enqueue(foldout);

                // bool doFoldout = HGUI.CollapsingHeader(foldout.displayName);
                // prop.unityInternalProperty.floatValue = doFoldout ? 1 : 0;
                // if (prop.unityInternalProperty.floatValue == 1.0f)
                // {
                //     HGUI.BeginGroup();
                //     RenderPropsRecursive(((HekkyShaderFoldout) prop).materialProperties);
                //     HGUI.EndGroup();
                // }

                return RenderPropsRecursive(( ( HekkyShaderFoldout ) prop ).materialProperties);
            } else {
                bool doRenderNormally = true;

                for ( int j = 0; j < prop.properties.Length; j++ ) {
                    // Shorthands
                    var currentProp = prop;
                    var currentToken = currentProp.properties[j];
                    switch ( currentToken.propertyType ) {
                        // Props which alter the GUI layout will stop being parsed
                        case HekkyShaderProperty.DoHeader:
                            stopRenderingRoot |= EnsureFoldoutIsRendered();
                            DoHeader();
                            doRenderNormally = false;
                            continue;

                        case HekkyShaderProperty.DoFooter:
                            stopRenderingRoot |= EnsureFoldoutIsRendered();
                            DoFooter();
                            doRenderNormally = false;
                            continue;

                        case HekkyShaderProperty.DoTextureFixCollection:
                            stopRenderingRoot |= EnsureFoldoutIsRendered();
                            DoGroupedWarningsContainer();
                            doRenderNormally = false;
                            continue;

                        // Shorthands for Unity Built-ins
                        case HekkyShaderProperty.DoBlendMode:
                            if ( BlendModeUnityProp == null )
                                Debug.LogError($"Blend mode property \"_Mode\" couldn't be found!");
                            else {
                                stopRenderingRoot |= EnsureFoldoutIsRendered();
                                DoBlendMode(BlendModeUnityProp, currentProp.displayName);
                            }

                            doRenderNormally = false;
                            continue;
                        case HekkyShaderProperty.DoRenderQueueField:
                            stopRenderingRoot |= EnsureFoldoutIsRendered();
                            materialEditor.RenderQueueField();
                            doRenderNormally = false;
                            continue;
                        case HekkyShaderProperty.DoInstancingField:
                            stopRenderingRoot |= EnsureFoldoutIsRendered();
                            materialEditor.EnableInstancingField();
                            doRenderNormally = false;
                            continue;
                        case HekkyShaderProperty.DoDoubleSidedGIField:
                            stopRenderingRoot |= EnsureFoldoutIsRendered();
                            materialEditor.DoubleSidedGIField();
                            doRenderNormally = false;
                            continue;

                        case HekkyShaderProperty.Spacing:
                            HGUI.Spacing();
                            doRenderNormally = false;
                            continue;

                        // Handle special props which aren't supposed to draw anything
                        case HekkyShaderProperty.Title:
                        case HekkyShaderProperty.Hide:
                            doRenderNormally = false;
                            continue;

                        case HekkyShaderProperty.Unknown:
                            Debug.LogError(
                                $"Unknown shader property \"{currentToken.propertyRaw}\" in {currentProp.unityInternalProperty.name}");
                            doRenderNormally = false;
                            break;

#pragma warning disable CS0162
                        // Props which require 3rd party assets to even render
                        case HekkyShaderProperty.RequireBakery:
                            if ( !BAKERY_AVAILABLE )
                                doRenderNormally = false;
                            continue;
                        case HekkyShaderProperty.RequireAudioLink:
                            if ( !AUDIOLINK_AVAILABLE )
                                doRenderNormally = false;
                            continue;
                        case HekkyShaderProperty.RequireLTCGI:
                            if ( !LTCGI_AVAILABLE )
                                doRenderNormally = false;
                            continue;

#pragma warning restore CS0162
                    }
                }

                if ( doRenderNormally ) {
                    stopRenderingRoot |= DrawPropInternal(prop);
                }
            }

            return stopRenderingRoot;
        }

        private bool RenderPropsRecursive(HekkyMaterialProperty[] props) {
            foreach ( var prop in props ) {
                if ( DrawProp(prop) ) {
                    break;
                }
            }

            if ( foldoutQueue.Count > 0 ) {
                foldoutQueue.Dequeue();
            } else if ( foldoutsToClose > 0 ) {
                HGUI.EndGroup();
                foldoutsToClose--;
            }

            return false;
        }

        #endregion

        #region Parser

        private HekkyShaderFoldout ParsePropertiesToFoldout(MaterialProperty[] properties, string displayName = "null",
            MaterialProperty foldoutRoot = null) {
            // Debug.Log($"Parsing foldout {displayName}!");

            // Setup root foldout
            HekkyShaderFoldout foldout = new HekkyShaderFoldout();
            foldout.properties = Array.Empty<HekkyShaderToken>();
            foldout.displayName = displayName;
            foldout.unityInternalProperty = foldoutRoot;
            foldout.index = -1;

            List<HekkyMaterialProperty> hekkyProps = new List<HekkyMaterialProperty>();

            Stack foldoutStack = new Stack();

            for ( int i = 0; i < properties.Length; i++ ) {
                bool skip = false;
                bool textureIsLinear = false;
                var currProp = new HekkyMaterialProperty();
                currProp.unityInternalProperty = properties[i];
                currProp.index = material.shader.FindPropertyIndex(properties[i].name);

                // Get tokens
                string[] propertyTokens = properties[i].displayName.Split(PROPERTY_SEPARATOR);
                // Trim tokens
                for ( int j = 0; j < propertyTokens.Length; j++ ) {
                    propertyTokens[j] = propertyTokens[j].Trim();
                }

                currProp.displayName = propertyTokens[0];
                var tokensParsed = new List<HekkyShaderToken>();
                for ( int j = 1; j < propertyTokens.Length; j++ ) {
                    // Tokens can be empty or null
                    if ( propertyTokens[j].Length == 0 )
                        continue;

                    var token = new HekkyShaderToken {
                        propertyType = HekkyShaderProperty.Unknown,
                        propertyRaw = propertyTokens[j]
                    };

                    int indexOfOpeningBracket = propertyTokens[j].IndexOf('(');
                    string methodName;
                    string methodProps;
                    if ( indexOfOpeningBracket == -1 ) {
                        methodName = propertyTokens[j].Trim();
                        methodProps = "";
                    } else {
                        methodName = propertyTokens[j].Substring(0, indexOfOpeningBracket).Trim();
                        methodProps = propertyTokens[j].Substring(indexOfOpeningBracket + 1).Trim().TrimEnd(')');
                    }

                    // Split by , then remove whitespacing
                    // TODO: \, ??
                    token.values = methodProps.Split(',');
                    for ( int k = 0; k < token.values.Length; k++ ) {
                        token.values[k] = ( ( string ) token.values[k] ).Trim();
                    }

                    // Convert to type
                    switch ( methodName ) {
                        // Special case: recursion!

                        case "beginFoldout":
                            token.propertyType = HekkyShaderProperty.BeginFoldout;
                            foldoutStack.Push(i);
                            break;
                        case "endFoldout":
                            token.propertyType = HekkyShaderProperty.EndFoldout;
                            int foldoutStart = ( int ) foldoutStack.Pop();
                            if ( foldoutStack.Count == 0 ) {
                                MaterialProperty[] props = new MaterialProperty[i - foldoutStart - 1];
                                Array.ConstrainedCopy(properties, foldoutStart + 1, props, 0, props.Length);

                                hekkyProps.Add(ParsePropertiesToFoldout(props,
                                    properties[foldoutStart].displayName
                                        .Split(PROPERTY_SEPARATOR)[0],
                                    properties[foldoutStart]));

                                skip = true;
                            }

                            break;
                    }

                    // Skip everything else if theres something in the foldout stack
                    if ( foldoutStack.Count == 0 && skip == false ) {
                        string key = ( string ) token.values[0];
                        switch ( methodName ) {
                            // String value, trim quotes
                            case "version":
                                token.propertyType = HekkyShaderProperty.Version;
                                token.values = new object[] { methodProps.Trim('\'') };
                                break;
                            case "title":
                                token.propertyType = HekkyShaderProperty.Title;
                                token.values = new object[] { methodProps.Trim('\'') };
                                break;
                            case "docsURL":
                                token.propertyType = HekkyShaderProperty.DocsURL;
                                token.values = new object[] { methodProps.Trim('\'') };
                                break;

                            case "doHeader":
                                token.propertyType = HekkyShaderProperty.DoHeader;
                                break;
                            case "doTextureFixCollection":
                                token.propertyType = HekkyShaderProperty.DoTextureFixCollection;
                                break;
                            case "doFooter":
                                token.propertyType = HekkyShaderProperty.DoFooter;
                                break;
                            case "doBlendMode":
                                token.propertyType = HekkyShaderProperty.DoBlendMode;
                                break;
                            case "doScaleOffset":
                                token.propertyType = HekkyShaderProperty.DoScaleOffset;
                                break;

                            case "doRenderQueueField":
                                token.propertyType = HekkyShaderProperty.DoRenderQueueField;
                                break;
                            case "doInstancingField":
                                token.propertyType = HekkyShaderProperty.DoInstancingField;
                                break;
                            case "doDoubleSidedGIField":
                                token.propertyType = HekkyShaderProperty.DoDoubleSidedGIField;
                                break;

                            case "hide":
                                token.propertyType = HekkyShaderProperty.Hide;
                                break;
                            case "disable":
                                token.propertyType = HekkyShaderProperty.Disable;
                                break;
                            case "disableIfNot":
                                token.propertyType = HekkyShaderProperty.DisableIfNot;
                                // Default value :: 1
                                if ( token.values.Length == 1 ) {
                                    token.values = new[] { token.values[0], "1" };
                                }

                                break;
                            case "hideIfNot":
                                token.propertyType = HekkyShaderProperty.HideIfNot;
                                // Default value :: 1
                                if ( token.values.Length == 1 ) {
                                    token.values = new[] { token.values[0], "1" };
                                }

                                break;
                            case "showAlong":
                                token.propertyType = HekkyShaderProperty.ShowAlong;
                                // Throw this property into the LUT
                                if ( !propertyMap.ContainsKey(key) )
                                    Debug.LogError(
                                        $"Property {key} not found in {currProp.unityInternalProperty.name}!");
                                else
                                    propertyMap[key].sameLine = currProp;
                                // TODO: Autohide
                                break;

                            case "spacing":
                                token.propertyType = HekkyShaderProperty.Spacing;
                                break;

                            case "slider":
                                token.propertyType = HekkyShaderProperty.Slider;
                                break;
                            case "minmax":
                                token.propertyType = HekkyShaderProperty.MinMax;
                                break;
                            case "linear":
                                token.propertyType = HekkyShaderProperty.LinearWarning;
                                textureIsLinear = true;
                                break;

                            case "pass":
                                token.propertyType = HekkyShaderProperty.ShaderPass;
                                break;
                            case "onToggle":
                                token.propertyType = HekkyShaderProperty.OnToggle;
                                break;

                            case "requireBakery":
                                token.propertyType = HekkyShaderProperty.RequireBakery;
                                break;
                            case "requireAudioLink":
                                token.propertyType = HekkyShaderProperty.RequireAudioLink;
                                break;
                            case "requireLTCGI":
                                token.propertyType = HekkyShaderProperty.RequireLTCGI;
                                break;

                            default:
                                token.propertyType = HekkyShaderProperty.Unknown;
                                break;
                        }

                        // Debug.Log($"Name: |{methodName}| Props: |{methodProps}|");

                        tokensParsed.Add(token);
                    }
                }

                // Textures are a special case
                if ( properties[i].type == MaterialProperty.PropType.Texture &&
                     !incorrectlyConfiguredTextureCount.ContainsValue(properties[i]) ) {
                    string texPath = AssetDatabase.GetAssetPath(properties[i].textureValue);
                    var importer = AssetImporter.GetAtPath(texPath) as TextureImporter;
                    if ( HekkyUtil.TestBitwiseFlag(properties[i].flags, MaterialProperty.PropFlags.Normal) ) {
                        // increase the counter if its a linear texture marked as sRGB
                        if ( importer != null && importer.textureType != TextureImporterType.NormalMap ) {
                            incorrectlyConfiguredTextureCount.Add(incorrectlyConfiguredTextureCount.Count,
                                properties[i]);
                        }
                    } else if ( textureIsLinear ) {
                        // increase the counter if its a linear texture marked as sRGB
                        if ( importer != null && importer.sRGBTexture ) {
                            incorrectlyConfiguredTextureCount.Add(incorrectlyConfiguredTextureCount.Count,
                                properties[i]);
                        }
                    }
                }

                // Skip everything else if theres something in the foldout stack
                if ( foldoutStack.Count == 0 && skip == false ) {
                    currProp.properties = tokensParsed.ToArray();
                    hekkyProps.Add(currProp);
                }
            }

            foldout.materialProperties = hekkyProps.ToArray();

            return foldout;
        }

        #endregion

        #region Utils

        private static readonly string[] blendModeNames = Enum.GetNames(typeof(HGUI.BlendMode));
        private static readonly int Mode = Shader.PropertyToID("_Mode");

        // private static Dictionary<string, MaterialProperty> RawPropsToLut(MaterialProperty[] properties)
        private static Dictionary<string, HekkyShaderPropertyContainer> RawPropsToLut(MaterialProperty[] properties) {
            var dict = new Dictionary<string, HekkyShaderPropertyContainer>();

            for ( int i = 0; i < properties.Length; i++ ) {
                var container = new HekkyShaderPropertyContainer();
                container.property = properties[i];
                dict.Add(properties[i].name, container);
            }

            return dict;
        }

        private bool BlendModePopup(MaterialProperty blendModeProp, string displayName) {
            EditorGUI.showMixedValue = blendModeProp.hasMixedValue;
            var mode = ( HGUI.BlendMode ) blendModeProp.floatValue;

            EditorGUI.BeginChangeCheck();
            mode = ( HGUI.BlendMode ) EditorGUILayout.Popup(displayName, ( int ) mode, blendModeNames);
            bool result = EditorGUI.EndChangeCheck();
            if ( result ) {
                materialEditor.RegisterPropertyChangeUndo(displayName);
                blendModeProp.floatValue = ( float ) mode;
            }

            EditorGUI.showMixedValue = false;

            return result;
        }

        private void SetBlendMode(Material material, HGUI.BlendMode blendMode, bool overrideRenderQueue) {
            int minRenderQueue = -1;
            int maxRenderQueue = 5000;
            int defaultRenderQueue = -1;

            switch ( blendMode ) {
                case HGUI.BlendMode.Opaque:
                    material.SetOverrideTag("RenderType", "");
                    material.SetFloat("_SrcBlend", ( float ) UnityEngine.Rendering.BlendMode.One);
                    material.SetFloat("_DstBlend", ( float ) UnityEngine.Rendering.BlendMode.Zero);
                    material.SetFloat("_ZWrite", 1.0f);
                    material.SetFloat("_AlphaCoverageMode", 0.0f);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    minRenderQueue = -1;
                    maxRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.AlphaTest - 1;
                    defaultRenderQueue = -1;
                    break;
                case HGUI.BlendMode.Cutout:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetFloat("_SrcBlend", ( float ) UnityEngine.Rendering.BlendMode.One);
                    material.SetFloat("_DstBlend", ( float ) UnityEngine.Rendering.BlendMode.Zero);
                    material.SetFloat("_ZWrite", 1.0f);
                    material.SetFloat("_AlphaCoverageMode", 1.0f);
                    material.EnableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    minRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.AlphaTest;
                    maxRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.GeometryLast;
                    defaultRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case HGUI.BlendMode.Fade:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetFloat("_SrcBlend", ( float ) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetFloat("_DstBlend", ( float ) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetFloat("_ZWrite", 0.0f);
                    material.SetFloat("_AlphaCoverageMode", 0.0f);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    minRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.GeometryLast + 1;
                    maxRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.Overlay - 1;
                    defaultRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case HGUI.BlendMode.Transparent:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetFloat("_SrcBlend", ( float ) UnityEngine.Rendering.BlendMode.One);
                    material.SetFloat("_DstBlend", ( float ) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetFloat("_ZWrite", 0.0f);
                    material.SetFloat("_AlphaCoverageMode", 0.0f);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                    minRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.GeometryLast + 1;
                    maxRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.Overlay - 1;
                    defaultRenderQueue = ( int ) UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
            }

            if ( overrideRenderQueue || material.renderQueue < minRenderQueue ||
                 material.renderQueue > maxRenderQueue ) {
                if ( !overrideRenderQueue )
                    Debug.LogFormat(
                        "Render queue value outside of the allowed range ({0} - {1}) for selected Blend mode, resetting render queue to default",
                        minRenderQueue, maxRenderQueue);
                material.renderQueue = defaultRenderQueue;
            }
        }

        private void UpdateKeywords(Material material) {
            HGUI.SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap"));

            // Fix emission for lightmapping
            MaterialEditor.FixupEmissiveFlag(material);
            bool shouldEmissionBeEnabled =
                ( material.globalIlluminationFlags & MaterialGlobalIlluminationFlags.EmissiveIsBlack ) == 0;
            HGUI.SetKeyword(material, "_EMISSION", shouldEmissionBeEnabled);
        }

        private string IndexToVecComponentString(int id) {
            switch ( id ) {
                case 0:
                    return "X";
                case 1:
                    return "Y";
                case 2:
                    return "Z";
                case 3:
                    return "W";
                default:
                    return "Unknown Vector Component";
            }
        }

        #endregion
    }

    /// <summary>
    /// A Shader property, similar to Unity's base MaterialProperty
    /// </summary>
    public class HekkyMaterialProperty {
        /// <summary>
        /// The individual properties of this property
        /// </summary>
        public HekkyShaderToken[] properties;

        /// <summary>
        /// The parsed displayName
        /// </summary>
        public string displayName;

        /// <summary>
        /// The raw <see cref="MaterialProperty"/> used by Unity
        /// </summary>
        public MaterialProperty unityInternalProperty;

        /// <summary>
        /// The index of the material property
        /// </summary>
        public int index;
    }

    public struct HekkyShaderToken {
        /// <summary>
        /// The raw, unparsed shader property
        /// </summary>
        public string propertyRaw;

        /// <summary>
        /// The value of the current shader property, null if doesn't exist
        /// </summary>
        public object[] values;

        /// <summary>
        /// The property type denoted by this
        /// </summary>
        public HekkyShaderProperty propertyType;
    }

    public enum HekkyShaderProperty {
        Unknown = -1, // what the fuck is this type

        Version = 0, // version(0.0.1a)
        Title, // title('Hekky\'s Awesome Shader')
        DocsURL, // docsURL('https://example.com')
        DoTextureFixCollection, // doTextureFixCollection

        Disable, // disable
        DisableIfNot, // disableIfNot(prop)
        Hide, // hide
        HideIfNot, // hideIfNot(prop)
        ShowAlong, // showAlong(prop)

        DoHeader, // doHeader
        DoFooter, // doFooter
        DoBlendMode, // doBlendMode
        DoScaleOffset, // doScaleOffset

        DoRenderQueueField, // doRenderQueueField
        DoInstancingField, // doInstancingField
        DoDoubleSidedGIField, // doDoubleSidedGIField

        BeginFoldout, // beginFoldout(title)
        EndFoldout, // endFoldout

        Spacing, // spacing

        Slider, // slider
        MinMax, // minMax
        LinearWarning, // linear

        ShaderPass, // pass
        OnToggle, // onToggle(fullMethodSignature)

        RequireBakery, // requireBakery
        RequireAudioLink, // requireAudioLink
        RequireLTCGI, // requireLTCGI
    }

    /// <summary>
    /// A special property variant, that can take children (generally a foldout)
    /// </summary>
    class HekkyShaderFoldout : HekkyMaterialProperty {
        /// <summary>
        /// List of all child properties of the foldout
        /// </summary>
        public HekkyMaterialProperty[] materialProperties;
    }

    /// <summary>
    /// A small wrapper around <see cref="MaterialProperty"/> to allow more data to be stored
    /// </summary>
    class HekkyShaderPropertyContainer {
        /// <summary>
        /// 
        /// </summary>
        public MaterialProperty property;

        /// <summary>
        /// The property which is to be shown on the same line, null if none
        /// </summary>
        public HekkyMaterialProperty sameLine;

        /// <summary>
        /// The properties which will be hidden if their corresponding value is set
        /// </summary>
        // public HekkyMaterialProperty[] hideIfProps;
        // public object[] hideIfValues;
        public (HekkyMaterialProperty prop, object val)[] hideIf;

        /// <summary>
        /// The properties which will be disabled if their corresponding value is not set
        /// </summary>
        public (HekkyMaterialProperty prop, object val)[] disableIf;
    }
}