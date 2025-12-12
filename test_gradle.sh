#!/bin/bash
#set -xv
buildDir="$(dirname $0)/build"

function test_inject_develocity_env_vars() {
    local projDir=$(setupProject)
    setupVars
    injectDevelocityForGradle

    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_ENABLED"
    assert "${DEVELOCITY_INJECTION_ENABLED}" "true"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_DEBUG"
    assert "${DEVELOCITY_INJECTION_DEBUG}" "true"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_INIT_SCRIPT_NAME"
    assert "${DEVELOCITY_INJECTION_INIT_SCRIPT_NAME}" "init-script.gradle"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_CUSTOM_VALUE"
    assert "${DEVELOCITY_INJECTION_CUSTOM_VALUE}" "GitLab"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_URL"
    assert "${DEVELOCITY_INJECTION_URL}" "https://localhost"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_DEVELOCITY_PLUGIN_VERSION"
    assert "${DEVELOCITY_INJECTION_DEVELOCITY_PLUGIN_VERSION}" "4.2.2"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_CCUD_PLUGIN_VERSION"
    assert "${DEVELOCITY_INJECTION_CCUD_PLUGIN_VERSION}" "2.4.0"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_ALLOW_UNTRUSTED_SERVER"
    assert "${DEVELOCITY_INJECTION_ALLOW_UNTRUSTED_SERVER}" "false"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_ENFORCE_URL"
    assert "${DEVELOCITY_INJECTION_ENFORCE_URL}" "false"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_CAPTURE_FILE_FINGERPRINTS"
    assert "${DEVELOCITY_INJECTION_CAPTURE_FILE_FINGERPRINTS}" "true"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_PLUGIN_REPOSITORY_URL"
    assert "${DEVELOCITY_INJECTION_PLUGIN_REPOSITORY_URL}" "https://somerepo"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_PLUGIN_REPOSITORY_USERNAME"
    assert "${DEVELOCITY_INJECTION_PLUGIN_REPOSITORY_USERNAME}" "repol"
    echo "test_inject_develocity_env_vars DEVELOCITY_INJECTION_PLUGIN_REPOSITORY_PASSWORD"
    assert "${DEVELOCITY_INJECTION_PLUGIN_REPOSITORY_PASSWORD}" "repop"
}

function setupProject() {
    local projDir="$(mktemp -p ${buildDir} -d ge.XXXXXX)"
    local extDir="${projDir}/.mvn"
    mkdir -p "${extDir}"

    echo "${projDir}"
}

function setupVars() {
    # Set the vars to default
    allowUntrustedServer="false"
    shortLivedTokensExpiry="2"
    enforceUrl="false"
    captureFileFingerprints="true"
    gradlePluginVersion="4.2.2"
    ccudPluginVersion="2.4.0"
    gradlePluginRepositoryUrl="https://somerepo"
    gradlePluginRepositoryUsername="repol"
    gradlePluginRepositoryPassword="repop"
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
    local file="$(dirname $0)/develocity-gradle.yml"

    sed -n "/$start_pattern/,/$end_pattern/p" "$file" | sed '/^$/d' > "${buildDir}/gradle-under-test.sh"
    source "${buildDir}/gradle-under-test.sh"
}

function clean() {
    echo "removing ${buildDir}"
    rm -Rf "${buildDir}"
    mkdir "${buildDir}"
}

clean
extractCodeUnderTest
test_inject_develocity_env_vars
