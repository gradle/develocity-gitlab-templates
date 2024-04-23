#!/bin/bash
#set -xv
buildDir="$(dirname $0)/build"
DEVELOCITY_EXT_PATH="/path/to/develocity-maven-extension.jar"
CCUD_EXT_PATH="/path/to/common-custom-user-data-maven-extension.jar"

function test_isAtLeast_Larger() {
  local actual=$(isAtLeast 1.1 1.0)
  local expected="true"
  echo "test_isAtLeast_Larger: actual = ${actual}; expected = ${expected}"
  assert "$actual" "$expected"
}

function test_isAtLeast_Equal() {
  local actual=$(isAtLeast 1.1 1.1)
  local expected="true"
  echo "test_isAtLeast_Equal: actual = ${actual}; expected = ${expected}"
  assert "$actual" "$expected"
}

function test_isAtLeast_Smaller() {
  local actual=$(isAtLeast 1.1 1.2)
  local expected="false"
  echo "test_isAtLeast_Smaller: actual = ${actual}; expected = ${expected}"
  assert "$actual" "$expected"
}

function test_isAtLeast_Minor_And_Patch_Larger() {
  local actual=$(isAtLeast 1.2 1.1.1)
  local expected="true"
  echo "test_isAtLeast_Minor_And_Patch_Larger: actual = ${actual}; expected = ${expected}"
  assert "$actual" "$expected"
}

function test_isAtLeast_Minor_And_Patch_Smaller() {
  local actual=$(isAtLeast 1.2 1.2.1)
  local expected="false"
  echo "test_isAtLeast_Minor_And_Patch_Larger: actual = ${actual}; expected = ${expected}"
  assert "$actual" "$expected"
}

function test_isAtLeast_Ignore_Qualifier() {
  local actual=$(isAtLeast 1.2-rc-4 1.2)
  local expected="true"
  echo "test_isAtLeast_Ignore_Qualifier: actual = ${actual}; expected = ${expected}"
  assert "$actual" "$expected"
}

function test_downloadMavenExtension_GradleEnterprise() {
  local mavenRepo="https://repo.grdev.net/artifactory/public"
  local mavenExtensionVersion="1.17"
  local TMP_DV=$buildDir
  downloadDvMavenExt
  echo "test_downloadMavenExtension_GradleEnterprise: $DEVELOCITY_EXT_PATH"
  assert "$DEVELOCITY_EXT_PATH" "$buildDir/gradle-enterprise-maven-extension.jar"
  DEVELOCITY_EXT_PATH="/path/to/develocity-maven-extension.jar"
}

function test_downloadMavenExtension_Develocity() {
  local mavenRepo="https://repo.grdev.net/artifactory/public"
  local mavenExtensionVersion="1.21-rc-4"
  local TMP_DV=$buildDir
  downloadDvMavenExt
  echo "test_downloadMavenExtension_Develocity: $DEVELOCITY_EXT_PATH"
  assert "$DEVELOCITY_EXT_PATH" "$buildDir/develocity-maven-extension.jar"
  DEVELOCITY_EXT_PATH="/path/to/develocity-maven-extension.jar"
}

function test_detectExtension_detected() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>com.gradle</groupId>
            <artifactId>develocity-maven-extension</artifactId>
            <version>1.20.1</version>
        </extension>
    </extensions>
EOF
    setupVars

    local result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension")

    echo "test_detectExtension_detected: ${result}"
    assert "${result}" "true"

    result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension:1.20.1")

    echo "test_detectExtension_detected with version: ${result}"
    assert "${result}" "true"

    result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension:1.18.1")

    echo "test_detectExtension_detected with wrong version: ${result}"
    assert "${result}" "false"
}

function test_detectExtension_multiple_detected() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>foo</groupId>
            <artifactId>bar</artifactId>
            <version>1.20.1</version>
        </extension>
        <extension>
            <groupId>foo</groupId>
            <artifactId>bar2</artifactId>
            <version>1.20.1</version>
        </extension>
        <extension>
            <groupId>com.gradle</groupId>
            <artifactId>develocity-maven-extension</artifactId>
            <version>1.20.1</version>
        </extension>
    </extensions>
