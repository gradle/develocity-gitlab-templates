#!/usr/bin/env bash
# Build Docker image with Maven injection enabled
usage() {
  echo "Usage: $0 --image my-gradle
                  [--baseImageVersion 8.8.0-jdk21]"
  exit 1
}

baseImageVersion=""
image=""

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
    result="${result}$(buildArg GRADLE_BASE_IMAGE_VERSION "${baseImageVersion}")"
    echo -e "${result}"
}

buildArgs=$(buildArgs)
if [ -z "${buildArgs}" ]
then
  docker build -t "${image}" -f src/gradle/docker/Dockerfile .
else
  # Pass multiple --build-arg
  echo "${buildArgs}" | xargs printf -- '--build-arg %s\n' | xargs docker build -t "${image}" -f src/gradle/docker/Dockerfile .
fi




