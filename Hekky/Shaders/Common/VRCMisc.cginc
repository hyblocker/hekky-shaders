#ifndef HEKKY_COMMON_VRC_MISC
#define HEKKY_COMMON_VRC_MISC

inline bool isVR() {
    // USING_STEREO_MATRICES
    #if UNITY_SINGLE_PASS_STEREO
    return true;
    #else
    return false;
    #endif
}

inline bool isVRHandCamera() {
    return !isVR() && abs(UNITY_MATRIX_V[0].y) > 0.0000005;
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

inline bool isPanorama() {
    // Crude method
    // FOV=90=camproj=[1][1]
    return unity_CameraProjection[1][1] == 1 && _ScreenParams.x == 1075 && _ScreenParams.y == 1025;
}

inline bool isInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

#endif