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