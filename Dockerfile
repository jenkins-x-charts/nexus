FROM sonatype/nexus3:3.13.0

COPY *.json /opt/sonatype/nexus/
COPY repositories /opt/sonatype/nexus/repositories
COPY postStart.sh /opt/sonatype/nexus/

USER root
RUN chgrp -R 0 /nexus-data
RUN chmod -R g+rw /nexus-data
RUN find /nexus-data -type d -exec chmod g+x {} +
    
    
