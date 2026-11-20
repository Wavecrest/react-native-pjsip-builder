/* pjproject build options for iOS.
 *
 * The sample's PJ_CONFIG_IPHONE block is applied first; the defines after it
 * override or extend it. (Defining a value before the include does not work:
 * the sample's plain #define replaces it.)
 */
#define PJ_CONFIG_IPHONE 1
#include <pj/config_site_sample.h>

#define PJMEDIA_HAS_VIDEO 0

/* Codecs: the app enables only opus, iLBC and G.711 (every other codec has
 * priority 0 and is never offered), so the rest is not built. L16 is already
 * disabled by the sample; G.722.1 and G.729 (bcg729) are off by default. */
#define PJMEDIA_HAS_SPEEX_CODEC 0
#define PJMEDIA_HAS_GSM_CODEC 0
#define PJMEDIA_HAS_G722_CODEC 0

#define PJSIP_AUTH_AUTO_SEND_NEXT 1
#define PJ_HAS_SSL_SOCK 1
