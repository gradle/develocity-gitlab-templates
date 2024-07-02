#!/usr/bin/env bash
# interface of this script, should use corresponding env vars
allowUntrustedServer=${DEVELOCITY_ALLOW_UNTRUSTED_SERVER:-false}
shortLivedTokensExpiry=${DEVELOCITY_SHORT_LIVED_TOKEN_EXPIRY:-2}
enforceUrl=${DEVELOCITY_ENFORCE_URL:false}
captureFileFingerprints=${DEVELOCITY_CAPTURE_FILE_FINGERPRINTS:-true}
customMavenExtensionCoordinates=${DEVELOCITY_CUSTOM_MAVEN_EXTENSION_COORDINATES}
customCcudCoordinates=${DEVELOCITY_CUSTOM_CCUD_COORDINATES}
url=${DEVELOCITY_URL}

<<DEVELOCITY_INJECTION_SCRIPT_MAVEN>>

<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>

createShortLivedToken "${url}" "${shortLivedTokensExpiry}"
injectDevelocityForMaven "${PWD}"
echo "Injecting Develocity MAVEN_OPTS=${MAVEN_OPTS}"

exec "$@"