EOF
    setupVars

    local result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension")

    echo "test_detectExtension_multiple_detected: ${result}"
    assert "${result}" "true"
}

function test_detectExtension_notDetected() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>org.apache.maven.extensions</groupId>
            <artifactId>maven-enforcer-extension</artifactId>
            <version>3.4.1</version>
        </extension>
    </extensions>
EOF
    setupVars

    local result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension")

    echo "test_detectExtension_notDetected: ${result}"
    assert $result "false"
}

function test_detectExtension_notDetected_junk() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <foo>
    </foo>
EOF
    setupVars

    local result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension")

    echo "test_detectExtension_notDetected_junk: ${result}"
    assert $result "false"
}

function test_detectExtension_unexisting() {
    local projDir=$(setupProject)
    setupVars

    local result=$(detectExtension "${projDir}" "com.gradle:develocity-maven-extension")

    echo "test_detectExtension_notDetected_unexisting: ${result}"
    assert $result "false"
}

function test_detectDvExtension_non_existing() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>com.foo</groupId>
            <artifactId>bar</artifactId>
            <version>1.0</version>
        </extension>
    </extensions>
EOF
    setupVars

    local result=$(detectDvExtension "${projDir}")
    echo "test_detectDvExtension_non_existing: ${result}"
    assert "${result}" "false"
}

function test_detectDvExtension_custom() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>com.foo</groupId>
            <artifactId>bar</artifactId>
            <version>1.0</version>
        </extension>
        <extension>
            <groupId>com.gradle</groupId>
            <artifactId>develocity-maven-extension</artifactId>
            <version>1.21</version>
        </extension>
    </extensions>
EOF
    setupVars

    customMavenExtensionCoordinates="com.foo:bar:1.0"
    local result=$(detectDvExtension "${projDir}")
    echo "test_detectDvExtension_custom: ${result}"
    assert "${result}" "true"

    customMavenExtensionCoordinates="com.foo:bar:2.0"
    result=$(detectDvExtension "${projDir}")
    echo "test_detectDvExtension_custom with wrong version: ${result}"
    assert "${result}" "false"
}

function test_detectDvExtension_GradleEnterprise() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>com.gradle</groupId>
            <artifactId>gradle-enterprise-maven-extension</artifactId>
            <version>1.20.1</version>
        </extension>
    </extensions>
EOF
    setupVars

    local result=$(detectDvExtension "${projDir}")
    echo "test_detectDvExtension_GradleEnterprise: ${result}"
    assert "${result}" "true"
}

function test_detectDvExtension_Develocity() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
    <?xml version="1.0" encoding="UTF-8"?>
    <extensions>
        <extension>
            <groupId>com.gradle</groupId>
            <artifactId>develocity-maven-extension</artifactId>
            <version>1.21</version>
        </extension>
    </extensions>
EOF
    setupVars

    local result=$(detectDvExtension "${projDir}")
    echo "test_detectDvExtension_Develocity: ${result}"
    assert "${result}" "true"
}

function test_inject_develocity_for_maven() {
    local projDir=$(setupProject)
    setupVars

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_develocity_for_maven_existing_maven_opts() {
    local projDir=$(setupProject)
    setupVars
    MAVEN_OPTS="-Dfoo=bar"

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_maven_opts: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dfoo=bar -Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_develocity_for_maven_existing_extension() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
      <?xml version="1.0" encoding="UTF-8"?>
      <extensions>
          <extension>
              <groupId>org.apache.maven.extensions</groupId>
              <artifactId>maven-enforcer-extension</artifactId>
              <version>3.4.1</version>
          </extension>
      </extensions>
EOF
    setupVars
    customMavenExtensionCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    enforceUrl=false

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_extension: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false"
}

function test_inject_develocity_for_maven_existing_extension_enforceUrl() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
      <?xml version="1.0" encoding="UTF-8"?>
      <extensions>
          <extension>
              <groupId>org.apache.maven.extensions</groupId>
              <artifactId>maven-enforcer-extension</artifactId>
              <version>3.4.1</version>
          </extension>
      </extensions>
EOF
    setupVars
    customMavenExtensionCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    enforceUrl=true

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_extension_enforceUrl: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost"
}

