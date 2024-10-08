# Copyright (C) 2022-2023 Intel Corporation
# Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE.TXT
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

add_ur_library(ur_common STATIC
    ur_util.cpp
    ur_util.hpp
    latency_tracker.hpp
    $<$<PLATFORM_ID:Windows>:windows/ur_lib_loader.cpp>
    $<$<PLATFORM_ID:Linux,Darwin>:linux/ur_lib_loader.cpp>
)

add_library(${PROJECT_NAME}::common ALIAS ur_common)

target_include_directories(ur_common PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
)

message(STATUS "Download Unified Memory Framework from github.com")
if (NOT DEFINED UMF_REPO)
    set(UMF_REPO "https://github.com/oneapi-src/unified-memory-framework.git")
endif()

if (NOT DEFINED UMF_TAG)
    # v0.9.x 23.08.2024: Merge pull request #696 ...
    set(UMF_TAG 3c340e61c197f4f9e29abd947f90ce27c571433e)
endif()

message(STATUS "Will fetch Unified Memory Framework from ${UMF_REPO}")

include(FetchContent)
FetchContent_Declare(unified-memory-framework
    GIT_REPOSITORY    ${UMF_REPO}
    GIT_TAG           ${UMF_TAG}
)

set(UMF_BUILD_TESTS OFF CACHE INTERNAL "Build UMF tests")
set(UMF_BUILD_EXAMPLES OFF CACHE INTERNAL "Build UMF examples")
# TODO: L0 provider not ready yet
set(UMF_BUILD_LEVEL_ZERO_PROVIDER OFF CACHE INTERNAL "Build Level Zero Provider")
set(UMF_BUILD_SHARED_LIBRARY ${UMF_BUILD_SHARED_LIBRARY} CACHE INTERNAL "Build UMF shared library")
set(UMF_BUILD_LIBUMF_POOL_DISJOINT ON CACHE INTERNAL "Build Disjoint Pool")

FetchContent_MakeAvailable(unified-memory-framework)
FetchContent_GetProperties(unified-memory-framework)

if(UR_ENABLE_LATENCY_HISTOGRAM)
    set(HDR_HISTOGRAM_BUILD_STATIC CACHE INTERNAL ON "")
    set(HDR_HISTOGRAM_BUILD_SHARED CACHE INTERNAL OFF "")

    include(FetchContent)
    FetchContent_Declare(hdr_histogram
        GIT_REPOSITORY    https://github.com/HdrHistogram/HdrHistogram_c.git
        GIT_TAG           0.11.8
    )

    FetchContent_MakeAvailable(hdr_histogram)
    FetchContent_GetProperties(hdr_histogram)

    target_link_libraries(ur_common PUBLIC hdr_histogram_static)
    target_include_directories(ur_common PUBLIC $<BUILD_INTERFACE:${hdr_histogram_SOURCE_DIR}/include>)
    target_compile_options(ur_common PUBLIC -DUR_ENABLE_LATENCY_HISTOGRAM=1)
endif()

target_link_libraries(ur_common PUBLIC
    ${CMAKE_DL_LIBS}
    ${PROJECT_NAME}::headers
)

if (UNIX)
    set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
    set(THREADS_PREFER_PTHREAD_FLAG TRUE)
    find_package(Threads REQUIRED)
    target_link_libraries(ur_common PUBLIC Threads::Threads)
endif()

install(TARGETS ur_common
    EXPORT ${PROJECT_NAME}-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

add_library(ur_umf INTERFACE)
target_sources(ur_umf INTERFACE
    umf_helpers.hpp
    umf_pools/disjoint_pool_config_parser.cpp
    ur_pool_manager.hpp
)

add_library(${PROJECT_NAME}::umf ALIAS ur_umf)

target_link_libraries(ur_umf INTERFACE
    umf::umf
    umf::headers
    umf::disjoint_pool
)
