using UnityEditor;
using UnityEngine;

namespace Hekky {
    public static partial class HGUI {
        public static GUIStyle ShaderTitle { get; private set; } = new GUIStyle(EditorStyles.boldLabel) {
            fontSize = 18, alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.Bold
        };
        public static GUIStyle VersionTitle { get; private set; } = new GUIStyle(EditorStyles.boldLabel) {
            fontSize = 12, alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.BoldAndItalic
        };

        public static GUIStyle ShaderHeaderTitle { get; private set; } =
            new GUIStyle(EditorStyles.boldLabel) {fontSize = 12, fontStyle = FontStyle.Bold};

        public static GUIStyle ShaderFooterCredit { get; private set; } = new GUIStyle(EditorStyles.miniLabel) {
            fontSize = 12, alignment = TextAnchor.MiddleRight, fontStyle = FontStyle.Italic
        };


        public static GUIStyle LabelWordWrapCenter { get; private set; } =
            new GUIStyle(EditorStyles.label) {alignment = TextAnchor.MiddleCenter, wordWrap = true};

        public static GUIStyle LabelWordWrapLeft { get; private set; } =
            new GUIStyle(EditorStyles.label) {alignment = TextAnchor.MiddleLeft, wordWrap = true};

        public static GUIStyle UndoButton { get; private set; } =
            new GUIStyle(EditorStyles.label)  {
                alignment = TextAnchor.MiddleCenter,
                padding = new RectOffset(0, 0, 1, 0),
                margin = new RectOffset(0, 0, 0, 0),
                border = new RectOffset(0, 0, 0, 0),
                stretchWidth = false,
                stretchHeight = false,
            };

        private static GUIContent UndoArrowLight = new GUIContent((Texture)EditorGUIUtility.Load("Assets/Hekky/Textures/btn-undo-light.png"), "Reset to default value");
        private static GUIContent UndoArrowDark = new GUIContent((Texture)EditorGUIUtility.Load("Assets/Hekky/Textures/btn-undo-dark.png"), "Reset to default value");
        public static GUIContent UndoArrowContent
        {
            get { return EditorGUIUtility.isProSkin ? UndoArrowLight : UndoArrowDark; }
        }
        
        public static GUIStyle IconButton { get; private set; } = new GUIStyle(EditorStyles.miniButton) {
            alignment = TextAnchor.MiddleCenter,
            fixedHeight = 42f,
            fixedWidth = 42f,
            padding = new RectOffset(8, 8, 8, 8),
            margin = new RectOffset(8, 8, 0, 0)
        };
    }
}