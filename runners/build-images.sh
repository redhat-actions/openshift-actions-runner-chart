#!/usr/bin/env bash

set -eE -o pipefail

export REGISTRY=quay.io/redhat-github-actions
export TAG=latest

if [[ -z $BASE_IMG ]]; then
    BASE_IMG=${REGISTRY}/redhat-actions-runner:${TAG}
fi

if [[ -z $BULIDAH_IMG ]]; then
    BUILDAH_IMG=${REGISTRY}/redhat-buildah-runner:${TAG}
fi

set -x

cd runners/

docker build ./base -f /base/Dockerfile -t $BASE_IMG
docker build ./buildah -f ./buildah/Dockerfile -t $BUILDAH_IMG

set +x

if [[ $1 == "push" ]]; then
    set -x
    docker push $BASE_IMG
    docker push $BUILDAH_IMG
else
    echo "Not pushing. Set \$1 to 'push' to push"
fi

cd - > /dev/null
