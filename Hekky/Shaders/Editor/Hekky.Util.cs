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
        /// Loads a shader with the specified name
        /// </summary>
        public static Shader FetchShaderByName(string name)
        {
            var shaderGuid = AssetDatabase.FindAssets($"{name} t:shader")[0];
            return AssetDatabase.LoadAssetAtPath<Shader>(AssetDatabase.GUIDToAssetPath(shaderGuid));
        }
        
        /// <summary>
        /// Loads a compute shader with the specified name
        /// </summary>
        public static ComputeShader FetchComputeShaderByName(string name)
        {
            var shaderGuid = AssetDatabase.FindAssets($"{name} t:computeshader")[0];
            return AssetDatabase.LoadAssetAtPath<ComputeShader>(AssetDatabase.GUIDToAssetPath(shaderGuid));
        }

        public static Texture2D FetchTexture2DByName(string name)
        {
            var texture2dGuid = AssetDatabase.FindAssets($"{name} t:Texture2D")[0];
            return AssetDatabase.LoadAssetAtPath<Texture2D>(AssetDatabase.GUIDToAssetPath(texture2dGuid));
        }

        static RenderTexture Copy3DSliceToRenderTexture(RenderTexture source, int layer, int width, int height)
        {
            RenderTexture render = new RenderTexture(width, height, 0, source.format);
            render.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
            render.enableRandomWrite = true;
            render.wrapMode = TextureWrapMode.Clamp;
            render.useMipMap = false;
            render.filterMode = FilterMode.Bilinear;
            render.Create();

            var shader = FetchComputeShaderByName("Tex3DSliceView");
            
            int kernelIndex = shader.FindKernel("CSSliceLayer");
            shader.SetTexture(kernelIndex, "Tex3DIn", source);
            shader.SetInt("Layer", layer);
            shader.SetTexture(kernelIndex, "Result2D", render);
            shader.Dispatch(kernelIndex, width, height, 1);

            return render;
        }

        static Texture2D ConvertFromRenderTexture(RenderTexture rt, int width, int height)
        {
            Texture2D output = new Texture2D(width, height);
            RenderTexture.active = rt;
            output.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            output.Apply();
            return output;
        }

        public static Texture3D SaveComputeTexture3D(RenderTexture renderTexture, int width, int height, int depth, string name, bool write = true)
        {
            RenderTexture[] layers = new RenderTexture[depth];
            for (int i = 0; i < depth; i++)
                layers[i] = Copy3DSliceToRenderTexture(renderTexture, i, width, height);

            Texture2D[] finalSlices = new Texture2D[depth];
            for (int i = 0; i < depth; i++)
                finalSlices[i] = ConvertFromRenderTexture(layers[i], width, height);

            Texture3D output = new Texture3D(width, height, depth, TextureFormat.ARGB32, false);
            output.filterMode = FilterMode.Trilinear;

            /*
            Color[] outputPixels = output.GetPixels();
            
            for (int k = 0; k < depth; k++)
            {
                Color[] layerPixels = finalSlices[k].GetPixels();
                for (int i = 0; i < width; i++)
                for (int j = 0; j < height; j++)
                {
                    outputPixels[i + j * width + k * width * depth] = layerPixels[i + j * width];
                }
            }
            */
            
            for (int z = 0; z < depth; z++)
            {
                //get the texture2D slice
                Texture2D slice = finalSlices[z];
 
                //iterate for the x axis
                for (int x = 0; x <  width; x++)
                {
                    //iterate for the y axis
                    for (int y = 0; y <  height; y++)
                    {
                        //get the color corresponding to the x and y resolution
                        Color singleColor = slice.GetPixel(x, y);
 
                        //apply the color corresponding to the slice we are on, and the x and y pixel of that slice.
                        output.SetPixel(x, y, z, singleColor);
                    }
                }
            }

            // output.SetPixels(outputPixels);
            output.Apply();

            if (write)
                AssetDatabase.CreateAsset(output, "Assets/" + name + ".asset");
            
            return output;
        }
    }

    public static class HekkyConstants {
        public static readonly string DiscordURL = "https://discord.gg/YWN7Z9T8DP";

        public static readonly string PatreonURL = "https://patreon.com/hyblocker";
        // public static readonly string DocumentationURL = "https://docs.hyblocker.dev/en/shaders/hekky-pbr/reference";
    }
}