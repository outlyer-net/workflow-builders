#!/bin/bash

set -e

IMAGE=${IMAGE:-outlyer-net/workflow-builders}
ACTION=${ACTION:-load}
REGISTRY=${REGISTRY:-ghcr.io}

STAGES='runner cbuilder'

# Construct the FQDN image to be build
# target_fqdn_image(tag_prefix, base_tag, tag_suffix)
# where
#  - tag_prefix: base image, e.g. fedora
#  - base_tag: base image tag, e.g. 39 for fedora:39
#  - tag_suffix: the stage variant, i.e. runner or cbuilder
target_fqdn_image() {
    local tag_prefix=$1
    local base_tag=$2
    local tag_suffix=$3

    # Special case
    if [[ $tag_prefix = 'opensuse/leap' ]]; then
        tag_prefix='opensuse'
    fi

    echo ${REGISTRY}/${IMAGE}:${tag_prefix}${base_tag}-${tag_suffix}
}

# extract base image id
# get_image_id(image, tag)
get_upstream_image_id() {
    local image=$1
    local tag=${2:-latest}
    # docker pull $image:$tag >&2
    # docker inspect --format '{{ .Id }}' $image:$tag
    # docker inspect --format='{{index .RepoDigests 0}}' $image:$tag | cut -d: -f2
    # Use skopeo to check the remote id
    skopeo inspect --format '{{ .Digest }}' docker://$image:$tag 2>/dev/null
}

# extract the base image id that was used to build the last version
# get_current_upstream_image_id(base_image, base_image_id, target_stage)
get_current_upstream_image_id() {
    local image=$1
    local tag=${2:-latest}
    local stage=$3
    local full_image=$(target_fqdn_image $image $tag $stage)
    skopeo inspect --format '{{ index .Labels "net.outlyer.base_image_id" }}' \
        docker://$full_image 2>/dev/null || true
}

# Checks whether the image needs to be rebuilt, i.e. if the upstream id has changed
# needs_rebuild(base_image, base_tag, target_stage)
needs_rebuild() {
    local base_image=$1
    local base_tag=$2
    local stage=$3
    
    local base_image_id=$(get_upstream_image_id $base_image $base_tag)
    local prebuilt_base_image_id=$(get_current_upstream_image_id $base_image $base_tag $stage)

    test "$base_image_id" != "$prebuilt_base_image_id"
}

# build_stage(stage, base_image, base_tag, dockerfile, [wrapper])
build_stage() {
    local stage=$1
    local base_image=$2
    local tag_prefix=${2/\/*}
    local tag=$3
    local dockerfile_prefix=$4
    local wrapper=$5

    if [[ $ACTION = 'load' ]]; then
        ACTION=build
    fi

    local base_image_id=$(get_upstream_image_id $base_image $tag)
    local full_tag=$(target_fqdn_image $base_image $tag $stage)

    if [[ $ACTION = 'build' ]]; then
        $wrapper docker $ACTION \
            -f $dockerfile_prefix.Dockerfile \
            . \
            -t $full_tag \
            --target $stage \
            --build-arg BASE_IMAGE=$base_image \
            --build-arg BASE_TAG=$tag \
            --label "net.outlyer.base_image_id=$base_image_id"
    else
        $wrapper docker $ACTION $full_tag
    fi
}

build() {
    local stage=''
    local base_image=$1
    local base_tag=$2

    for stage in $STAGES ; do
        echo "> Building $stage against $base_image:$base_tag" >&2 

        # Test whether we need to rebuild
        if ! needs_rebuild $base_image $base_tag $stage ; then
            echo "  Base image is up to date, skipping $base_image:$base_tag" >&2
            continue
        fi
    
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
        opensuse) build opensuse/leap 15 suse ;;
        fedora) build fedora 39 redhat ;;
        almalinux) build almalinux 9 redhat ;;
        *) echo "Unknown image: $param" >&2 ;;
    esac
done
