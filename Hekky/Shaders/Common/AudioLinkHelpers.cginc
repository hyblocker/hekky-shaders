#ifndef HEKKY_COMMON_AL_HELPERS
#define HEKKY_COMMON_AL_HELPERS

// Check if AL has been imported
#if !defined(ALPASS_DFT) && (defined(_AUDIOLINK))
    #include "Packages/AudioLink/Runtime/Shaders/AudioLink.cginc"
#endif

// AudioLink Debug variables
fixed _AudioLink;
fixed _AudioLinkDebug;
fixed _AudioLinkDebugBass;
fixed _AudioLinkDebugLowMid;
fixed _AudioLinkDebugHighMid;
fixed _AudioLinkDebugTreble;

bool audioLinkEnabled()
{
    #ifdef ALPASS_DFT
    return (AudioLinkIsAvailable() && _AudioLink == 1) || _AudioLinkDebug == 1;
    #else
    return false;
    #endif
}

float getAudioLinkValue(int audioLinkBand)
{
    #if defined(ALPASS_DFT)
    if (audioLinkEnabled())
    {
        if (_AudioLinkDebug == 1)
        {
            switch (audioLinkBand)
            {
            default:
                return _AudioLinkDebugBass;
            case 1:
                return _AudioLinkDebugLowMid;
            case 2:
                return _AudioLinkDebugHighMid;
            case 3:
                return _AudioLinkDebugTreble;
            }
        }
        else
        {
            switch (audioLinkBand)
            {
            default:
                return AudioLinkData(ALPASS_AUDIOLINK + int2( 0, 0 )).r;
            case 1:
                return AudioLinkData(ALPASS_AUDIOLINK + int2( 0, 1 )).r;
            case 2:
                return AudioLinkData(ALPASS_AUDIOLINK + int2( 0, 2 )).r;
            case 3:
                return AudioLinkData(ALPASS_AUDIOLINK + int2( 0, 3 )).r;
            }
        }
    }

    return 0.f;
    #else
    return 0.f;
    #endif
}

#endif // HEKKY_COMMON_AL_HELPERS
