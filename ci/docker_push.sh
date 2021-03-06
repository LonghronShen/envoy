#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# Travis logs.
set -e

# push the envoy image on merge to master
want_push='false'
for branch in "master"
do
   if [ "$CIRCLE_BRANCH" == "$branch" ]
   then
       want_push='true'
   fi
done
if [ -z "$CIRCLE_PULL_REQUEST" ] && [ "$want_push" == "true" ]
then
   docker build -f ci/Dockerfile-envoy-image -t lyft/envoy:latest .
   docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"
   docker push lyft/envoy:latest
   docker tag lyft/envoy:latest lyft/envoy:$CIRCLE_SHA1
   docker push lyft/envoy:$CIRCLE_SHA1
   docker rm $(docker ps -a -q) || true
   docker rmi $(docker images -a -q) || true

   make -C ci/build_alpine_container
   docker tag lyft/envoy-alpine:latest lyft/envoy-alpine:$CIRCLE_SHA1
   docker push lyft/envoy-alpine:$CIRCLE_SHA1
   docker push lyft/envoy-alpine:latest
   docker tag lyft/envoy-alpine-debug:latest lyft/envoy-alpine-debug:$CIRCLE_SHA1
   docker push lyft/envoy-alpine-debug:$CIRCLE_SHA1
   docker push lyft/envoy-alpine-debug:latest

   # This script tests the docker examples.
   # TODO(mattklein123): This almost always times out on Travis. Do not run for now until we
   # have a better CI setup.
   #./ci/verify_examples.sh
else
   echo 'Ignoring PR branch for docker push.'
fi
