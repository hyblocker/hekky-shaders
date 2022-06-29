using UnityEditor;
using UnityEngine;

namespace Hekky {
    public static partial class HGUI {
        public static bool Toggle(MaterialProperty prop, string text) {
            bool toggleValue = prop.floatValue == 1.0f;
            toggleValue = GUILayout.Toggle(toggleValue, text);
            prop.floatValue = toggleValue ? 1.0f : 0.0f;

            return toggleValue;
        }

        /// <summary>
        /// Mimics the normal map import warning, to encourage users to not use sRGB
        /// Written by Orels1
        /// </summary>
        public static bool TextureImportWarningBox(string message) {
            GUILayout.BeginVertical(new GUIStyle(EditorStyles.helpBox));
            EditorGUILayout.LabelField(message,
                new GUIStyle(EditorStyles.label) {
                    fontSize = 10, wordWrap = true, padding = new RectOffset(0, 0, 0, 0)
                });
            EditorGUILayout.BeginHorizontal(new GUIStyle() {alignment = TextAnchor.MiddleRight}, GUILayout.Height(0));
            EditorGUILayout.Space(0f, true);
            bool buttonPress = GUILayout.Button("Fix Now",
                new GUIStyle("button") {
                    stretchWidth = false, margin = new RectOffset(0, 0, -4, 0), padding = new RectOffset(7, 8, 0, 0)
                }, GUILayout.Height(20));
            EditorGUILayout.EndHorizontal();
            GUILayout.EndVertical();
            return buttonPress;
        }
    }

    /// <summary>
    /// Draws a vector2 field for vector properties.
    /// Usage: [Vec2] _Vector2("Vector 2", Vector) = (0,0,0,0)
    /// </summary>
    public class Vec2Drawer : MaterialPropertyDrawer {
        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor) {
            if ( prop.type == MaterialProperty.PropType.Vector ) {
                EditorGUIUtility.labelWidth = 0f;
                EditorGUIUtility.fieldWidth = 0f;

                if ( !EditorGUIUtility.wideMode ) {
                    EditorGUIUtility.wideMode = true;
                    EditorGUIUtility.labelWidth = EditorGUIUtility.currentViewWidth - 212;
                }

                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = prop.hasMixedValue;
                Vector4 vec = EditorGUI.Vector2Field(position, label, prop.vectorValue);
                if ( EditorGUI.EndChangeCheck() ) {
                    prop.vectorValue = vec;
                }
            } else
                editor.DefaultShaderProperty(prop, label.text);
        }
    }
}