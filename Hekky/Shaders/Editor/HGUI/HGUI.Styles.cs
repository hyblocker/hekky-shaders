using UnityEditor;
using UnityEngine;

namespace Hekky
{
    public static partial class HGUI
    {
        public static GUIStyle ShaderTitle { get; private set; } = new GUIStyle(EditorStyles.boldLabel)
            {fontSize = 18, alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.Bold};

        public static GUIStyle ShaderHeaderTitle { get; private set; } = new GUIStyle(EditorStyles.boldLabel)
            {fontSize = 12, fontStyle = FontStyle.Bold};

        public static GUIStyle ShaderFooterCredit { get; private set; } = new GUIStyle(EditorStyles.miniLabel)
            {fontSize = 12, alignment = TextAnchor.MiddleRight, fontStyle = FontStyle.Italic};
        
        
        public static GUIStyle LabelWordWrapCenter { get; private set; } = new GUIStyle(EditorStyles.label)
            {alignment = TextAnchor.MiddleCenter, wordWrap = true};
        public static GUIStyle LabelWordWrapLeft { get; private set; } = new GUIStyle(EditorStyles.label)
            {alignment = TextAnchor.MiddleLeft, wordWrap = true};


        public static GUIStyle IconButton { get; private set; } = new GUIStyle(EditorStyles.miniButton)
            {alignment = TextAnchor.MiddleCenter, fixedHeight = 42f, fixedWidth = 42f, padding = new RectOffset(8,8,8,8), margin = new RectOffset(8,8,0,0)};
    }
}