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

fail_count=0

function assert_match
{
	description="$1"
	value="$2"
	pattern="$3"

	if [[ "$value" =~ $pattern ]]; then
		printf "|== PASS: %s ('%s')\n" "$description" "$value"
	else
		printf "|== FAIL: %s: '%s' doesn't match '%s'\n" "$description" "$value" "$pattern"
		fail_count=$((fail_count + 1))
	fi
}

function assert_no_match
{
	description="$1"
	value="$2"
	pattern="$3"

	if [[ "$value" =~ $pattern ]]; then
		printf "|== FAIL: %s: '%s' unexpectedly matches '%s'\n" "$description" "$value" "$pattern"
		fail_count=$((fail_count + 1))
	else
		printf "|== PASS: %s ('%s')\n" "$description" "$value"
	fi
}

function assert_downloadable
{
	description="$1"
	url="$2"

	if curl --head --fail --silent "$url" > /dev/null; then
		printf "|== PASS: %s is downloadable ('%s')\n" "$description" "$url"
	else
		printf "|== FAIL: %s is NOT downloadable ('%s')\n" "$description" "$url"
		fail_count=$((fail_count + 1))
	fi
}

# get_latest_version_from_maven(): default (snapshot) version
snapshot_version="$(get_latest_version_from_maven "$url_base" "$group_id" "$artifact_id" zip false)"
assert_match "latest version (default)" "$snapshot_version" '-SNAPSHOT$'

# get_latest_version_from_maven(): stable release version
release_version="$(get_latest_version_from_maven "$url_base" "$group_id" "$artifact_id" zip true)"
assert_no_match "latest version (stable release)" "$release_version" '-SNAPSHOT$'

# get_download_url_from_maven(): default (snapshot) download URL, resolved to a timestamped build
snapshot_url="$(get_download_url_from_maven "$url_base" "$group_id" "$artifact_id" zip false)"
assert_match "download URL (default)" "$snapshot_url" '-[0-9]{8}\.[0-9]{6}-[0-9]+\.zip$'
assert_downloadable "download URL (default)" "$snapshot_url"

# get_download_url_from_maven(): stable release download URL, no timestamp
release_url="$(get_download_url_from_maven "$url_base" "$group_id" "$artifact_id" zip true)"
assert_match "download URL (stable release)" "$release_url" "-${release_version}\.zip\$"
assert_downloadable "download URL (stable release)" "$release_url"

# get_download_url_from_maven() against Maven Central directly (not the KnetMiner
# artifactory), to check the standard-layout resolution isn't Reposilite-specific.
central_url="$(get_download_url_from_maven https://repo1.maven.org/maven2 \
  org.springframework.boot spring-boot-starter-web jar false)"
assert_match "download URL (Maven Central)" "$central_url" '^https://repo1\.maven\.org/maven2/org/springframework/boot/spring-boot-starter-web/[^/]+/spring-boot-starter-web-[^/]+\.jar$'
assert_downloadable "download URL (Maven Central)" "$central_url"

if [[ "$fail_count" -gt 0 ]]; then
	printf "\n|==== %d test(s) FAILED\n" "$fail_count" >&2
	exit 1
fi

printf "\n|==== All tests PASSED\n"
