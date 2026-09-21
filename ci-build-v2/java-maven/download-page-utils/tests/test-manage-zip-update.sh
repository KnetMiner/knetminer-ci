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

# The latest version, used to compute the package directory name inside the zip
# (eg, rdf2neo-cli_7.0.2-SNAPSHOT), and to fake an "already up to date" tracking file.
version="$(get_latest_version_from_maven "$url_base" "$group_id" "$artifact_id" zip false)"
package_dir="${artifact_id}_${version}"

# A file known to exist in the package distro, used to check the target dir was
# actually populated with real content.
package_marker_file="README.md"

# Tests manage_zip_update(), when no tracking file exists
# Verifies manage_zip_update() exits with 0
# Verifies a new tracking file was created
# Verifies a target directory is created and populated
#
function test_manage_zip_update_no_tracking_file
{
	work_dir="$(mktemp -d)"
	track_file="$work_dir/track"
	target_dir="$work_dir/target"
	mkdir -p "$target_dir"

	manage_zip_update "$track_file" "$package_dir" "$target_dir" "$url_base" "$group_id" "$artifact_id" false \
	&& update_status=0 || update_status=$?

	if [[ "$update_status" != 0 ]]; then
		echo "FAIL (no tracking file): manage_zip_update() exited with $update_status, expected 0" >&2
		exit 1
	fi

	if [[ ! -s "$track_file" ]]; then
		echo "FAIL (no tracking file): tracking file '$track_file' wasn't created" >&2
		exit 1
	fi

	if [[ ! -f "$target_dir/$package_marker_file" ]]; then
		echo "FAIL (no tracking file): target dir '$target_dir' doesn't contain expected '$package_marker_file'" >&2
		exit 1
	fi

	rm -Rf "$work_dir"
}

# Tests manage_zip_update() when a tracking file exists and an update is needed
# To simulate this, the function first creates a fake tracking file and a fake
# target directory to simulate an update.
function test_manage_zip_update_with_tracking_file
{
	work_dir="$(mktemp -d)"
	track_file="$work_dir/track"
	target_dir="$work_dir/target"
	mkdir -p "$target_dir"

	# Create a fake tracking file
	echo "0.0.0-fake" > "$track_file"

	# Create a fake target directory
	touch "$target_dir/old-marker"

	# Call manage_zip_update() and verify it exited with 0
	manage_zip_update "$track_file" "$package_dir" "$target_dir" "$url_base" "$group_id" "$artifact_id" false \
	&& update_status=0 || update_status=$?

	if [[ "$update_status" != 0 ]]; then
		echo "FAIL (with tracking file): manage_zip_update() exited with $update_status, expected 0" >&2
		exit 1
	fi

	# Verify the tracking file changed
	new_track_content="$(cat "$track_file")"
	if [[ "$new_track_content" != "$version" ]]; then
		echo "FAIL (with tracking file): tracking file content is '$new_track_content', expected '$version'" >&2
		exit 1
	fi

	# Verify the target directory is no longer empty, and doesn't contain the old marker
	if [[ -f "$target_dir/old-marker" ]]; then
		echo "FAIL (with tracking file): target dir '$target_dir' still contains the stale 'old-marker' file" >&2
		exit 1
	fi

	if [[ ! -f "$target_dir/$package_marker_file" ]]; then
		echo "FAIL (with tracking file): target dir '$target_dir' doesn't contain expected '$package_marker_file'" >&2
		exit 1
	fi

	rm -Rf "$work_dir"
}


# Tests manage_zip_update() when no update is needed
# To simulate this, the function first creates a tracking file with the latest version
# and a target directory that already contains the package contents.
function test_manage_zip_update_no_update_needed
{
	work_dir="$(mktemp -d)"
	track_file="$work_dir/track"
	target_dir="$work_dir/target"
	mkdir -p "$target_dir"

	# Use the latest version to create a tracking file
	echo "$version" > "$track_file"

	# Create a fake target directory with a foo file in it
	touch "$target_dir/foo"

	# Call manage_zip_update() and verify it exited with 3
	manage_zip_update "$track_file" "$package_dir" "$target_dir" "$url_base" "$group_id" "$artifact_id" false \
	&& update_status=0 || update_status=$?

	if [[ "$update_status" != 3 ]]; then
		echo "FAIL (no update needed): manage_zip_update() exited with $update_status, expected 3" >&2
		exit 1
	fi

	# Verify the tracking file did not change
	track_content="$(cat "$track_file")"
	if [[ "$track_content" != "$version" ]]; then
		echo "FAIL (no update needed): tracking file content changed to '$track_content', expected unchanged '$version'" >&2
		exit 1
	fi

	# Verify the target directory still contains the foo file, and nothing else
	if [[ ! -f "$target_dir/foo" ]]; then
		echo "FAIL (no update needed): target dir '$target_dir' no longer contains 'foo'" >&2
		exit 1
	fi

	target_contents="$(ls -A "$target_dir")"
	if [[ "$target_contents" != "foo" ]]; then
		echo "FAIL (no update needed): target dir '$target_dir' was modified, contains: $target_contents" >&2
		exit 1
	fi

	rm -Rf "$work_dir"
}

# Run all the tests
test_manage_zip_update_no_tracking_file
test_manage_zip_update_with_tracking_file
test_manage_zip_update_no_update_needed

printf "\nHORRAY! All tests passed.\n"
