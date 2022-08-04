// A script to make interfacing with Unity's EditorGUI class comfier by trying to emulate the DearImGUI APIs
// by Hekky#6869

using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEditor;
using UnityEngine;

namespace Hekky {
    // Core stuff
    public static partial class HGUI {
        private static Stack<int> m_idStack = new Stack<int>();
        private static Dictionary<int, bool> m_toggles = new Dictionary<int, bool>();

        // Implement an ID system like Dear ImGUI

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void PushID(int id) {
            m_idStack.Push(id);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void PushID(string label) {
            m_idStack.Push(label.GetHashCode());
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int PopID() {
            return m_idStack.Pop();
        }

        // Spacing
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Spacing() {
            GUILayout.Space(8);
        }

        // Indenting
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Indent(int indentW = 0) {
            EditorGUI.indentLevel += indentW;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Unindent(int indentW = 0) {
            EditorGUI.indentLevel -= indentW;
        }

        // Bodies
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Title(string shaderTitle) {
            EditorGUILayout.LabelField(shaderTitle, ShaderTitle);
        }
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Version(string versionString) {
            EditorGUILayout.LabelField(versionString, VersionTitle);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Header(string shaderTitle) {
            EditorGUILayout.LabelField(shaderTitle, ShaderHeaderTitle);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void Footer() {
            EditorGUILayout.LabelField("Made with <3 by Hekky", ShaderFooterCredit);
        }
    }
}