function test_inject_develocity_for_maven_existing_ccud_extension() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
      <?xml version="1.0" encoding="UTF-8"?>
      <extensions>
          <extension>
              <groupId>org.apache.maven.extensions</groupId>
              <artifactId>maven-enforcer-extension</artifactId>
              <version>3.4.1</version>
          </extension>
      </extensions>
EOF
    setupVars
    customCcudCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    enforceUrl=false

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_ccud_extension: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_develocity_for_maven_existing_default_ccud_extension() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
      <?xml version="1.0" encoding="UTF-8"?>
      <extensions>
          <extension>
              <groupId>com.gradle</groupId>
              <artifactId>common-custom-user-data-maven-extension</artifactId>
              <version>1.13</version>
          </extension>
      </extensions>
EOF
    setupVars
    enforceUrl=false

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_default_ccud_extension: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_develocity_for_maven_existing_ccud_extension_enforceUrl() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
      <?xml version="1.0" encoding="UTF-8"?>
      <extensions>
          <extension>
              <groupId>org.apache.maven.extensions</groupId>
              <artifactId>maven-enforcer-extension</artifactId>
              <version>3.4.1</version>
          </extension>
      </extensions>
EOF
    setupVars
    customCcudCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    enforceUrl=true

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_ccud_extension_enforceUrl: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_develocity_for_maven_existing_dv_and_ccud_extension_enforceUrl() {
    local projDir=$(setupProject)
    cat << EOF >"${projDir}/.mvn/extensions.xml"
      <?xml version="1.0" encoding="UTF-8"?>
      <extensions>
          <extension>
              <groupId>org.apache.maven.extensions</groupId>
              <artifactId>maven-enforcer-extension</artifactId>
              <version>3.4.1</version>
          </extension>
          <extension>
              <groupId>org.foo</groupId>
              <artifactId>bar-extension</artifactId>
              <version>1.0</version>
          </extension>
      </extensions>
EOF
    setupVars
    customMavenExtensionCoordinates="org.foo:bar-extension"
    customCcudCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    enforceUrl=true

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_dv_and_ccud_extension_enforceUrl: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost"
}

