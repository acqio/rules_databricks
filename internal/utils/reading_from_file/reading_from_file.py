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

parser.add_argument('--config_file', action='store', help='')
parser.add_argument('--profile', action='store', help='')
parser.add_argument('--output', action='store', help='')

def main():

    args = parser.parse_args()
    config_file = args.config_file or ""
    profile = args.profile or ""
    outfile = args.output or ""

    data = {}
    data['status'] = ''
    data['message'] = ''

    try:
        if not os.path.isfile(config_file):
            data['status'] = 'error'
            data['message'] = 'The databricks configuration file does not exist at ' + str(config_file)
        else:
            config_parser = configparser.ConfigParser()
            config_parser.read(config_file)
            section_profile = config_parser[profile]
            data['status'] = 'success'
            data['message'] = 'Profile exists'
            data['config'] = {
                'host': section_profile.get('host')
            }
    except IOError:
        data['status'] = 'error'
        data['message'] = 'The databricks configuration file does not accessible in ' + str(config_file)
    except KeyError as error:
        data['status'] = 'error'
        data['message'] = 'The ' + str(profile) + \
            ' profile does not exist in the configuration file at: ' + str(config_file)

    with open(outfile, 'w') as f:
        json.dump(data, f)

if __name__ == '__main__':
    main()
