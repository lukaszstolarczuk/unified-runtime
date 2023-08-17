#! /usr/bin/env python3
"""
 Copyright (C) 2023 Intel Corporation

 Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
 See LICENSE.TXT
 SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""

import sys
from argparse import ArgumentParser
import subprocess  # nosec B404

if __name__ == '__main__':

    parser = ArgumentParser()
    parser.add_argument("--test_command", help="Ctest test case")

    args = parser.parse_args()
    result = subprocess.Popen([args.test_command, '--gtest_brief=1'], stdout = subprocess.PIPE, text = True)  # nosec B603

    while True:
        line = result.stdout.readline()
        if not line: break
        if "[  FAILED  ]" in line:
            test_case = line.split(" ")[5]
            if (test_case[-1] == ","):
                test_case = test_case[:len(test_case)-1]
                print(test_case)
    exit(0)