function test_inject_capture_goal_input_files_true_old() {
    local projDir=$(setupProject)
    setupVars
    captureFileFingerprints=true
    mavenExtensionVersion="1.20.1"

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_capture_goal_input_files_true_old: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_capture_goal_input_files_true() {
    local projDir=$(setupProject)
    setupVars
    captureFileFingerprints=true

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_capture_goal_input_files_true: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost -Ddevelocity.scan.captureFileFingerprints=true -Dgradle.scan.captureGoalInputFiles=true"
}

function test_inject_capture_goal_input_files_false() {
    local projDir=$(setupProject)
    setupVars
    captureFileFingerprints=false

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_capture_goal_input_files_false: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/develocity-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost -Ddevelocity.url=https://localhost -Ddevelocity.scan.captureFileFingerprints=false -Dgradle.scan.captureGoalInputFiles=false"
}

function test_inject_capture_goal_input_files_existing_ext() {
    local projDir=$(setupProject)
        cat << EOF >"${projDir}/.mvn/extensions.xml"
          <?xml version="1.0" encoding="UTF-8"?>
          <extensions>
              <extension>
                  <groupId>com.gradle</groupId>
                  <artifactId>develocity-maven-extension</artifactId>
                  <version>1.21</version>
              </extension>
          </extensions>
EOF
    setupVars
    enforceUrl=false
    captureFileFingerprints=false

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_capture_goal_input_files_existing_ext: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Ddevelocity.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Ddevelocity.allowUntrustedServer=false"
}

function test_extract_hostname() {
    echo "test_extract_hostname"
    local hostname=$(extractHostname "http://some-dv-server.gradle.com")
    assert "${hostname}" "some-dv-server.gradle.com"

    hostname=$(extractHostname "http://some-dv-server.gradle.com/somepath")
    assert "${hostname}" "some-dv-server.gradle.com"

    hostname=$(extractHostname "http://192.168.1.10")
    assert "${hostname}" "192.168.1.10"

    hostname=$(extractHostname "http://192.168.1.10:5086")
    assert "${hostname}" "192.168.1.10"

    # we do not handle this case for now
    hostname=$(extractHostname "not_a_url")
    assert "${hostname}" "not_a_url"
}

function test_extract_access_key() {
    echo "test_extract_access_key"
    local key=$(extractAccessKey "host1=key1;host2=key2;host3=key3" "host2")
    assert "${key}" "key2"

    key=$(extractAccessKey "host1=key1;host2=key2;host3=key3" "unknown")
    assert "${key}" ""
}

function test_single_key() {
    echo "test_single_key"
    local key=$(singleKey "host1=key1")
    assert "${key}" "true"

    key=$(singleKey "host1=key1;host2=key2;host3=key3")
    assert "${key}" "false"
}

function setupProject() {
    local projDir="$(mktemp -p ${buildDir} -d ge.XXXXXX)"
    local extDir="${projDir}/.mvn"
    mkdir -p "${extDir}"

    echo "${projDir}"
}

function setupVars() {
    # Set the vars to default
    MAVEN_OPTS=""
    ccudMavenExtensionVersion=""
    mavenRepo=""
    mavenExtensionVersion="1.21"
    allowUntrustedServer="false"
    enforceUrl="true"
    captureFileFingerprints="true"
    customMavenExtensionCoordinates=""
    customCcudCoordinates=""
    url="https://localhost"
}


function assert() {
    local val=$1
    local expected=$2
    if [ ! "${val}" = "${expected}" ]
    then
        echo "Not equal to expected"
        diff  <(echo "${val}" ) <(echo "${expected}")
        exit 1
    fi
}

function extractCodeUnderTest() {
    local start_pattern="#functions-start"
    local end_pattern="#functions-end"
    local file="$(dirname $0)/develocity-maven.yml"

    sed -n "/$start_pattern/,/$end_pattern/p" "$file" | sed '/^$/d' > "${buildDir}/under-test.sh"
    source "${buildDir}/under-test.sh"
}

function clean() {
    echo "removing ${buildDir}"
    rm -Rf "${buildDir}"
    mkdir "${buildDir}"
}

clean
extractCodeUnderTest
test_isAtLeast_Larger
test_isAtLeast_Equal
test_isAtLeast_Smaller
test_isAtLeast_Minor_And_Patch_Larger
test_isAtLeast_Minor_And_Patch_Smaller
test_isAtLeast_Ignore_Qualifier
test_downloadMavenExtension_GradleEnterprise
test_downloadMavenExtension_Develocity
test_detectExtension_detected
test_detectExtension_notDetected
test_detectExtension_notDetected_junk
test_detectExtension_unexisting
test_detectExtension_multiple_detected
test_detectDvExtension_non_existing
test_detectDvExtension_custom
test_detectDvExtension_GradleEnterprise
test_detectDvExtension_Develocity
test_inject_develocity_for_maven
test_inject_develocity_for_maven_existing_maven_opts
test_inject_develocity_for_maven_existing_extension
test_inject_develocity_for_maven_existing_extension_enforceUrl
test_inject_develocity_for_maven_existing_ccud_extension
test_inject_develocity_for_maven_existing_default_ccud_extension
test_inject_develocity_for_maven_existing_ccud_extension_enforceUrl
test_inject_develocity_for_maven_existing_dv_and_ccud_extension_enforceUrl
test_inject_capture_goal_input_files_true_old
test_inject_capture_goal_input_files_true
test_inject_capture_goal_input_files_false
test_inject_capture_goal_input_files_existing_ext
test_extract_hostname
test_extract_access_key
test_single_key
