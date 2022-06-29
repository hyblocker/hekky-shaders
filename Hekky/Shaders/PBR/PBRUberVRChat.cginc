#ifndef HEKKY_PBR_UBER_VRCHAT
#define HEKKY_PBR_UBER_VRCHAT

// patches data so that the surfaces look good regardless of culling settings
#define PATCH_INPUT_DATA(input, facing) \
    input.normal *= facing ? 1 : -1; \
    input.tangent *= facing ? 1 : -1; \
    input.binormal *= facing ? 1 : -1;

#endif // HEKKY_PBR_UBER_VRCHAT