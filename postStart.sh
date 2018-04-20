#!/bin/bash
set -e
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

if curl --fail --silent -u $USERNAME:$PASSWORD http://$HOST/service/metrics/ping
then 
    curl --fail -u $USERNAME:$PASSWORD --header "Content-Type: application/json" "http://$HOST/service/rest/v1/script/" -d @/opt/sonatype/nexus/admin_password.json
    curl --fail -X POST -u $USERNAME:$PASSWORD --header "Content-Type: text/plain" "http://$HOST/service/rest/v1/script/admin_password/run"
fi

PASSWORD=`cat /opt/sonatype/nexus/config/password`

REPOS=($(ls /opt/sonatype/nexus/repositories | grep json | sed -e 's/\..*$//'))
# we should check if we already have repos configured to avoid errors in logs when adding duplicates
for i in "${REPOS[@]}"
do
    echo "\ncreating $i repository"
    curl -u $USERNAME:$PASSWORD --header "Content-Type: application/json" "http://$HOST/service/rest/v1/script/" -d @/opt/sonatype/nexus/repositories/$i.json
    curl -X POST -u $USERNAME:$PASSWORD --header "Content-Type: text/plain" "http://$HOST/service/rest/v1/script/$i/run"
done

echo "\ncreating maven group"    
curl -u $USERNAME:$PASSWORD --header "Content-Type: application/json" "http://$HOST/service/rest/v1/script/" -d @/opt/sonatype/nexus/maven-group.json
curl -X POST -u $USERNAME:$PASSWORD --header "Content-Type: text/plain" "http://$HOST/service/rest/v1/script/maven-group/run"
