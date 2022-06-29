using System.Runtime.CompilerServices;
using UnityEditor;
using UnityEngine;

namespace Hekky {
    public static partial class HGUI {
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool CollapsingHeader(string label, bool defaultOpen = false) {
            bool autoAssignedId = AutoAssignId(label);
            int currentID = m_idStack.Peek();

            if ( !m_toggles.ContainsKey(currentID) )
                m_toggles.Add(currentID, defaultOpen);

            // Render the control
            GUILayout.Space(4);

            GUILayoutOption clickArea = GUILayout.MaxWidth(EditorGUIUtility.labelWidth);
            Rect clickRect = GUILayoutUtility.GetRect(0, 18f, clickArea);

            GUILayout.Space(-24);
            EditorGUILayout.LabelField("     " + label, EditorStyles.boldLabel);
            GUILayout.Space(20);

            // Handle events
            switch ( Event.current.rawType ) {
                case EventType.Repaint:
                    EditorStyles.foldout.Draw(
                        new Rect(clickRect.x, clickRect.y - 3, clickRect.width, clickRect.height),
                        clickRect.Contains(Event.current.mousePosition),
                        false,
                        m_toggles[currentID],
                        false);
                    break;

                case EventType.MouseDown:
                    if ( clickRect.Contains(Event.current.mousePosition) ) {
                        m_toggles[currentID] = !m_toggles[currentID];
                        Event.current.Use();
                    }

                    break;
            }

            GUILayout.Space(-20);

            if ( autoAssignedId )
                m_idStack.Pop();

            return m_toggles[currentID];
        }
    }
}