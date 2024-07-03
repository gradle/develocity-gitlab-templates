#!/usr/bin/env bash
# Build Docker image with Maven injection enabled
usage() {
  echo "Usage: $0 --image my-maven
                  [--baseImageVersion 3.9.8-amazoncorretto-11]
                  [--mavenRepo https://myrepo]
                  [--ccudMavenExtensionVersion 2.0]
                  [--mavenExtensionVersion 1.21.5]"
  exit 1
}

baseImageVersion=""
image=""
mavenRepo=""
ccudMavenExtensionVersion=""
mavenExtensionVersion=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseImageVersion)
      baseImageVersion="$2"
      shift 2
      ;;
    --image)
      image="$2"
      shift 2
      ;;
    --mavenRepo)
      mavenRepo="$2"
      shift 2
      ;;
    --ccudMavenExtensionVersion)
      ccudMavenExtensionVersion="$2"
      shift 2
      ;;
    --mavenExtensionVersion)
      mavenExtensionVersion="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "${image}" ]; then
  echo "Error: --image is required."
  usage
fi

function buildArg() {
  local buildArgName=$1
  local buildArgValue=$2
  if [ -z "${buildArgValue}" ]
  then
    echo ""
  else
    echo -e "\n${buildArgName}=${buildArgValue}"
  fi
}

function buildArgs() {
    local result=""
    result="${result}$(buildArg MAVEN_BASE_IMAGE_VERSION "${baseImageVersion}")"
    result="${result}$(buildArg MAVEN_REPO "${mavenRepo}")"
    result="${result}$(buildArg CCUD_MAVEN_EXTENSION_VERSION "${ccudMavenExtensionVersion}")"
    result="${result}$(buildArg MAVEN_EXTENSION_VERSION "${mavenExtensionVersion}")"
    echo -e "${result}"
}

buildArgs=$(buildArgs)
if [ -z "${buildArgs}" ]
then
  docker build -t "${image}" -f src/maven/docker/Dockerfile .
else
  # Pass multiple --build-arg
  echo "${buildArgs}" | xargs printf -- '--build-arg %s\n' | xargs docker build -t "${image}" -f src/maven/docker/Dockerfile .
fi




