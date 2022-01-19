FROM sonatype/nexus3:3.27.0

COPY *.json /opt/sonatype/nexus/
COPY maven-group-repositories /opt/sonatype/nexus/maven-group-repositories
COPY maven-proxy-repositories /opt/sonatype/nexus/maven-proxy-repositories
COPY npmjs-proxy-repositories /opt/sonatype/nexus/npmjs-proxy-repositories
COPY docker-hosted-repositories /opt/sonatype/nexus/docker-hosted-repositories
COPY docker-proxy-repositories /opt/sonatype/nexus/docker-proxy-repositories
COPY postStart.sh /opt/sonatype/nexus/

USER root
RUN chgrp -R 0 /nexus-data
RUN chmod -R g+rw /nexus-data
RUN find /nexus-data -type d -exec chmod g+x {} +

ENV NEXUS_DATA_CHOWN "true"
