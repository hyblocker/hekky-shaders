using UnityEditor;

namespace Hekky {
    public static partial class HGUI {
        /// <summary>
        /// Returns whether AudioLink is imported and available for use
        /// Used to hide AudioLink features when AudioLink is not imported (or else users will get shader errors)
        /// </summary>
        public static bool AudioLinkImported =>
            AssetDatabase.AssetPathToGUID("Assets/AudioLink/Scripts/AudioLink.cs") != string.Empty;
    }
}