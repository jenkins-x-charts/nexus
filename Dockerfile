FROM sonatype/nexus3:3.8.0

COPY *.json /opt/sonatype/nexus/
COPY repositories /opt/sonatype/nexus/repositories
COPY postStart.sh /opt/sonatype/nexus/