# RPM builders for workflows

This repository provides a series of container images meant to be used with
GitHub workflows (and compatible systems like Gitea and Forgejo).

They provide the means to build RPM packages in an RPM-based distribution
inside a workflow.

Unlike GitHub's runner images, these are meant to be as small and basic as
possible, to be installed quickly and without space issues in Gitea/Forgejo
installations.

The images are rebuilt once per day if their corresponding official distribution image is updated.

Each distribution has two different images:
* `runner`: Allows running actions and building RPMs
* `cbuilder`: Extends `runner` by adding a GCC/G++ and autotools toolchain

The following distributions are available:
* Fedora 39
* AlmaLinux 9 
* openSUSE/Leap 15 

Images are named following the pattern: ghcr.io/docker-builders:_&lt;distribution>&lt;version>_-_&lt;variation>_, e.g. `ghcr.io/outlyer-net/workflow-builders:fedora39-runner`.

## Usage

The images can be used in a workflow, with e.g.:

~~~yaml
  ·
  ·
  ·
  job:
    container:
      image: ghcr.io/outlyer-net/workflow-builders:fedora39-runner
    steps:
      - use: actions/checkout@v3
  ·
  ·
  ·
~~~

## Building

The images can be built with:

Build all images:
~~~shell
./make.bash
~~~

Build only selected images:
~~~shell
./make.bash fedora opensuse
~~~

Environment variables can be defined to override the image tag:

* `REGISTRY`: defaults to `ghcr.io`
* `IMAGE`: defaults to `outlyer-net/workflow-builders`
* `ACTION`: defaults to `load`, can also be set to `push` to push to the registry

e.g.:

~~~shell
env REGISTRY=docker.io IMAGE=myuser/myimage ACTION=push ./make.bash
~~~

will build and push the images to Docker Hub for user `myuser` and image name `myimage`.