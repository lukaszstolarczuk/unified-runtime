# Copyright (C) 2023-2024 Intel Corporation
# Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE.TXT
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#
# Dockerfile - a 'recipe' for Docker to build an image of rockylinux-based
#              environment for building the Unified Runtime project.
#

# Pull base image
FROM registry.hub.docker.com/library/rockylinux:9

# Set environment variables
ENV OS rockylinux
ENV OS_VER 9
ENV NOTTY 1

# Additional parameters to build docker without building components.
# These ARGs can be set in docker building phase and are used
# within bash scripts (executed within docker).
ARG SKIP_DPCPP_BUILD
ARG SKIP_LIBBACKTRACE_BUILD

# Base development packages
ARG BASE_DEPS="\
	cmake \
	git \
	glibc-devel \
	libstdc++-devel \
	make"

# Unified Runtime's dependencies
ARG UR_DEPS="\
	doxygen \
	python3 \
	python3-pip"

# Miscellaneous for our builds/CI (optional)
ARG MISC_DEPS="\
	clang \
	ncurses-libs-6.2 \
	passwd \
	sudo \
	wget"

# Update and install required packages
RUN dnf update -y \
 && dnf --enablerepo devel install -y \
	${BASE_DEPS} \
	${UR_DEPS} \
	${MISC_DEPS} \
 && dnf clean all

# Prepare a dir (accessible by anyone)
RUN mkdir --mode 777 /opt/ur/

# Additional dependencies (installed via pip)
COPY third_party/requirements.txt /opt/ur/requirements.txt
RUN pip3 install --no-cache-dir -r /opt/ur/requirements.txt

# Install DPC++
COPY .github/docker/install_dpcpp.sh /opt/ur/install_dpcpp.sh
ENV DPCPP_PATH=/opt/dpcpp
RUN /opt/ur/install_dpcpp.sh

# Install libbacktrace
COPY .github/docker/install_libbacktrace.sh /ur/opt/install_libbacktrace.sh
RUN /ur/opt/install_libbacktrace.sh

# Add a new (non-root) 'user'
ENV USER user
ENV USERPASS pass
# Change shell to bash with safe pipe usage
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]
RUN useradd -m $USER \
 && echo "${USERPASS}" | passwd "${USER}" --stdin \
 && gpasswd wheel -a "${USER}" \
 && echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Change shell back to default
SHELL ["/bin/sh", "-c"]