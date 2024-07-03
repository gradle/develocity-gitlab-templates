#!/usr/bin/env bash
# interface of this script, should use corresponding env vars
allowUntrustedServer=${DEVELOCITY_ALLOW_UNTRUSTED_SERVER:-false}
shortLivedTokensExpiry=${DEVELOCITY_SHORT_LIVED_TOKEN_EXPIRY:-2}
enforceUrl=${DEVELOCITY_ENFORCE_URL:false}
captureFileFingerprints=${DEVELOCITY_CAPTURE_FILE_FINGERPRINTS:-true}
customMavenExtensionCoordinates=${DEVELOCITY_CUSTOM_MAVEN_EXTENSION_COORDINATES}
customCcudCoordinates=${DEVELOCITY_CUSTOM_CCUD_COORDINATES}
url=${DEVELOCITY_URL}

function createTmp() {
  export TMP_DV=$(mktemp -d develocity.XXXXXX --tmpdir="${CI_PROJECT_DIR}")
}

function isAtLeast() {
  local v1=$(printf "%03d%03d%03d%03d" $(echo "$1" | cut -f1 -d"-" | tr '.' ' '))
  local v2=$(printf "%03d%03d%03d%03d" $(echo "$2" | cut -f1 -d"-" | tr '.' ' '))
  if [ "$v1" -eq "$v2" ] || [ "$v1" -gt "$v2" ]
  then
    echo "true"
  else
    echo "false"
  fi
}

function downloadDvCcudExt() {
  local ext_path="${TMP_DV}/common-custom-user-data-maven-extension.jar"
  curl -s "${mavenRepo}/com/gradle/common-custom-user-data-maven-extension/${ccudMavenExtensionVersion}/common-custom-user-data-maven-extension-${ccudMavenExtensionVersion}.jar" -o "${ext_path}"
  export CCUD_EXT_PATH="${ext_path}"
}

function downloadDvMavenExt() {
  local ext_path
  if [ "$(isAtLeast $mavenExtensionVersion 1.21)" = "true" ]
  then
    ext_path="${TMP_DV}/develocity-maven-extension.jar"
    curl -s "${mavenRepo}/com/gradle/develocity-maven-extension/${mavenExtensionVersion}/develocity-maven-extension-${mavenExtensionVersion}.jar" -o "${ext_path}"
  else
    ext_path="${TMP_DV}/gradle-enterprise-maven-extension.jar"
    curl -s "${mavenRepo}/com/gradle/gradle-enterprise-maven-extension/${mavenExtensionVersion}/gradle-enterprise-maven-extension-${mavenExtensionVersion}.jar" -o "${ext_path}"
  fi
  export DEVELOCITY_EXT_PATH="${ext_path}"
}

function injectDevelocityForMaven() {
  local rootDir=$1
  local mavenOpts="-Dgradle.scan.uploadInBackground=false -Ddevelocity.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=${allowUntrustedServer} -Ddevelocity.allowUntrustedServer=${allowUntrustedServer}"
  local mavenExtClasspath=''
  local appliedCustomDv="false"
  local appliedCustomCcud="false"
  local appliedCustomDv=$(detectDvExtension "${rootDir}")
  if [ "${appliedCustomDv}" = "false" ]
  then
    mavenExtClasspath="${DEVELOCITY_EXT_PATH}"
  fi
  local appliedCustomCcud=$(detectExtension "${rootDir}" "$(ccudCoordinates)")
  if [ "${appliedCustomCcud}" = "false" ]
  then
    if [ ! -z "${mavenExtClasspath}" ]
    then
      mavenExtClasspath+=":"
    fi
    mavenExtClasspath="${mavenExtClasspath}${CCUD_EXT_PATH}"
  fi
  if [ ! -z "${mavenExtClasspath}" ]
  then
    mavenOpts="-Dmaven.ext.class.path=${mavenExtClasspath} ${mavenOpts}"
  fi
  if [[ ("${appliedCustomDv}" = "true" || "${appliedCustomCcud}" = "true") && "${enforceUrl}" = "true" ]]
  then
    mavenOpts="${mavenOpts} -Dgradle.enterprise.url=${url} -Ddevelocity.url=${url}"
  elif [[ "${appliedCustomDv}" = "false" && "${appliedCustomCcud}" = "false" ]]
  then
    mavenOpts="${mavenOpts} -Dgradle.enterprise.url=${url} -Ddevelocity.url=${url}"
  fi
  if [[ "${appliedCustomDv}" = "false" && ("${captureFileFingerprints}" = "true" || "${captureFileFingerprints}" = "false") ]]
  then
      mavenOpts="${mavenOpts} -Ddevelocity.scan.captureFileFingerprints=${captureFileFingerprints} -Dgradle.scan.captureGoalInputFiles=${captureFileFingerprints}"
  fi
  local existingMavenOpts=$(if [ ! -z "$MAVEN_OPTS" ]; then echo "${MAVEN_OPTS} "; else echo ''; fi)
  export MAVEN_OPTS=${existingMavenOpts}${mavenOpts}
}

function detectDvExtension() {
  local rootDir=$1
  if [ ! -z "${customMavenExtensionCoordinates}" ]
  then
    echo "$(detectExtension $rootDir $customMavenExtensionCoordinates)"
  else
    local appliedDefaultExtension="$(detectExtension $rootDir 'com.gradle:gradle-enterprise-maven-extension')"
    if [ "${appliedDefaultExtension}" = "false" ]
    then
      appliedDefaultExtension="$(detectExtension $rootDir 'com.gradle:develocity-maven-extension')"
    fi
    echo "${appliedDefaultExtension}"
  fi
}

