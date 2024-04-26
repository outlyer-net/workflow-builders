# DO NOT use latest, only meant for test
ARG BASE_IMAGE=opensuse/leap
ARG BASE_TAG=latest

# Base image, allows running actions via nodejs and provides rpmbuild
FROM ${BASE_IMAGE}:${BASE_TAG} AS runner

RUN zypper install -y \
        nodejs \
        rpm-build \
    && zypper clean -a \
    && rm -rf /var/log/zypp /var/log/zypper.log

# C, C++ builder, provides compilers and autotools
FROM runner AS cbuilder

# g++ already drags gcc and make
RUN zypper install -y \
        autoconf \
        automake  \
        g++ \
        gcc \
        make \
    && zypper clean -a \
    && rm -rf /var/log/zypp /var/log/zypper.log

