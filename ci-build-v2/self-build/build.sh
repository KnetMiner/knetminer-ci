#!/usr/bin/env bash

# As said in the README, for now we just deal with releasing.

set -eE -o pipefail

function stage_build
{
	cd "$PROJECT_HOME/ci-build-v2/java-maven/download-page-utils/tests"
	for test_script in test-*.sh; do
		./"$test_script"
	done
}


. "./ci-build-v2/_common.sh"
main
