#if UNITY_EDITOR

using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.PackageManager.Requests;
using UnityEditor.PackageManager;
using Debug = UnityEngine.Debug;
#if UNITY_POST_PROCESSING_STACK_V2
using UnityEngine.Rendering.PostProcessing;
#endif


namespace Hekky {
    /// <summary>
    /// Setups post processing assets in your project
    /// </summary>
    public class PostProcessingGen : EditorWindow {
#if UNITY_POST_PROCESSING_STACK_V2
        private const bool postProcessingStackAvailable = true;
#else
        private const bool postProcessingStackAvailable = false;
#endif

        [MenuItem("Hekky/Setup Post Processing", false, 1)]
        static void Init() {
            // Get existing open window or if none, make a new one:
            PostProcessingGen window = ( PostProcessingGen ) GetWindow(typeof(PostProcessingGen));
            window.Show();
        }

        [MenuItem("Hekky/Setup Post Processing", true, 1)]
        static bool PostProcessingValidator() {
#if UNITY_POST_PROCESSING_STACK_V2
            ScriptableObject postProcessingAsset = GetPostProcessingAsset();
            bool isPostProcessingAssetSetup = postProcessingAsset != null;
            bool isScenePostProcessingSetup = SceneHasPostProcessingSetup();

            return !( isPostProcessingAssetSetup && isScenePostProcessingSetup &&
                      PlayerSettings.colorSpace == ColorSpace.Linear );
#else
            return true;
#endif
        }

        private void OnEnable() {
            titleContent = new GUIContent("Post Processing Setup");
        }

        void OnGUI() {
            GUILayout.Space(16);
#if !UNITY_POST_PROCESSING_STACK_V2
            EditorGUILayout.HelpBox("The Unity Post Processing Stack couldn't be found in this project. Post processing requires this package to be imported.", MessageType.Warning);
            GUILayout.Space(16);
            if (GUILayout.Button("Import Post Processing Stack")) {
                Import_PPv2();
            }
#else

            ScriptableObject postProcessingAsset = GetPostProcessingAsset();

            bool isPostProcessingAssetSetup = postProcessingAsset != null;
            bool isScenePostProcessingSetup = SceneHasPostProcessingSetup();

            if ( PlayerSettings.colorSpace != ColorSpace.Linear ) {
                EditorGUILayout.HelpBox(
                    "This project is not using linear colour space. PBR rendering requires linear colour space to function properly.",
                    MessageType.Warning);
                GUILayout.Space(16);

                if ( GUILayout.Button("Convert project to linear colour space") ) {
                    PlayerSettings.colorSpace = ColorSpace.Linear;
                }
            }

            if ( !isPostProcessingAssetSetup ) {
                EditorGUILayout.HelpBox("Couldn't find a Post Processing asset in the current Unity Project.",
                    MessageType.Warning);
                GUILayout.Space(16);

                if ( GUILayout.Button("Generate profile") ) {
                    GeneratePostProcessingAsset();
                }
            }

            if ( !isScenePostProcessingSetup ) {
                EditorGUILayout.HelpBox("Post processing isn't set up in this scene.", MessageType.Warning);
                GUILayout.Space(16);

                EditorGUI.BeginDisabledGroup(!isPostProcessingAssetSetup);

                if ( GUILayout.Button("Setup post-processing") ) {
                    SetupScenePostProcessing(postProcessingAsset);
                }

                EditorGUI.EndDisabledGroup();
            }

            if ( isPostProcessingAssetSetup && isScenePostProcessingSetup &&
                 PlayerSettings.colorSpace == ColorSpace.Linear ) {
                GUILayout.Label("Post Processing is set-up correctly!\n\n\nYou can close this window.",
                    HGUI.LabelWordWrapCenter);
            }
#endif
        }

        /// <summary>
        /// Returns the first Post Processing Profile in the project
        /// </summary>
        static ScriptableObject GetPostProcessingAsset() {
            var assets = AssetDatabase.FindAssets("t:PostProcessProfile");
            return assets.Length != 0
                ? AssetDatabase.LoadAssetAtPath<ScriptableObject>(AssetDatabase.GUIDToAssetPath(assets[0]))
                : null;
        }

#if UNITY_POST_PROCESSING_STACK_V2
        /// <summary>
        /// Returns all <see cref="GameObject"/>s on the specified <see cref="LayerMask"/>
        /// </summary>
        static GameObject[] FindGamePostProcessingVolumeInLayer(int layer) {
            var goArray = FindObjectsOfType(typeof(PostProcessVolume)) as PostProcessVolume[];
            var goList = new List<GameObject>();
            for ( int i = 0; i < goArray.Length; i++ ) {
                if ( ( layer & ( 1 << goArray[i].gameObject.layer ) ) != 0 )
                    // if (goArray[i].gameObject.layer == layer)
                {
                    goList.Add(goArray[i].gameObject);
                }
            }

            if ( goList.Count == 0 ) {
                return null;
            }

            return goList.ToArray();
        }

