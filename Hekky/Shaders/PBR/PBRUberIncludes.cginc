#ifndef HEKKY_PBR_UBER_DEFINES
#define HEKKY_PBR_UBER_DEFINES

#include "PBRUberKeywordDefines.cginc"

// Unity Helper functions
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityPBSLighting.cginc"

// Common files
#include "../Common/Sampling.cginc"
#include "../Common/VRCMisc.cginc"
#include "../Common/AudioLinkHelpers.cginc"
#include "../Common/UnityUtils.cginc"
#include "../Common/Lighting.cginc"
#include "../Common/Blending.cginc"

// PBR Uber files
#include "PBRUberVariables.cginc"
#include "PBRUberToonFunc.cginc"
#include "PBRUberStructures.cginc"
#include "PBRUberUtils.cginc"
#include "PBRUberAO.cginc"
#include "PBRUberMatcap.cginc"
#include "PBRUberBRDF.cginc"
// SSR only
#if SSR
    #include "PBRUberSSR.cginc"
#endif // SSR
#include "PBRUberLightingLTCGI.cginc"
#include "PBRUberLighting.cginc"
#include "PBRUberPassStructures.cginc"
#include "PBRUberPOM.cginc"
#include "PBRUberSetups.cginc"

// Outline only
#if OUTLINE
    #include "PBRUberOutline.cginc"
#endif // OUTLINE

// Imported after all PBR methods so that we have access to structs
#include "../Common/UnityStandardUtil.cginc"

// Passes go last because of dependency chains
#include "PBRUberPasses.cginc"

#endif // HEKKY_PBR_UBER_DEFINES