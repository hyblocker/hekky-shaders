using UnityEditor;
using UnityEngine;

namespace Hekky {
    public static class HekkySSR {

        public static void OnToggleSSR(bool newState, HekkyMaterialProperty property, MaterialEditor materialEditor, Material material) {
            material.SetShaderPassEnabled("GRABPASS", newState);
            material.SetOverrideTag("RenderType", newState ? "Transparent" : "Opaque");
            material.renderQueue = newState ? 2500 : 2000;
        }
    }
}
