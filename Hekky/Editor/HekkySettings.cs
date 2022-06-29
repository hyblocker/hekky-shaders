using UnityEditor;
using UnityEngine;

namespace Hekky {
    public class HekkySettings : ScriptableObject {
        public const string k_HekkySettingsPath = "Assets/Editor/HekkySettings.asset";

#pragma warning disable CS01414

        /// <summary>
        /// Whether to use Bakery with LTCGI
        /// </summary>
        [SerializeField] private bool m_useLtcgiWithBakery;

#pragma warning restore CS01414

        internal static HekkySettings GetOrCreateSettings() {
            var settings = AssetDatabase.LoadAssetAtPath<HekkySettings>(k_HekkySettingsPath);
            if ( settings == null ) {
                settings = ScriptableObject.CreateInstance<HekkySettings>();
                settings.m_useLtcgiWithBakery = false;
                AssetDatabase.CreateAsset(settings, k_HekkySettingsPath);
                AssetDatabase.SaveAssets();
            }

            return settings;
        }

        internal static SerializedObject GetSerializedSettings() {
            return new SerializedObject(GetOrCreateSettings());
        }
    }
}