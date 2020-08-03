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
import configparser
import json
import argparse
import sys
import os

parser = argparse.ArgumentParser(description='Resolve stamp references.')

parser.add_argument('--config_file', action='store', help='', required=True)
parser.add_argument('--profile', action='store', help='', required=True)

def main():

    args = parser.parse_args()
    config_file = args.config_file or ""
    profile = args.profile or ""

    try:
        if not os.path.isfile(config_file):
            raise Exception('The Databricks configuration file does not exist at "{}"'.format(str(config_file)))
        else:
            config_parser = configparser.ConfigParser()
            config_parser.read(config_file)
            section_profile = config_parser[profile]
            print('Using the profile: "{}"'.format(profile))
    except IOError:
        raise Exception('The Databricks configuration file does not accessible at: {}'.format(str(config_file)))
    except KeyError as error:
        raise Exception(
            'The "{}" profile does not exist in the Databricks configuration file at: {}'.format(
                str(profile), str(config_file))
            )

if __name__ == '__main__':
    main()
