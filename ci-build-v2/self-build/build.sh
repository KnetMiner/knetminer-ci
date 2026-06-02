#!/usr/bin/env bash

# As said in the README, for now we just deal with releasing.

set -eE -o pipefail

. "./ci-build-v2/_common.sh"
main
