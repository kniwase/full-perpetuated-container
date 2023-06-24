#!/bin/bash -e

function main() {
    local BASE_DIR="$(dirname "$0")"
    local IMAGE_NAME="ubuntu-$(uuidgen)"
    # request sudo
    echo "This script requests root privileges."
    sudo bash -c :
    # create container filesystem directory
    mkdir "${BASE_DIR}/filesystem"
    # build image
    docker \
        build \
        -t "${IMAGE_NAME}" \
        --build-arg UID="$(id -u)" \
        --build-arg GID="$(id -g)" \
        --build-arg "UNAME=$(id -un)" \
        --build-arg "SSH_KEY=$(cat ~/.ssh/id_*.pub ~/.ssh/authorized_keys)" \
        -f Dockerfile \
        "${BASE_DIR}"
    # create base container
    docker container run --name "${IMAGE_NAME}" "${IMAGE_NAME}" bash
    # export and extract base container to filesystem directory
    docker export "${IMAGE_NAME}" | sudo tar x -C "${BASE_DIR}/filesystem"
    # remove base container and image
    docker rm "${IMAGE_NAME}"
    docker rmi "${IMAGE_NAME}"
    # start perpetuated container
    if [ -z "$(docker-compose)" ]; then
        docker-compose -f "${BASE_DIR}/docker-compose.yml" up -d --build
    else
        docker compose -f "${BASE_DIR}/docker-compose.yml" up -d --build
    fi
    # massage
    echo "To connect perpetuated container"
    echo "$ ssh -p 52222 $(id -un)@localhost"
}
main $@
