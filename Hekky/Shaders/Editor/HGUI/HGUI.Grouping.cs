using System.Runtime.CompilerServices;
using UnityEditor;
using UnityEngine;

namespace Hekky {
    public static partial class HGUI {
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void BeginGroup() {
            GUILayout.Space(2);
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            GUILayout.Space(2);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void EndGroup() {
            GUILayout.Space(2);
            EditorGUILayout.EndVertical();
            GUILayout.Space(2);
        }
    }
}