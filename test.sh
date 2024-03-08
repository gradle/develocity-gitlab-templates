#!/bin/bash
#set -xv
buildDir="$(dirname $0)/build"
DEVELOCITY_EXT_PATH="/path/to/gradle-enterprise-maven-extension.jar"
CCUD_EXT_PATH="/path/to/common-custom-user-data-maven-extension.jar"

function test_detectExtension_detected() {
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

    local result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension")

    echo "test_detectExtension_detected: ${result}"
    assert "${result}" "true"

    result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension:1.20.1")

    echo "test_detectExtension_detected with version: ${result}"
    assert "${result}" "true"

    result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension:1.18.1")

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
            <artifactId>gradle-enterprise-maven-extension</artifactId>
            <version>1.20.1</version>
        </extension>
    </extensions>
EOF

    local result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension")

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

    local result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension")

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

    local result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension")

    echo "test_detectExtension_notDetected_junk: ${result}"
    assert $result "false"
}

function test_detectExtension_unexisting() {
    local projDir=$(setupProject)

    local result=$(detectExtension "${projDir}" "com.gradle:gradle-enterprise-maven-extension")

    echo "test_detectExtension_notDetected_unexisting: ${result}"
    assert $result "false"
}

function test_inject_develocity_for_maven() {
    local projDir=$(setupProject)
    allowUntrustedServer=false
    url=https://localhost
    MAVEN_OPTS=""

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/gradle-enterprise-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost"
}

function test_inject_develocity_for_maven_existing_maven_opts() {
    local projDir=$(setupProject)
    allowUntrustedServer=false
    url=https://localhost
    MAVEN_OPTS="-Dfoo=bar"

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_maven_opts: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dfoo=bar -Dmaven.ext.class.path=/path/to/gradle-enterprise-maven-extension.jar:/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost"
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
    allowUntrustedServer=false
    customMavenExtensionCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    url=https://localhost
    enforceUrl=false
    MAVEN_OPTS=""

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_extension: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false"
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
    allowUntrustedServer=false
    customMavenExtensionCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    url=https://localhost
    MAVEN_OPTS=""
    enforceUrl=true

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_extension_enforceUrl: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/common-custom-user-data-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost"
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
    allowUntrustedServer=false
    customMavenExtensionCoordinates=""
    customCcudCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    url=https://localhost
    enforceUrl=false
    MAVEN_OPTS=""

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_ccud_extension: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/gradle-enterprise-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false"
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
    allowUntrustedServer=false
    customMavenExtensionCoordinates=""
    customCcudCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    url=https://localhost
    enforceUrl=true
    MAVEN_OPTS=""

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_ccud_extension_enforceUrl: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dmaven.ext.class.path=/path/to/gradle-enterprise-maven-extension.jar -Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost"
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
    allowUntrustedServer=false
    customMavenExtensionCoordinates="org.foo:bar-extension"
    customCcudCoordinates="org.apache.maven.extensions:maven-enforcer-extension"
    url=https://localhost
    enforceUrl=true
    MAVEN_OPTS=""

    injectDevelocityForMaven "${projDir}"

    echo "test_inject_develocity_for_maven_existing_dv_and_ccud_extension_enforceUrl: ${MAVEN_OPTS}"
    assert "${MAVEN_OPTS}" "-Dgradle.scan.uploadInBackground=false -Dgradle.enterprise.allowUntrustedServer=false -Dgradle.enterprise.url=https://localhost"
}

function setupProject() {
    local projDir="$(mktemp -p ${buildDir} -d ge.XXXXXX)"
    local extDir="${projDir}/.mvn"
    mkdir -p "${extDir}"

    echo "${projDir}"
}

function assert() {
    local val=$1
    local expected=$2
    if [ ! "${val}" = "${expected}" ]
    then
        echo "${val} not equal to expected ${expected}"
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
test_detectExtension_detected
test_detectExtension_notDetected
test_detectExtension_notDetected_junk
test_detectExtension_unexisting
test_detectExtension_multiple_detected
test_inject_develocity_for_maven
test_inject_develocity_for_maven_existing_maven_opts
test_inject_develocity_for_maven_existing_extension
test_inject_develocity_for_maven_existing_extension_enforceUrl
test_inject_develocity_for_maven_existing_ccud_extension
test_inject_develocity_for_maven_existing_ccud_extension_enforceUrl
test_inject_develocity_for_maven_existing_dv_and_ccud_extension_enforceUrl
