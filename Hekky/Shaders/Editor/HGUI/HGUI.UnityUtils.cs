using System.IO;
using UnityEngine;

namespace Hekky {
    public static partial class HGUI {
        /// <summary>
        /// Returns whether AudioLink is imported and available for use
        /// Used to hide AudioLink features when AudioLink is not imported (or else users will get shader errors)
        /// </summary>
        public static bool AudioLinkImported => AssetExists("AudioLink/Scripts/AudioLink.cs");
        /// <summary>
        /// Returns whether LTCGI is imported and available for use
        /// Used to hide LTCGI features when LTCGI is not imported (or else users will get shader errors)
        /// </summary>
        public static bool LTCGIImported =>  AssetExists("_pi_/_LTCGI/Shaders/LTCGI.cginc");
        /// <summary>
        /// Returns whether Bakery is imported and available for use
        /// Used to hide Bakery features when Bakery is not imported (or else users will get shader errors)
        /// </summary>
        public static bool BakeryImported =>  AssetExists("Bakery/ftLightmaps.cs");

        internal static bool AssetExists(string filename)
        {
            return File.Exists(Path.GetFullPath(Path.Combine(Application.dataPath, filename)));
        }
    }
}