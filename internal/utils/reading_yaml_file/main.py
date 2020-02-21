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
"""Resolve stamp variables."""
import yaml
import argparse
import json
import sys
import os

parser = argparse.ArgumentParser(description='Resolve stamp references.')

parser.add_argument('--yaml', action='store', help='')
parser.add_argument('--maven-coordinates', action='store', help='')
parser.add_argument('--output', action='store', help='')

def main():
    args = parser.parse_args()

    bazel_coordinate = json.loads(args.maven_coordinates)
    bazel_deps_coordinate = {}

    with open(args.yaml, 'r') as file:
      y = yaml.load(file, Loader=yaml.FullLoader)
      bazel_deps_coordinate['dependencies'] = y['dependencies']
      bazel_deps_coordinate['repo'] = y['options']['resolvers']

    for repo, coordinate in bazel_coordinate.items():
        # print(repo)
        # print(coordinate)
        if not repo in [repo['url'] for repo in bazel_deps_coordinate['repo']]:
          print("levanta exception")
    print ([c for c in coordinate])

if __name__ == '__main__':
  main()
