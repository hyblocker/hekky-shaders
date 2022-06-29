using System.IO;
using UnityEditor;
using UnityEngine.UIElements;

namespace Hekky {
    public class HekkySettingsProvider : SettingsProvider {
        private SerializedObject m_HekkySettings;
        public const string k_HekkySettingsPath = "Assets/Editor/HekkySettings.asset";

        public HekkySettingsProvider(string path, SettingsScope scope = SettingsScope.User) : base(path, scope) { }

        public static bool IsSettingsAvailable() {
            return File.Exists(k_HekkySettingsPath);
        }

        public override void OnActivate(string searchContext, VisualElement rootElement) {
            // This function is called when the user clicks on the MyCustom element in the Settings window.
            m_HekkySettings = HekkySettings.GetSerializedSettings();
        }

        // Register the SettingsProvider
        [SettingsProvider]
        public static SettingsProvider CreateMyCustomSettingsProvider() {
            if ( IsSettingsAvailable() ) {
                var provider = new HekkySettingsProvider("Project/HekkySettingsProvider", SettingsScope.Project);

                // Automatically extract all keywords from the Styles.
                provider.keywords = new string[] { };
                return provider;
            }

            // Settings Asset doesn't exist yet; no need to display anything in the Settings window.
            return null;
        }
    }
}