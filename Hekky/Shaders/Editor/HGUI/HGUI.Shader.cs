using UnityEditor;
using UnityEngine;

namespace Hekky {
    // Common controls specific to shader editors
    public static partial class HGUI {
        public static void AudioLinkDebug(MaterialEditor materialEditor, AudioLinkDebugProps alDebugProps) {
            HGUI.PushID("__al_debug");
            if ( HGUI.CollapsingHeader("Debug") ) {
                HGUI.Spacing();
                bool alDebugModeEnabled = HGUI.Toggle(alDebugProps.DebugEnabled, "Enable Debug Mode");
                EditorGUI.BeginDisabledGroup(!alDebugModeEnabled);
                materialEditor.ShaderProperty(alDebugProps.DebugBass, alDebugProps.DebugBass.displayName);
                materialEditor.ShaderProperty(alDebugProps.DebugLowMid, alDebugProps.DebugLowMid.displayName);
                materialEditor.ShaderProperty(alDebugProps.DebugHighMid, alDebugProps.DebugHighMid.displayName);
                materialEditor.ShaderProperty(alDebugProps.DebugTreble, alDebugProps.DebugTreble.displayName);
                EditorGUI.EndDisabledGroup();
            }

            HGUI.PopID();
        }

        public static void SetKeyword(Material material, string keyword, bool state) {
            if ( state )
                material.EnableKeyword(keyword);
            else
                material.DisableKeyword(keyword);
        }
    }
}