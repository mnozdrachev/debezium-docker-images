#!/bin/bash

set -eo pipefail

#
# Parameter 1: image name
# Parameter 2: path to component (if different)
# Parameter 3: image tag if different from versioned
#
build_docker_image () {
    IMAGE_NAME=$1;
    IMAGE_PATH=$2;
    IMAGE_TAG=$3;
    
    if [ -z "$IMAGE_PATH" ]; then
        IMAGE_PATH=${IMAGE_NAME};
    fi

    if [ -z "$IMAGE_TAG" ]; then
        IMAGE_TAG=${DEBEZIUM_VERSION};
    fi

    IMAGE_PATH="${IMAGE_PATH}/${IMAGE_TAG}"

    echo ""
    echo "****************************************************************"
    echo "** Validating  debezium/${IMAGE_NAME}"
    echo "****************************************************************"
    echo ""
    docker run --rm -i hadolint/hadolint:latest < "${IMAGE_PATH}"

    echo "****************************************************************"
    echo "** Building    debezium/mmc-${IMAGE_NAME}:${IMAGE_TAG}"
    echo "****************************************************************"
    docker build -t "debezium/mmc-${IMAGE_NAME}:latest" "${IMAGE_PATH}"
}


if [[ -z "$1" ]]; then
    echo ""
    echo "A version must be specified."
    echo ""
    echo "Usage:  build-debezium <version>";
    echo ""
    exit 1;
fi

DEBEZIUM_VERSION="$1"

build_docker_image base base latest
build_docker_image zookeeper
build_docker_image kafka
build_docker_image connect-base
build_docker_image connect
build_docker_image server
if [[ "$SKIP_UI" != "true" ]]; then
    build_docker_image debezium-ui ui
fi
build_docker_image example-mysql examples/mysql
build_docker_image example-mysql-gtids examples/mysql-gtids
build_docker_image example-postgres examples/postgres
build_docker_image example-mongodb examples/mongodb

echo ""
echo "**********************************"
echo "Successfully created Docker images"
echo "**********************************"
echo ""
