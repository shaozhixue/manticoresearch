#!/bin/bash

declare -A tags
#tags["latest"]=release
tags["dev"]=dev

for ((i = 0; i < 3; i++)); do
     echo "Trying to authorise into dockerhub"
      echo $DOCKER_PASSWORD|docker login -u$DOCKER_USER --password-stdin docker.io
      docker info | grep Username|grep $DOCKER_USER && break
done

if ! (docker info | grep Username) > /dev/null 2>&1; then
      echo "Can't authorise to dockerhub"
      exit 1
fi

if [ ! -n "$BUILD_TAGS" ]; then
  BUILD_TAGS="dev"
fi

IFS=' ' read -r -a SPLITTED_BUILD_TAGS <<<"$BUILD_TAGS"

git clone https://github.com/manticoresoftware/docker.git docker
cd docker

BUILD_FAILED=false

for BUILD_TAG in "${SPLITTED_BUILD_TAGS[@]}"; do
  echo "Start to build $BUILD_TAG from branch ${tags[$BUILD_TAG]}"

  if [ -n ${tags[$BUILD_TAG]} ]; then

    for ((i = 0; i < 3; i++)); do
      echo "Started to buid manticoresearch/manticore:$BUILD_TAG"
      docker build --build-arg DEV=1 --no-cache -t manticoresearch/manticore:$BUILD_TAG . && break
      if [ $i==2 ]; then
        echo "Docker build are failed"
        BUILD_FAILED=true
      fi
    done

    for ((i = 0; i < 3; i++)); do
      echo "Started to push manticoresearch/manticore:$BUILD_TAG"
      docker push manticoresearch/manticore:$BUILD_TAG && break
      if [ $i==2 ]; then
        echo "Docker push are failed"
        BUILD_FAILED=true
      fi
    done

  else
    echo "Can't find branch for tag $BUILD_TAG"
  fi
done

echo "Done"
cd ..
rm -rf docker

if [ "$BUILD_FAILED" = true ] ; then
    exit 1
fi
