#!/bin/bash
set -eu
HOST=localhost:8081

until curl --output /dev/null --silent --head --fail http://${HOST}/; do
  printf '.'
  sleep 5
done

chgrp -R 0 /nexus-data
chmod -R g+rw /nexus-data
find /nexus-data -type d -exec chmod g+x {} +

USERNAME="admin"
PASSWORD="admin123"
PASSWORD_FROM_FILE="$(cat /opt/sonatype/nexus/config/password || true)"
NEXUS_BASE_DIR="/opt/sonatype/nexus"
NEXUS_REPO_DIR="${NEXUS_BASE_DIR}/repositories"
declare -a SCRIPT_LIST

function die() {
    echo "ERROR: $*" 1>&2
    exit 1
}

function createOrUpdateAndRun() {
    local scriptName=$1
    local scriptFile=$2
    local scriptName_regex=" ${scriptName} "
    if [ "${#SCRIPT_LIST[@]}" = 0 ] || [[ ! " ${SCRIPT_LIST[*]} " =~ ${scriptName_regex} ]]; then
        echo "Creating ${scriptName} repository script"
        curl --fail -X POST -u "${USERNAME}":"${PASSWORD}" --header "Content-Type: application/json" "http://${HOST}/service/rest/v1/script/" -d @"${scriptFile}"
    else
        echo "Updating ${scriptName} repository script"
        curl --fail -X PUT -u ${USERNAME}:${PASSWORD} --header "Content-Type: application/json" "http://${HOST}/service/rest/v1/script/${scriptName}" -d @"${scriptFile}"
    fi
    echo "Running ${scriptName} repository script"
    curl --fail -X POST -u ${USERNAME}:${PASSWORD} --header "Content-Type: text/plain" "http://${HOST}/service/rest/v1/script/${scriptName}/run"
    echo
}

function setScriptList() {
    # initialising the scripts already present once and assuming that there no duplicate script names in the scripts that follow
    mapfile SCRIPT_LIST < <(curl --fail -s -u "${USERNAME}":"${PASSWORD}" http://"${HOST}"/service/rest/v1/script | grep -oE "\"name\" : \"[^\"]+" | sed 's/"name" : "//')
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
    setScriptList
    createOrUpdateAndRun admin_password "${NEXUS_BASE_DIR}"/admin_password.json
    setPasswordFromFile
elif [ -n "${PASSWORD_FROM_FILE}" ]; then
    setPasswordFromFile
    echo "Default password failed. Checking password file..."
    if curl --fail --silent -u "${USERNAME}":"${PASSWORD}" http://"${HOST}"/service/metrics/ping; then
        echo "Login to nexus succeeded. Password from secret file worked."
        setScriptList
    else
        die "Login to nexus failed. Tried both the default password and the provided password secret file."
    fi
else
    die "Login to nexus failed. Tried the default password only since no password secret file was provided."
fi


mapfile REPOS < <(find "${NEXUS_REPO_DIR}" -type f -maxdepth 1 -name "*json*" | sed -e 's/\..*$//')
for repo in "${REPOS[@]}"; do
    createOrUpdateAndRun "${repo}" "${NEXUS_REPO_DIR}"/"${repo}".json
done

createOrUpdateAndRun maven-group "${NEXUS_BASE_DIR}"/maven-group.json

if [ -z "${ENABLE_ANONYMOUS_ACCESS}" ]; then
  createOrUpdateAndRun disable-anonymous-access "${NEXUS_BASE_DIR}"/disable-anonymous-access.json
fi
