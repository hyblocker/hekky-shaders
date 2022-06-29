using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace Hekky {
    /// <summary>
    /// A helper class for dealing with Texture assets
    /// </summary>
    public static class TextureUtils {
        private const string NormalMapComputeShaderName = "NormalConvert";

        /// <summary>
        /// Loads an uncompressed Texture asset. This doesn't go through Unity's regular pipeline, avoiding sRGB and compression.
        /// </summary>
        public static Texture2D LoadTextureRAW(Texture2D original, string path) {
            // The unity "LoadImage" extension method only supports PNG and JPEG
            if ( path.EndsWith(".png") || path.EndsWith(".jpeg") || path.EndsWith(".jpg") ) {
                Texture2D rawTexture =
                    new Texture2D(original.width, original.height, TextureFormat.ARGB32, false, true);
                rawTexture.LoadImage(File.ReadAllBytes(path));
                return rawTexture;
            }

            // TODO: FUCKING STB_IMAGE_SHARP :kms: (allows us to also use a fuck load of formats that coincidentally Unity supports

            return original;
        }

        #region Normal map conversion

        [MenuItem("Assets/Convert/Normal map (GL 🡸🡺 DX)")]
        private static void ConvertNormalMap() {
            // Load the texture, (with compression ; mainly for metadata)
            var texture = ( Texture2D ) Selection.activeObject;
            // Proceed to attempt loading the uncompressed texture now
            var assetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
            var uncompressedTexture = LoadTextureRAW(texture, assetPath);

            // Texture buffer because we can't use Graphics.Blit()
            var renderBuffer = new RenderTexture(texture.width, texture.height, 24, RenderTextureFormat.ARGB32,
                RenderTextureReadWrite.Linear);
            renderBuffer.enableRandomWrite = true;
            renderBuffer.filterMode = texture.filterMode;
            renderBuffer.Create();

            // find the compute shader, set it's params, and dispatch it
            var computeShader = HekkyUtil.FetchComputeShaderByName(NormalMapComputeShaderName);
            computeShader.SetTexture(0, "Result", renderBuffer);
            computeShader.SetTexture(0, "NormalRaw", uncompressedTexture);
            computeShader.SetFloat("Width", texture.width);
            computeShader.SetFloat("Height", texture.height);

            computeShader.Dispatch(0, texture.width / 8 + 1, texture.height / 8 + 1, 1);

            // Convert back to Texture2D
            var tex2DOut = new Texture2D(texture.width, texture.height, TextureFormat.ARGB32, true, true);
            RenderTexture.active = renderBuffer;
            tex2DOut.ReadPixels(new Rect(0, 0, texture.width, texture.height), 0, 0);
            tex2DOut.Apply(true);

            // Save !
            var newPath = Path.Combine(Path.GetDirectoryName(assetPath) ?? Directory.GetCurrentDirectory(),
                Path.GetFileNameWithoutExtension(assetPath) + "_Converted.png");
            var pngBytes = tex2DOut.EncodeToPNG();
            File.WriteAllBytes(newPath, pngBytes);
            AssetDatabase.ImportAsset(newPath);
            tex2DOut = ( Texture2D ) AssetDatabase.LoadAssetAtPath<Texture>(newPath);

            // TODO: Abstract to function
            // Copy texture import settings
            TextureImporter importer = ( TextureImporter ) AssetImporter.GetAtPath(newPath);
            TextureImporter originalTextureImporter = ( TextureImporter ) AssetImporter.GetAtPath(assetPath);

            importer.textureType = originalTextureImporter.textureType;
            importer.textureShape = originalTextureImporter.textureShape;
            importer.normalmapFilter = originalTextureImporter.normalmapFilter;
            importer.alphaSource = originalTextureImporter.alphaSource;
            importer.alphaIsTransparency = originalTextureImporter.alphaIsTransparency;

            importer.sRGBTexture = originalTextureImporter.sRGBTexture;

            importer.isReadable = originalTextureImporter.isReadable;
            importer.streamingMipmaps = originalTextureImporter.streamingMipmaps;
            importer.mipmapEnabled = originalTextureImporter.mipmapEnabled;

            importer.borderMipmap = originalTextureImporter.borderMipmap;
            importer.mipmapFilter = originalTextureImporter.mipmapFilter;
            importer.mipMapsPreserveCoverage = originalTextureImporter.mipMapsPreserveCoverage;
            importer.fadeout = originalTextureImporter.fadeout;

            importer.wrapMode = originalTextureImporter.wrapMode;
            importer.wrapModeU = originalTextureImporter.wrapModeU;
            importer.wrapModeV = originalTextureImporter.wrapModeV;
            importer.wrapModeW = originalTextureImporter.wrapModeW;
            importer.filterMode = originalTextureImporter.filterMode;
            importer.anisoLevel = originalTextureImporter.anisoLevel;

            importer.textureCompression = originalTextureImporter.textureCompression;
            importer.compressionQuality = originalTextureImporter.compressionQuality;
            importer.crunchedCompression = originalTextureImporter.crunchedCompression;
            importer.userData = originalTextureImporter.userData;
            importer.SaveAndReimport();
        }

        // Disable on anything but textures marked as normal map
        // [MenuItem("Assets/Convert/Normal map (GL <=> DX)", true)]
        [MenuItem("Assets/Convert/Normal map (GL 🡸🡺 DX)", true)]
        private static bool ConvertNormalMapValidation() {
            if ( Selection.activeObject is Texture ) {
                var assetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
                TextureImporter importer = ( TextureImporter ) AssetImporter.GetAtPath(assetPath);
                return importer.textureType == TextureImporterType.NormalMap;
            }

            return false;
        }

        #endregion
    }
}