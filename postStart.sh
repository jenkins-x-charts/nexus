#!/bin/bash
set -eu
HOST="localhost:8081"

until curl --output /dev/null --silent --head --fail http://${HOST}/; do
  printf '.'
  sleep 5
done


chgrp -R 0 /nexus-data
chmod -R g+rw /nexus-data
find /nexus-data -type d -exec chmod g+x {} +

NEXUS_BASE_DIR="/opt/sonatype/nexus"
NEXUS_MAVEN_REPO_DIR="${NEXUS_BASE_DIR}/maven-proxy-repositories"
NEXUS_NPMJS_REPO_DIR="${NEXUS_BASE_DIR}/npmjs-proxy-repositories"
NEXUS_MAVEN_GROUP_DIR="${NEXUS_BASE_DIR}/maven-group-repositories"
USERNAME="admin"
PASSWORD="admin123"
PASSWORD_FROM_FILE="$(cat "${NEXUS_BASE_DIR}"/config/password || true)"

function die() {
    echo "ERROR: $*" 1>&2
    exit 1
}

# Call the Nexus API for the specified repository
function runCurlFromJsonFile() {
    local jsonFile
    local service
    local body
    local method
    jsonFile="${1}"
    service="${2}"
    method="${3}"
    body="$(cat "${jsonFile}")"

    if  ! curl --fail -X "${method}" -u "${USERNAME}":"${PASSWORD}" "http://${HOST}/${service}" -H "accept:application/json" -H "Content-Type:application/json" -d "${body//[$'\t\r\n']}"; then
        echo "Error calling Nexus API for http://${HOST}/${service} to add repository from ${jsonFile}"
    fi
}

function setPasswordFromFile() {
    if [ -n "${PASSWORD_FROM_FILE}" ]; then
        echo "Updating PASSWORD variable from password file."
        PASSWORD="${PASSWORD_FROM_FILE}"
    else
        echo "Not updating PASSWORD var. Password file either non-existent or not readable."
    fi
}

if curl --fail --silent -u "${USERNAME}":"${PASSWORD}" http://"${HOST}"/service/metrics/ping; then
    echo "Login to nexus succeeded. Default password worked. Updating password if available..."
    curl --fail -X PUT -u "${USERNAME}":"${PASSWORD}" "http://${HOST}/service/rest/beta/security/users/admin/change-password" --header "Content-Type: text/plain" -d "${PASSWORD_FROM_FILE}"
    setPasswordFromFile
elif [ -n "${PASSWORD_FROM_FILE}" ]; then
    setPasswordFromFile
    echo "Default password failed. Checking password file..."
    if curl --fail --silent -u "${USERNAME}":"${PASSWORD}" http://"${HOST}"/service/metrics/ping; then
        echo "Login to nexus succeeded. Password from secret file worked."
    else
        die "Login to nexus failed. Tried both the default password and the provided password secret file."
    fi
else
    die "Login to nexus failed. Tried the default password only since no password secret file was provided."
fi

# For each maven repository proxy json file, create the repo proxy via the Nexus API.
echo "Creating maven proxy repositories from json"
mapfile -t REPOS < <(find "${NEXUS_MAVEN_REPO_DIR}" -maxdepth 1 -type f -name "*json*")
for repo in "${REPOS[@]}"; do
    runCurlFromJsonFile "${repo}" "service/rest/beta/repositories/maven/proxy" POST
done

# For each npmjs proxy repository json file, create the repo proxy via the Nexus API.
echo "Creating npmjs proxy repositories from json"
mapfile -t REPOS < <(find "${NEXUS_NPMJS_REPO_DIR}" -maxdepth 1 -type f -name "*json*")
for repo in "${REPOS[@]}"; do
    runCurlFromJsonFile "${repo}" "service/rest/beta/repositories/npm/proxy" POST
done

# For each maven group repository json file, create the repo via the Nexus API.
echo "Creating maven group repositories from json"
mapfile -t REPOS < <(find "${NEXUS_MAVEN_GROUP_DIR}" -maxdepth 1 -type f -name "*json*")
for repo in "${REPOS[@]}"; do
    runCurlFromJsonFile "${repo}" "service/rest/beta/repositories/maven/group" POST
done

# It is not possible at this time to disable anonymous access at the server level via API.
# By disabling the anonymous user account, it has the same result.
if [ -z "${ENABLE_ANONYMOUS_ACCESS}" ] || [ "${ENABLE_ANONYMOUS_ACCESS}" = "false" ]; then
    echo "Disabling the anonymous account"
    runCurlFromJsonFile "${NEXUS_BASE_DIR}"/disable-anonymous-access.json "service/rest/beta/security/users/anonymous" PUT
fi
