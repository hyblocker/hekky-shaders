using UnityEditor;
using UnityEngine;

namespace Hekky {
    public class HekkySettings : ScriptableObject {
        public const string k_HekkySettingsPath = "Assets/Editor/HekkySettings.asset";

#pragma warning disable CS0414

        /// <summary>
        /// Whether to use Bakery with LTCGI
        /// </summary>
        [SerializeField] private bool m_useLtcgiWithBakery;
        
        /// <summary>
        /// Forces MonoSH L1 lightmap textures to high quality compression when using MonoSH with Bakery due to the
        /// severe compression artifacts
        /// </summary>
        [SerializeField] private bool m_bakeryForceMonoShHighQuality;
        
        /// <summary>
        /// Whether the Force MonoSH L1 lightmap textures to BC7 popup has been shown before
        /// </summary>
        [HideInInspector][SerializeField] private bool m_bakeryMonoSHPopupShown;

#pragma warning restore CS0414

        internal static HekkySettings GetOrCreateSettings() {
            var settings = AssetDatabase.LoadAssetAtPath<HekkySettings>(k_HekkySettingsPath);
            if ( settings == null ) {
                settings = ScriptableObject.CreateInstance<HekkySettings>();
                settings.m_useLtcgiWithBakery = false;
                settings.m_bakeryForceMonoShHighQuality = false;
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