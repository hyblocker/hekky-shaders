#if UNITY_EDITOR_WIN
#if BAKERY_INCLUDED
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hekky
{
    [InitializeOnLoad]
    class BakeryTweaks
    {
        static BakeryTweaks()
        {
            ftRenderLightmap.OnFinishedFullRender += OnLightmapFinishedRender;
        }

        private static void OnLightmapFinishedRender(object sender, EventArgs e)
        {
            // By default, MonoSH's L1 texture uses DXT1 compression, which results in horrible blocks since DXT1 handles
            // gradients horribly. As a result, this script will be used to force the L1 lightmap to high quality compression
            if ((int)ftRenderLightmap.renderDirMode == 6)
            {
                // Setting so that we don't force unwanted behavior on people's projects
                bool hasUsedBakeryBefore = ReadFromProjectSettings("m_bakeryForceMonoShHighQuality");
                bool doForceMonoShHQ = ReadFromProjectSettings("m_bakeryMonoSHPopupShown");
                if ( !hasUsedBakeryBefore ) {
                    doForceMonoShHQ = EditorUtility.DisplayDialog("High Quality MonoSH Lightmaps",
                        "Bakery MonoSH Directional mode detected.\n\nUse BC7 (High quality) texture compression instead of DXT1 (Normal quality)?\n\nThis will result in much better looking gradients, but also create larger texture assets.",
                        "Yes, use BC7", "No, use DXT1");
                    if ( doForceMonoShHQ )
                        WriteToProjectSettings("m_bakeryMonoSHPopupShown", doForceMonoShHQ);
                } else {
                    doForceMonoShHQ = true;
                }
                WriteToProjectSettings("m_bakeryForceMonoShHighQuality", true);

                if (!doForceMonoShHQ)
                    return;
                
                // Ensure that we can load all the lightmaps before we try doing anything with them
                AssetDatabase.Refresh();
                
                var monoSH_L1s = AssetDatabase.FindAssets($"_L1 t:Texture2D",
                    new string[] {$"Assets/{ftRenderLightmap.outputPath}"});
                
                foreach (var l1Lightmap in monoSH_L1s)
                {
                    // Check to ensure that the current texture ends with _L1.tga, as the user could have a scene with
                    // _L1 in it for some reason
                    if (!AssetDatabase.GUIDToAssetPath(l1Lightmap).EndsWith("_L1.tga")) {
                        continue;
                    }
                    
                    Debug.Log($"Forcing {AssetDatabase.GUIDToAssetPath(l1Lightmap)} to use High Quality texture compression");
                    
                    TextureImporter importer = ( TextureImporter ) AssetImporter.GetAtPath(AssetDatabase.GUIDToAssetPath(l1Lightmap));
                    
                    // Force enable "High quality compression", which in turn enables BC7 on PC
                    importer.textureCompression = TextureImporterCompression.CompressedHQ;

                    // Set Android to ASTC (6x6)
                    var androidImporter = importer.GetPlatformTextureSettings("Android");
                    androidImporter.overridden = true;
                    androidImporter.format = TextureImporterFormat.ASTC_6x6;
                    
                    // Apply changes
                    importer.SetPlatformTextureSettings(androidImporter);
                    importer.SaveAndReimport();
                }
            }
        }
        
        private static bool ReadFromProjectSettings(string prop, bool defaultValue = false) {

            var hekkySettingsManager = HekkySettings.GetSerializedSettings();
            SerializedProperty m_bakeryForceMonoShHighQuality = hekkySettingsManager.FindProperty(prop);
            return m_bakeryForceMonoShHighQuality?.boolValue ?? defaultValue;
        }

        private static void WriteToProjectSettings(string prop, bool val) {

            var hekkySettingsManager = HekkySettings.GetSerializedSettings();
            SerializedProperty m_bakeryForceMonoShHighQuality = hekkySettingsManager.FindProperty(prop);
            m_bakeryForceMonoShHighQuality.boolValue = val;
            hekkySettingsManager.ApplyModifiedProperties();
        }
    }
}
#endif
#endif