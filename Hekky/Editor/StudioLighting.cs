using UnityEditor;
using UnityEditor.ShortcutManagement;
using UnityEngine;

namespace Hekky
{
    public class SceneViewUtil : EditorWindow
    {
        private static bool isInStudioModePrevious = false;
        private static bool isInStudioMode = false;
        
        static SceneViewUtil()
        {
            SceneView.duringSceneGui += OnScene;
        }
        
        [MenuItem("Window/Studio Mode/Enable")]
        public static void Enable()
        {
            isInStudioMode = true;
        }
 
        [MenuItem("Window/Studio Mode/Disable")]
        public static void Disable()
        {
            isInStudioMode = false;
        }

        [Shortcut("Scene View/Toggle Studio Mode", KeyCode.F12)]
        public static void ToggleStudioMode()
        {
            isInStudioMode = !isInStudioMode;
        }
 
        private static void OnScene(SceneView sceneview)
        {
            var darkSkin = EditorGUIUtility.GetBuiltinSkin(EditorSkin.Scene);
            Handles.BeginGUI();
            GUILayout.BeginArea(new Rect(Screen.width - 110, 120, 90, 600));
            GUILayout.BeginVertical();
 
            // button to toggle studio mode
            // if (GUILayout.Button("Studio mode", darkSkin.button))
            // {
            //     isInStudioMode = !isInStudioMode;
            // }
            
            // actually handle the shader switching
            if (isInStudioModePrevious != isInStudioMode)
            {
                if (isInStudioMode)
                    sceneview.SetSceneViewShaderReplace(Shader.Find("Hidden/Hekky/Scene View Studio Mode"), "RenderType");
                else
                    sceneview.SetSceneViewShaderReplace(null, null);
                isInStudioModePrevious = isInStudioMode;
            }

            GUILayout.EndVertical();
            GUILayout.EndArea();
            Handles.EndGUI();
        }
    }
}