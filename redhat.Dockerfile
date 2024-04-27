# DO NOT use latest, only meant for test
ARG BASE_IMAGE=fedora
ARG BASE_TAG=latest

# Base image, allows running actions via nodejs and provides rpmbuild
FROM ${BASE_IMAGE}:${BASE_TAG} AS runner

# Attempt at speeding up dnf
# TODO: Remove later on
RUN echo max_parallel_downloads=10  | tee -a /etc/dnf/dnf.conf

RUN dnf install -y \
        nodejs \
        rpm-build \
    && dnf clean all \
  	&& rm -rf /var/cache/yum

# C, C++ builder, provides compilers and autotools
FROM runner AS cbuilder

# g++ already drags gcc and make
RUN dnf install -y \
        autoconf \
        automake  \
        g++ \
        gcc \
        make \
    && dnf clean all \
    && rm -rf /var/cache/yum

