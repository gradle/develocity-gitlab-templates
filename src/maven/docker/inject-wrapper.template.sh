#!/usr/bin/env bash
# interface of this script, should use corresponding env vars
allowUntrustedServer=${ALLOW_UNTRUSTED_SERVER:-false}
shortLivedTokensExpiry=${SHORT_LIVED_TOKEN_EXPIRY:-2}
enforceUrl=${ENFORCE_URL:false}
captureFileFingerprints=${CAPTURE_FILE_FINGERPRINTS:-true}
customMavenExtensionCoordinates=${CUSTOM_MAVEN_EXTENSION_COORDINATES}
customCcudCoordinates=${CUSTOM_CCUD_COORDINATES}
url=${DEVELOCITY_URL}

<<DEVELOCITY_INJECTION_SCRIPT_MAVEN>>
<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>

createShortLivedToken "${url}" "${shortLivedTokensExpiry}"
injectDevelocityForMaven "${PWD}"
echo "Injecting Develocity MAVEN_OPTS=${MAVEN_OPTS}"

exec "$@"
