using System;
using UnityEditor;
using UnityEngine;

namespace Hekky {
    public static class HekkyUtil
    {
        public static bool TestBitwiseFlag(object value, object flag)
        {
            return ((int) value & (int) flag) == (int) flag;
        }

        /// <summary>
        /// Loads a compute shader with the specified name
        /// </summary>
        public static ComputeShader FetchComputeShaderByName(string name)
        {
            var shaderGuid = AssetDatabase.FindAssets($"{name} t:computeshader")[0];
            return AssetDatabase.LoadAssetAtPath<ComputeShader>(AssetDatabase.GUIDToAssetPath(shaderGuid));
        }

        static RenderTexture Copy3DSliceToRenderTexture(RenderTexture source, int layer, int size)
        {
            RenderTexture render = new RenderTexture(size, size, 0, RenderTextureFormat.ARGB32);
            render.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
            render.enableRandomWrite = true;
            render.wrapMode = TextureWrapMode.Clamp;
            render.Create();

            var shader = FetchComputeShaderByName("Tex3DSliceView");
            
            int kernelIndex = shader.FindKernel("CSSliceLayer");
            shader.SetTexture(kernelIndex, "Tex3DIn", source);
            shader.SetInt("Resolution", layer);
            shader.SetTexture(kernelIndex, "Result2D", render);
            shader.Dispatch(kernelIndex, size, size, 1);

            return render;
        }

        static Texture2D ConvertFromRenderTexture(RenderTexture rt, int size)
        {
            Texture2D output = new Texture2D(size, size);
            RenderTexture.active = rt;
            output.ReadPixels(new Rect(0, 0, size, size), 0, 0);
            output.Apply();
            return output;
        }

        public static void SaveComputeTexture3D(RenderTexture renderTexture, int size, string name)
        {
            RenderTexture[] layers = new RenderTexture[size];
            for (int i = 0; i < size; i++)
                layers[i] = Copy3DSliceToRenderTexture(renderTexture, i, size);

            Texture2D[] finalSlices = new Texture2D[size];
            for (int i = 0; i < size; i++)
                finalSlices[i] = ConvertFromRenderTexture(layers[i], size);

            Texture3D output = new Texture3D(size, size, size, TextureFormat.ARGB32, true);
            output.filterMode = FilterMode.Trilinear;
            Color[] outputPixels = output.GetPixels();

            for (int k = 0; k < size; k++)
            {
                Color[] layerPixels = finalSlices[k].GetPixels();
                for (int i = 0; i < size; i++)
                for (int j = 0; j < size; j++)
                {
                    outputPixels[i + j * size + k * size * size] = layerPixels[i + j * size];
                }
            }

            output.SetPixels(outputPixels);
            output.Apply();

            AssetDatabase.CreateAsset(output, "Assets/" + name + ".asset");
        }
    }

    public static class HekkyConstants {
        public static readonly string DiscordURL = "https://discord.gg/YWN7Z9T8DP";

        public static readonly string PatreonURL = "https://patreon.com/hyblocker";
        // public static readonly string DocumentationURL = "https://docs.hyblocker.dev/en/shaders/hekky-pbr/reference";
    }
}