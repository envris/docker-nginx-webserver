#!/bin/bash

echo "DOCKER_OPTS=\"${DOCKER_BUILDER_OPTS}\"" >> /etc/default/docker

# Start the docker daemon
/etc/init.d/docker start

sleep 6s

# Pull latest base images (purely for cache, naming does not matter, just hashes)
docker pull ${DOCKER_REG_PREFIX}/nginx-webserver:latest

# cd and cont.
cd /builder/
if [ "${DOCKER_BASE_IMG}" != "" ] ; then
  sed -i "s;.*FROM .*;FROM ${DOCKER_BASE_IMG};" ./Dockerfile
fi
echo -e "ENV BUILD_DETAILS ${GIT_COMMIT}_${BUILD_NUMBER}" >> ./Dockerfile
echo -e "BUILD_DETAILS:\n  GIT_COMMIT: ${GIT_COMMIT}\n  BUILD_NUMBER: ${BUILD_NUMBER}\n" > ./BUILD_DETAILS
echo -e "ADD ./BUILD_DETAILS /etc/BUILD_DETAILS" >> ./Dockerfile

# Build the new app server
docker build -t dd/nginx-webserver:latest . 

LATEST_IMG=`docker images | grep "dd/nginx-webserver" | grep "latest" | awk '{print $3}'`

if [ "${LATEST_IMG}" != "" ] ; then
  docker tag dd/nginx-webserver:latest ${DOCKER_REG_PREFIX}/nginx-webserver:${GIT_COMMIT}_${BUILD_NUMBER}
  docker tag -f dd/nginx-webserver:latest ${DOCKER_REG_PREFIX}/nginx-webserver:latest
  docker push ${DOCKER_REG_PREFIX}/nginx-webserver:${GIT_COMMIT}_${BUILD_NUMBER}
  docker push ${DOCKER_REG_PREFIX}/nginx-webserver:latest
fi
