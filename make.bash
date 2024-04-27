#!/bin/bash

IMAGE=${IMAGE:-outlyer-net/workflow-builders}
ACTION=${ACTION:-load}
REGISTRY=${REGISTRY:-ghcr.io}

STAGES='runner cbuilder'

# build_stage(stage, base_image, base_tag, dockerfile, [wrapper])
build_stage() {
    local stage=$1
    local base_image=$2
    local tag_prefix=${2/\/*}
    local tag=$3
    local dockerfile_prefix=$4
    local wrapper=$5

    $wrapper docker buildx build \
        --$ACTION \
        --progress plain \
        -f $dockerfile_prefix.Dockerfile \
        . \
        -t ${REGISTRY}/${IMAGE}:${tag_prefix}${tag}-${stage} \
        --target $stage \
        --build-arg BASE_IMAGE=$base_image \
        --build-arg BASE_TAG=$tag
}

build() {
    for stage in $STAGES ; do
        build_stage $stage $@ echo
        build_stage $stage $@
    done
}

if [[ -z $1 ]]; then
    set -- opensuse fedora almalinux
fi

cat >&2 <<EOF
Running with:
 - REGISTRY: $REGISTRY
 -    IMAGE: $IMAGE
 -   ACTION: $ACTION
EOF

for param in "$@" ; do
    case $param in
        opensuse) echo build opensuse/leap 15 suse ;;
        fedora) echo build fedora 39 redhat ;;
        almalinux) echo build almalinux 9 redhat ;;
        *) echo "Unknown image: $param" >&2 ;;
    esac
done
