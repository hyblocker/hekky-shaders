#ifndef HEKKY_COMMON_VRC_MISC
#define HEKKY_COMMON_VRC_MISC

/*
Introduced in VRC 2022.3.1 :: https://docs.vrchat.com/docs/vrchat-202231
# SDK
## Features

- Added 3 shader globals that can be accessed by any avatar or world shader:
    - `float _VRChatCameraMode`:
        - `0` - Rendering normally
        - `1` - Rendering in VR handheld camera
        - `2` - Rendering in Desktop handheld camera
        - `3` - Rendering for a screenshot
    - `float _VRChatMirrorMode`:
        - `0` - Rendering normally, not in a mirror
        - `1` - Rendering in a mirror viewed in VR
        - `2` - Rendering in a mirror viewed in desktop mode
    - `float3 _VRChatMirrorCameraPos` - World space position of mirror camera (eye independent, "centered" in VR)
*/

float _VRChatCameraMode;
float _VRChatMirrorMode;
float3 _VRChatMirrorCameraPos;

static const float VRCHAT_CAMERA_MODE_NORMAL                = 0;
static const float VRCHAT_CAMERA_MODE_VR_HAND_CAMERA        = 1;
static const float VRCHAT_CAMERA_MODE_DESKTOP_HAND_CAMERA   = 2;
static const float VRCHAT_CAMERA_MODE_SCREENSHOT            = 3;

static const float VRCHAT_MIRROR_MODE_NONE                  = 0;
static const float VRCHAT_MIRROR_MODE_VR                    = 1;
static const float VRCHAT_MIRROR_MODE_DESKTOP               = 2;

inline bool isVR() {
    // USING_STEREO_MATRICES
    #if UNITY_SINGLE_PASS_STEREO
        return true;
    #else
        return false;
    #endif
}

inline bool isVRHandCamera() {
    return (_VRChatCameraMode == VRCHAT_CAMERA_MODE_VR_HAND_CAMERA) || (_VRChatCameraMode == VRCHAT_CAMERA_MODE_DESKTOP_HAND_CAMERA);
    // return !isVR() && abs(UNITY_MATRIX_V[0].y) > 0.0000005;
}

inline bool isDesktop() {
    return !isVR() && abs(UNITY_MATRIX_V[0].y) < 0.0000005;
}

inline bool isVRHandCameraPreview() {
    return isVRHandCamera() && _ScreenParams.y == 720;
}

inline bool isVRHandCameraPicture() {
    return isVRHandCamera() && _ScreenParams.y == 1080;
}

inline bool isCameraNormal() {
    return _VRChatCameraMode == VRCHAT_CAMERA_MODE_NORMAL;
}

inline bool isCameraScreenshot() {
    return _VRChatCameraMode == VRCHAT_CAMERA_MODE_SCREENSHOT;
}

inline bool isHandCameraVR() {
    return _VRChatCameraMode == VRCHAT_CAMERA_MODE_VR_HAND_CAMERA;
}

inline bool isHandCameraDesktop() {
    return _VRChatCameraMode == VRCHAT_CAMERA_MODE_DESKTOP_HAND_CAMERA;
}

inline bool isPanorama() {
    // Crude method
    // FOV=90=camproj=[1][1]
    return unity_CameraProjection[1][1] == 1 && _ScreenParams.x == 1075 && _ScreenParams.y == 1025;
}

inline bool isInMirror()
{
    return _VRChatMirrorMode > VRCHAT_MIRROR_MODE_NONE;
    // return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

#endif