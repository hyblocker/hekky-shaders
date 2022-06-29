using System;
using UnityEditor;

namespace Hekky {
    // Constants
    public static partial class HGUI {
        public static MaterialProperty[] materialPropsEmpty = { };

        /// <summary>
        /// Standard AudioLink Debug Layout struct
        /// </summary>
        public struct AudioLinkDebugProps {
            public AudioLinkDebugProps(MaterialProperty[] props) {
                DebugEnabled = FindProperty("_AudioLinkDebug", props);

                DebugBass = FindProperty("_AudioLinkDebugBass", props);
                DebugLowMid = FindProperty("_AudioLinkDebugLowMid", props);
                DebugHighMid = FindProperty("_AudioLinkDebugHighMid", props);
                DebugTreble = FindProperty("_AudioLinkDebugTreble", props);
            }

            public MaterialProperty DebugEnabled, DebugBass, DebugLowMid, DebugHighMid, DebugTreble;
        }

        // Reimpl from Unity
        private static MaterialProperty FindProperty(
            string propertyName,
            MaterialProperty[] properties,
            bool propertyIsMandatory = true) {
            for ( int index = 0; index < properties.Length; ++index ) {
                if ( properties[index] != null && properties[index].name == propertyName )
                    return properties[index];
            }

            if ( propertyIsMandatory )
                throw new ArgumentException("Could not find MaterialProperty: '" + propertyName +
                                            "', Num properties: " + ( object ) properties.Length);
            return ( MaterialProperty ) null;
        }
    }
}