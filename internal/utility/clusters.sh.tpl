#!/usr/bin/env sh

# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -e

PYTHON="%{PYTHON}"
CLI="%{CLI}"
CLI_OPTIONS="%{CLI_OPTIONS}"
CLI_COMMAND="%{CLI_COMMAND}"
CLUSTER_NAME="%{CLUSTER_NAME}"
JQ_PATH="%{JQ_PATH}"
OUTPUT="%{JSON_CLUSTER_INFO}"
# tree -d

CLUSTER_CONFIG=$($PYTHON $CLI $CLI_OPTIONS clusters list  --output JSON | \
 $JQ_PATH -r '(.clusters[] | select (.cluster_name=="'$CLUSTER_NAME'")).cluster_id')

echo $CLUSTER_CONFIG

echo 'ahadhjks' > $OUTPUT