        /// <summary>
        /// Returns if the scene has Post Processing setup
        /// </summary>
        static bool SceneHasPostProcessingSetup() {

            var sceneCam = GameObject.FindGameObjectWithTag("MainCamera");
            var scenePostLayer = sceneCam.GetComponent<PostProcessLayer>();
            if ( scenePostLayer == null )
                return false;

            var layerMask = scenePostLayer.volumeLayer;
            var candidatePostProcessingVolumes = FindGamePostProcessingVolumeInLayer(layerMask);
            if ( candidatePostProcessingVolumes == null )
                return false;

            for ( int i = 0; i < candidatePostProcessingVolumes.Length; i++ ) {
                var volumeComponent = candidatePostProcessingVolumes[i].GetComponent<PostProcessVolume>();
                if ( volumeComponent != null && volumeComponent.sharedProfile != null ) {
                    return true;
                }
            }

            return false;
        }

        void SetupScenePostProcessing(ScriptableObject postProcessingAsset) {

            var sceneCam = GameObject.FindGameObjectWithTag("MainCamera");
            var scenePostLayer = sceneCam.GetComponent<PostProcessLayer>();
            if ( scenePostLayer == null ) {
                scenePostLayer = sceneCam.gameObject.AddComponent<PostProcessLayer>();
            }

            // set props
            var waterLayerMask = LayerMask.NameToLayer("Water"); // Use the Water layer bc its practically unused LOL
            scenePostLayer.volumeLayer = 1 << waterLayerMask;
            scenePostLayer.volumeTrigger = sceneCam.transform;
            scenePostLayer.antialiasingMode = PostProcessLayer.Antialiasing.None;
            scenePostLayer.stopNaNPropagation = true;
            scenePostLayer.finalBlitToCameraTarget = false;

            // Fetch obj on Water layer
            var candidatePostProcessingVolumes = FindGamePostProcessingVolumeInLayer(waterLayerMask);
            if ( candidatePostProcessingVolumes == null ) {
                var postVolume = new GameObject();
                postVolume.transform.name = "Post Processing";
                postVolume.transform.parent = sceneCam.transform.parent;
                postVolume.transform.localPosition = Vector3.zero;
                postVolume.transform.localRotation = Quaternion.identity;
                postVolume.transform.localScale = Vector3.one;
                postVolume.layer = waterLayerMask;
                candidatePostProcessingVolumes = new[] {postVolume};
            }

            // Fetch volume component
            var postVolumeComponent = candidatePostProcessingVolumes[0].GetComponent<PostProcessVolume>();
            if ( postVolumeComponent == null ) {
                postVolumeComponent = candidatePostProcessingVolumes[0].AddComponent<PostProcessVolume>();
            }

            postVolumeComponent.isGlobal = true;
            postVolumeComponent.weight = 1f;
            postVolumeComponent.priority = 0f;
            postVolumeComponent.sharedProfile = ( PostProcessProfile ) postProcessingAsset;
        }

        ScriptableObject GeneratePostProcessingAsset() {

            PostProcessProfile asset = CreateInstance<PostProcessProfile>();

            AutoExposure autoExposureSettings = CreateInstance<AutoExposure>();
            autoExposureSettings.enabled.overrideState = true;
            autoExposureSettings.enabled.value = true;

            ColorGrading tonemappingSettings = CreateInstance<ColorGrading>();
            tonemappingSettings.enabled.overrideState = true;
            tonemappingSettings.enabled.value = true;
            tonemappingSettings.gradingMode.overrideState = true;
            tonemappingSettings.gradingMode.value = GradingMode.HighDefinitionRange;
            tonemappingSettings.tonemapper.overrideState = true;
            tonemappingSettings.tonemapper.value = Tonemapper.ACES;

            Bloom bloomSettings = CreateInstance<Bloom>();
            bloomSettings.enabled.overrideState = true;
            bloomSettings.enabled.value = true;
            bloomSettings.intensity.overrideState = true;
            bloomSettings.intensity.value = 0.15f;
            bloomSettings.threshold.overrideState = true;
            bloomSettings.threshold.value = 0f;
            bloomSettings.softKnee.overrideState = true;
            bloomSettings.softKnee.value = 0f;
            bloomSettings.clamp.overrideState = true;
            bloomSettings.clamp.value = 100f;
            bloomSettings.diffusion.overrideState = true;
            bloomSettings.diffusion.value = 10f;

            asset.AddSettings(autoExposureSettings);
            asset.AddSettings(tonemappingSettings);
            asset.AddSettings(bloomSettings);

            AssetDatabase.CreateAsset(asset, "Assets/Hekky-PostProcessingProfile.asset");
            AssetDatabase.SaveAssets();

            EditorUtility.FocusProjectWindow();
            Selection.activeObject = asset;

            return asset;
        }
#endif

#if !UNITY_POST_PROCESSING_STACK_V2
        static AddRequest m_ppv2ImportRequest;

        static void Import_PPv2() {
            // Add a package to the project
            m_ppv2ImportRequest = Client.Add("com.unity.postprocessing");
            EditorApplication.update += Progress;
        }
        
        static void Progress()
        {
            if (m_ppv2ImportRequest.IsCompleted)
            {
                if (m_ppv2ImportRequest.Status == StatusCode.Success)
                    Debug.Log("Successfully Installed: " + m_ppv2ImportRequest.Result.packageId);
                else if (m_ppv2ImportRequest.Status >= StatusCode.Failure)
                    Debug.Log(m_ppv2ImportRequest.Error.message);

                EditorApplication.update -= Progress;
            }
        }
#endif
    }
}

#endif