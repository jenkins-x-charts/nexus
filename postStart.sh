#!/bin/bash
set -eu
HOST=localhost:8081

until $(curl --output /dev/null --silent --head --fail http://$HOST/); do
  printf '.'
  sleep 5
done

chgrp -R 0 /nexus-data
chmod -R g+rw /nexus-data
find /nexus-data -type d -exec chmod g+x {} +

USERNAME=admin
PASSWORD=admin123

function createOrUpdateAndRun() {
    local scriptName=$1
    local scriptFile=$2
    if [ "${#SCRIPT_LIST[@]}" = 0 ] || [[ ! " ${SCRIPT_LIST[@]} " =~ " ${scriptName} " ]]; then
        echo "Creating $scriptName repository script"
        curl --fail -X POST -u $USERNAME:$PASSWORD --header "Content-Type: application/json" "http://$HOST/service/rest/v1/script/" -d @$scriptFile
    else
        echo "Updating $scriptName repository script"
        curl --fail -X PUT -u $USERNAME:$PASSWORD --header "Content-Type: application/json" "http://$HOST/service/rest/v1/script/$scriptName" -d @$scriptFile
    fi
    echo "Running $scriptName repository script"
    curl --fail -X POST -u $USERNAME:$PASSWORD --header "Content-Type: text/plain" "http://$HOST/service/rest/v1/script/$scriptName/run"
    echo
}

if curl --fail --silent -u $USERNAME:$PASSWORD http://$HOST/service/metrics/ping; then

    # initialising the scripts already present once and assuming that there no duplicate script names in the scripts that follow
    SCRIPT_LIST=($(curl --fail -s -u $USERNAME:$PASSWORD http://$HOST/service/rest/v1/script | grep -oE "\"name\" : \"[^\"]+" | sed 's/"name" : "//'))

    createOrUpdateAndRun admin_password /opt/sonatype/nexus/admin_password.json
fi

PASSWORD=`cat /opt/sonatype/nexus/config/password`

REPOS=($(ls /opt/sonatype/nexus/repositories | grep json | sed -e 's/\..*$//'))
for i in "${REPOS[@]}"; do
    createOrUpdateAndRun $i /opt/sonatype/nexus/repositories/$i.json
done

createOrUpdateAndRun maven-group /opt/sonatype/nexus/maven-group.json