#if UNITY_EDITOR_WIN
#if BAKERY_INCLUDED
#if LTCGI_INCLUDED

using System.Reflection;
using pi.LTCGI;
using UnityEditor;
using UnityEngine;

namespace Hekky {
    public class LCTGI_QuickBake : EditorWindow {

        private static int iterations;
        private static bool bakery;

        [MenuItem("Hekky/LTCGI Quick Bake", false, 2)]
        static void LTCGI_QuickBake() {
            bakery = false;
#if BAKERY_INCLUDED
            var hasUsedBakeryBefore = ReadFromProjectSettings();
            if ( !hasUsedBakeryBefore ) {
                bakery = EditorUtility.DisplayDialog("LTCGI",
                    "Bakery has been detected in your project. Do you want to bake the lightmap with Bakery?",
                    "Yes, use Bakery", "No, use built-in");
                if ( bakery )
                    WriteToProjectSettings(bakery);
            } else {
                bakery = true;
            }
#endif
            iterations = 0;
            ftRenderLightmap.OnFinishedFullRender += (sender, args) => {
                iterations++;
                ContinueBake();
            };
            BakeryBake();
        }

        private static void ContinueBake() {
            switch ( iterations ) {
                case 0:
                    BakeryBake();
                    break;
                case 1:
                    LTCGIBake(bakery);
                    break;
                case 2:
                    BakeryBake();
                    break;
            }
        }

        static void BakeryBake() {
            var instance = ( ftRenderLightmap ) GetWindow(typeof(ftRenderLightmap));
            ftRenderLightmap.bakeInProgress = false;

            // instance.ValidateOutputPath();
            typeof(ftRenderLightmap).GetMethod("ValidateOutputPath", BindingFlags.Instance | BindingFlags.NonPublic)
                ?.Invoke(instance, null);
            instance.RenderButton();
            Debug.Log($"Bakery started!");

        }

        static void LTCGIBake(bool bakery) {
            if ( LTCGI_Controller.Singleton == null ) {
                EditorUtility.DisplayDialog("LTCGI", "Couldn't find an LTCGI controller in this project!", "OK");
                return;
            }

            ftRenderLightmap.bakeInProgress = false;

            // LTCGI_Controller.Singleton.BakeLightmap(bakery);
            typeof(LTCGI_Controller).GetMethod("BakeLightmap", BindingFlags.Instance | BindingFlags.NonPublic)
                ?.Invoke(LTCGI_Controller.Singleton, new object[] {bakery});

            Debug.Log($"LTCGI started!");
        }

        private static bool ReadFromProjectSettings(bool defaultValue = false) {

            var hekkySettingsManager = HekkySettings.GetSerializedSettings();
            SerializedProperty m_useLtcgiWithBakery = hekkySettingsManager.FindProperty("m_useLtcgiWithBakery");
            return m_useLtcgiWithBakery?.boolValue ?? defaultValue;
        }

        private static void WriteToProjectSettings(bool val) {

            var hekkySettingsManager = HekkySettings.GetSerializedSettings();
            SerializedProperty m_useLtcgiWithBakery = hekkySettingsManager.FindProperty("m_useLtcgiWithBakery");
            m_useLtcgiWithBakery.boolValue = val;
            hekkySettingsManager.ApplyModifiedProperties();
        }
    }
}

#endif
#endif
#endif