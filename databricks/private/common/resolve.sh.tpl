#!/usr/bin/env bash

set -euo pipefail

function exe() { echo "\$ ${@/eval/}" ; "$@" ; }

%{VARIABLES}
%{CONDITIONS}
%{CMD}
