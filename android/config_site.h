/* pjproject build options for Android.
 *
 * The sample's PJ_CONFIG_ANDROID block is applied first; the defines after it
 * override or extend it. (Defining a value before the include does not work:
 * the sample's plain #define replaces it.)
 */
#define PJ_ANDROID 1
#define PJ_CONFIG_ANDROID 1
#include <pj/config_site_sample.h>

#define PJ_HAS_STDINT_H 1
#define PJ_HAS_SYS_TIME_H 1

/* Audio device: the sample selects the Android JNI backend (AudioRecord with
 * VOICE_COMMUNICATION, AudioTrack on STREAM_VOICE_CALL) and disables OpenSL.
 * Earlier builds asked for OpenSL, but the sample overrode it, so JNI is what
 * has always shipped. It needs pjlib's JNI_OnLoad (PJ_JNI_HAS_JNI_ONLOAD). */

/* Every arm64-v8a and armeabi-v7a device has an FPU; the sample's fixed-point
 * default dates from ARMv5. Affects local DSP only (echo canceller, resampling). */
#undef PJ_HAS_FLOATING_POINT
#define PJ_HAS_FLOATING_POINT 1

#define PJMEDIA_HAS_VIDEO 0

/* Codecs: the app enables only opus, iLBC and G.711 (every other codec has
 * priority 0 and is never offered), so the rest is not built. L16 is already
 * disabled by the sample; G.722.1 and G.729 (bcg729) are off by default. */
#define PJMEDIA_HAS_SPEEX_CODEC 0
#define PJMEDIA_HAS_GSM_CODEC 0
#define PJMEDIA_HAS_G722_CODEC 0

#define PJSIP_AUTH_AUTO_SEND_NEXT 1
#define PJ_HAS_SSL_SOCK 1
