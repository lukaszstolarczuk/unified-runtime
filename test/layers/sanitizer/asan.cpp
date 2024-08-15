/*
 *
 * Copyright (C) 2024 Intel Corporation
 *
 * Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE.TXT
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 * @file asan.cpp
 *
 */

#include <gtest/gtest.h>
#include <ur_api.h>

TEST(DeviceAsan, Initialization) {
    ur_result_t status;

    ur_loader_config_handle_t loaderConfig;
    status = urLoaderConfigCreate(&loaderConfig);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);
    status = urLoaderConfigEnableLayer(loaderConfig, "UR_LAYER_ASAN");
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    status = urLoaderInit(0, loaderConfig);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    ur_adapter_handle_t adapter;
    status = urAdapterGet(1, &adapter, nullptr);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    ur_platform_handle_t platform;
    status = urPlatformGet(&adapter, 1, 1, &platform, nullptr);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    ur_device_handle_t device;
    status = urDeviceGet(platform, UR_DEVICE_TYPE_DEFAULT, 1, &device, nullptr);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    ur_context_handle_t context;
    status = urContextCreate(1, &device, nullptr, &context);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    status = urContextRelease(context);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    status = urDeviceRelease(device);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    status = urAdapterRelease(adapter);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    status = urLoaderTearDown();
    ASSERT_EQ(status, UR_RESULT_SUCCESS);

    status = urLoaderConfigRelease(loaderConfig);
    ASSERT_EQ(status, UR_RESULT_SUCCESS);
}
