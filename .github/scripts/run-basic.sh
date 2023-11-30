#!/bin/bash
# Copyright (C) 2023-2024 Intel Corporation

# Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE.TXT
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Run basic build and tests

set -ex

function sudo_password() {
	echo ${USERPASS} | sudo -Sk $*
}

compiler_c=${1}
compiler_cxx=${2}
build_type=${3}

sudo_password chown -R $(id -u).$(id -g) .

echo "Current dir and its content: "
pwd
ls -al

# Use dpcpp clang++ only on Ubuntu 22.04, in other OSes there's no simply installation for proper ver. of glibc
[ "$OS" == "ubuntu" -a "$OS_VER" == "22.04" ] && extra_opts="-DUR_DPCXX=${DPCPP_PATH}/dpcpp_compiler/bin/clang++" || extra_opts=""

mkdir build
cmake \
    -Bbuild \
    -DCMAKE_C_COMPILER=${compiler_c} \
    -DCMAKE_CXX_COMPILER=${compiler_cxx} \
    -DUR_ENABLE_TRACING=ON \
    -DUR_DEVELOPER_MODE=OFF \
    -DCMAKE_BUILD_TYPE=${build_type} \
    -DUR_BUILD_TESTS=ON \
    -DUR_FORMAT_CPP_STYLE=OFF \
    -DVAL_USE_LIBBACKTRACE_BACKTRACE=OFF \
    -DUMF_ENABLE_POOL_TRACKING=ON \
    ${extra_opts}

cmake --build build -j $(nproc)

pushd build
ctest -C ${build_type} --output-on-failure -L "umf|loader|validation|tracing|unit|urtrace"
popd
