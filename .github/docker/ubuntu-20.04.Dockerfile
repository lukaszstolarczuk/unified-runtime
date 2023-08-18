# Copyright (C) 2023 Intel Corporation
# Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE.TXT
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#
# Dockerfile - image with all Unified Runtime dependencies.
#

# Pull base image
FROM registry.hub.docker.com/library/ubuntu:20.04

# Set environment variables
ENV OS ubuntu
ENV OS_VER 20.04
ENV NOTTY 1
ENV DEBIAN_FRONTEND noninteractive

# Additional parameters to build docker without building components.
# These ARGs can be set in docker building phase and are used
# within bash scripts (executed within docker).
ARG SKIP_DPCPP_BUILD
ARG SKIP_LIBBACKTRACE_BUILD

# Base development packages
ARG BASE_DEPS="\
	build-essential \
	cmake \
	git"

# Unified Runtime's dependencies
ARG UR_DEPS="\
	doxygen \
	python3 \
	python3-pip"

# Miscellaneous for our builds/CI (optional)
ARG MISC_DEPS="\
	clang \
	g++-7 \
	sudo \
	wget \
	whois"

# Update and install required packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
	${BASE_DEPS} \
	${UR_DEPS} \
	${MISC_DEPS} \
 && apt-get clean all

# Additional dependencies (installed via pip)
COPY third_party/requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

# Install DPC++
COPY .github/docker/install_dpcpp.sh install_dpcpp.sh
ENV DPCPP_PATH=/opt/dpcpp
RUN ./install_dpcpp.sh

# Install libbacktrace
COPY .github/docker/install_libbacktrace.sh install_libbacktrace.sh
RUN ./install_libbacktrace.sh

# Add a new (non-root) 'user'
ENV USER user
ENV USERPASS pass
RUN useradd -m $USER -g sudo -p `mkpasswd $USERPASS`