function ccudCoordinates() {
  local coordinates='com.gradle:common-custom-user-data-maven-extension'
  if [ ! -z "${customCcudCoordinates}" ]
  then
    coordinates="${customCcudCoordinates}"
  fi
  echo "${coordinates}"
}

function detectExtension() {
  local rootDir=$1
  local extCoordinates=$2
  local extFile="${rootDir}/.mvn/extensions.xml"
  if [ ! -f "${extFile}" ]
  then
    echo "false"
    return
  fi
  local currentExtension
  while readXml
  do
    if [ "${elementName}" = "groupId"  ]
    then
      currentExtension="${value}"
    fi
    if [ "${elementName}" = "artifactId"  ]
    then
      currentExtension="${currentExtension}:${value}"
    fi
    if [ "${elementName}" = "version"  ]
    then
      currentExtension="${currentExtension}:${value}"
    fi
    if [[ "${currentExtension}" =~ ^.*:.*:.*$ && "${currentExtension}" == *"${extCoordinates}"* ]]
    then
      echo "true"
      return
    fi
  done < "${extFile}"
  echo "false"
}

function readXml() {
  local IFS=\>
  read -d \< elementName value
}

function createShortLivedToken() {
  local allKeys="${GRADLE_ENTERPRISE_ACCESS_KEY:-${DEVELOCITY_ACCESS_KEY}}"
  if [ -z "${allKeys}" ]
  then
    return 0
  fi

  local serverUrl=${1}
  local expiry="${2}"

  local newAccessKey=""
  if [[ "${enforceUrl}" == "true" || $(singleKey "${allKeys}") == "true" ]]
  then
    local hostname=$(extractHostname "${serverUrl}")
    local accessKey=$(extractAccessKey "${allKeys}" "${hostname}")
    local tokenUrl="${serverUrl}/api/auth/token"
    if [ ! -z "${accessKey}" ]
    then
      local token=$(getShortLivedToken $tokenUrl $expiry $accessKey)
      if [ ! -z "${token}" ]
      then
        newAccessKey="${hostname}=${token}"
      fi
    else
      >&2 echo "Could not create short lived access token, no access key matching given Develocity server hostname ${hostname}"
    fi
  else
    local separator=";"
    IFS="${separator}" read -ra pairs <<< "${allKeys}"
    for pair in "${pairs[@]}"; do
      IFS='=' read -r host key <<< "$pair"
      local tokenUrl="https://${host}/api/auth/token"
      local token=$(getShortLivedToken $tokenUrl $expiry $key)
      if [ ! -z "${token}" ]
      then
        if [ -z "${newAccessKey}" ]
        then
          newAccessKey="${host}=${token}"
        else
          newAccessKey="${newAccessKey}${separator}${host}=${token}"
        fi
      fi
    done
  fi

  export DEVELOCITY_ACCESS_KEY="${newAccessKey}"
  export GRADLE_ENTERPRISE_ACCESS_KEY="${DEVELOCITY_ACCESS_KEY}"
}

function singleKey() {
  local allKeys=$1
  local separator=";"
  IFS="${separator}" read -ra pairs <<< "${allKeys}"
  if [ "${#pairs[@]}" -eq 1 ]
  then
    echo "true"
  else
    echo "false"
  fi
}

function extractHostname() {
  local url=$1
  echo "${url}" | cut -d'/' -f3 | cut -d':' -f1
}

function extractAccessKey() {
  local allKeys=$1
  local hostname=$2
  key="${allKeys#*$hostname=}"    # Remove everything before the host name and '='
  if [ "${key}" == "${allKeys}" ] # if nothing has changed, it's not a match
  then
    echo ""
  else
    key="${key%%;*}"              # Remove everything after the first ';'
    echo "$key"
  fi
}

function getShortLivedToken() {
  local tokenUrl=$1
  local expiry=$2
  local accessKey=$3
  local maxRetries=3
  local retryInterval=1
  local attempt=0

  if [ ! -z "${expiry}" ]
  then
    tokenUrl="${tokenUrl}?expiresInHours=${expiry}"
  fi
  while [ ${attempt} -le ${maxRetries} ]
  do
    local response=$(curl -s -w "\n%{http_code}" -X POST "${tokenUrl}" -H "Authorization: Bearer ${accessKey}")
    local statusCode=$(tail -n1 <<< "${response}")
    local shortLivedToken=$(head -n -1 <<< "${response}")
    if [[ "${statusCode}" == "200" && ! -z "${shortLivedToken}" ]]
    then
      echo "${shortLivedToken}"
      return
    elif [[ "${statusCode}" == "401" || "${statusCode}" == "400" ]]
    then
      >&2 echo "Develocity short lived token request failed ${serverUrl} with status code=${statusCode}"
      return
    else
      ((attempt++))
      >&2 echo "Develocity short lived token request failed ${serverUrl} with status code=${statusCode} and response=${response}"
      sleep ${retryInterval}
    fi
  done
}

createShortLivedToken "${url}" "${shortLivedTokensExpiry}"
injectDevelocityForMaven "${PWD}"
echo "Injecting Develocity MAVEN_OPTS=${MAVEN_OPTS}"

exec "$@"