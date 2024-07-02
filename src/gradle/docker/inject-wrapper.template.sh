#!/usr/bin/env bash
shortLivedTokensExpiry=${DEVELOCITY_SHORT_LIVED_TOKEN_EXPIRY:-2}
url=${DEVELOCITY_URL}

<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>

createShortLivedToken "${url}" "${shortLivedTokensExpiry}"

exec "$@"
