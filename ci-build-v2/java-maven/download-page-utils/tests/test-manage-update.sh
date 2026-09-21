#!/usr/bin/env bash
set -e -o pipefail

# Tests for download-page-utils.sh, run against the real KnetMiner artifactory (network
# required, as with the rest of this repo's scripts).
#
cd "$(dirname "${BASH_SOURCE[0]}")"
source ../download-page-utils.sh

url_base="https://artifactory.knetminer.com/#/public"
group_id="uk.ac.rothamsted.kg"
artifact_id="rdf2neo-cli"

# Tests manage_update(), when no tracking file exists
# Verifies manage_update() exits with 0
# Verifies a new tracking file was created
# Verifies a target directory is created and populated
#
function test_manage_update_no_tracking_file 
{
}

# Tests manage_update() when a tracking file exists and an update is needed
# To simulate this, the function first creates a fake tracking file and a fake
# target directory to simulate an update.
function test_manage_update_with_tracking_file
{
	# Create a fake tracking file
	# Create a fake target directory
	# Call manage_update() and verify it exited with 0
	# Verify the tracking file changed
	# Verify the target directory is no longer empty
}


# Tests manage_update() when no update is needed
# To simulate this, the function first creates a tracking file with the latest version
# and a target directory that already contains the package contents.
function test_manage_update_no_update_needed
{
	# Get the latest version from the Maven repository
	# Use the latest version to create a tracking file
	# Create a fake target directory with a foo file in it
	# Call manage_update() and verify it exited with 1
	# Verify the tracking file did not change
	# Verify the target directory still contains the foo file
}

# Run all the tests
test_manage_update_no_tracking_file
test_manage_update_with_tracking_file
test_manage_update_no_update_needed
