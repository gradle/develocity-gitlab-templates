#!/usr/bin/env bash
shortLivedTokensExpiry=${DEVELOCITY_SHORT_LIVED_TOKEN_EXPIRY:-2}
url=${DEVELOCITY_URL}

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

exec "$@"
