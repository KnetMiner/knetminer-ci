#!/usr/bin/env bash

# Scripts to Get download URLs for Maven artifacts and update download pages
# 
# WARNING: require xmllint (from libxml2)
#

set -e -o pipefail

# Fetches a maven-metadata.xml document from the given URL and evaluates an XPath expression
# against it, printing the result.
# For instance:
# get_maven_metadata_field \
#   https://artifactory.knetminer.com/public/uk/ac/rothamsted/kg/rdf2neo-cli/maven-metadata.xml \
#   'string(/metadata/versioning/latest)'
#
function get_maven_metadata_field
{
	metadata_url="$1"
	xpath="$2"

	field="$(curl --fail --silent --show-error "$metadata_url" | xmllint --xpath "$xpath" -)"

	if [[ -z "$field" ]]; then
		printf "\n\nERROR: couldn't get '%s' from '%s'\n\n" "$xpath" "$metadata_url" >&2
		exit 1
	fi

	echo "$field"
}

# Gets the latest version of a Maven artifact from the specified repository.
# For instance:
# get_latest_version_from_maven \
#   https://artifactory.knetminer.com/#/public \
#   uk.ac.rothamsted.kg \
#   rdf2neo-cli \
#   zip \
#   false
# Will yield something like 7.0.2-SNAPSHOT
# With $5 set to true, it will yield something like 7.0.1 (the latest stable release)
#
function get_latest_version_from_maven
{
	url_base="$1"
	group_id="$2"
	artifact_id="$3"
	extension="${4:-zip}"
	want_stable_release="${5:-false}"

	# The example URL above is the Reposilite web UI address, '#/' is a client-side route,
	# not part of the real file path.
	url_base="${url_base%/}"
	url_base="${url_base//#\//}"
	group_path="${group_id//./\/}"

	metadata_url="$url_base/$group_path/$artifact_id/maven-metadata.xml"

	if [[ "$want_stable_release" == "true" ]]; then
		xpath="string(/metadata/versioning/release)"
	else
		# Not every repository (eg, Reposilite) generates <latest>, but <versions> is always
		# there, with the actual latest version being the last one listed.
		xpath="string(/metadata/versioning/versions/version[last()])"
	fi

	get_maven_metadata_field "$metadata_url" "$xpath"
}

# Calls get_latest_version_from_maven() and returns the full download URL for the latest version
# of an artifact.
function get_download_url_from_maven
{
	url_base="$1"
	group_id="$2"
	artifact_id="$3"
	extension="${4:-zip}"
	want_stable_release="${5:-false}"

	url_base="${url_base%/}"
	url_base="${url_base//#\//}"
	group_path="${group_id//./\/}"

	version="$(get_latest_version_from_maven "$url_base" "$group_id" "$artifact_id" "$extension" "$want_stable_release")"

	if [[ "$version" == *-SNAPSHOT ]]; then
		version_metadata_url="$url_base/$group_path/$artifact_id/$version/maven-metadata.xml"
		xpath="string(//snapshotVersions/snapshotVersion[extension='$extension'][not(classifier)][1]/value)"
		file_version="$(get_maven_metadata_field "$version_metadata_url" "$xpath")"
	else
		file_version="$version"
	fi

	echo "$url_base/$group_path/$artifact_id/$version/$artifact_id-$file_version.$extension"
}


# Creates a download page starting from a template document, where to replace a placeholder
# for the download URL of a Maven artifact.
# 
# This first calls get_download_url_from_maven() to get the actual download URL, and 
# then does the placeholder injection.
# 
# The template (like a .md document) comes from the standard output and the output 
# is written to the standard output. This allows for chaining multiple invocations
# of this utility, when the template has multiple placeholders/URLs to be replaced.
# 
function make_download_page
{
	# This is wrapped into ${}. Eg, if you give FOO_URL, then it will look for ${FOO_URL} in the template.
	placeholder="$1"
	url_base="$2"
	group_id="$3"
	artifact_id="$4"
	extension="${5:-zip}"
	want_stable_release="${6:-false}"

	download_url="$(get_download_url_from_maven "$url_base" "$group_id" "$artifact_id" "$extension" "$want_stable_release")"
	sed "s|\${$placeholder}|$download_url|g"
}


# Checks if a Maven package installed locally needs to be updated, based on the latest deployment version
# saved in a local tracking file and the latest version available in the Maven repository 
# (using get_latest_version_from_maven()).
#
# Exit with 0 status if an update is needed, 3 if not. The latter allows you to treat
# other exit codes as errors.
function needs_update
{
	track_file="$1"
	url_base="$2"
	group_id="$3"
	artifact_id="$4"
	extension="${5:-zip}"
	want_stable_release="${6:-false}"

	latest_version="$(get_latest_version_from_maven "$url_base" "$group_id" "$artifact_id" "$extension" "$want_stable_release")"
	if [[ ! -f "$track_file" ]]; then
		return 0
	fi
	installed_version="$(cat "$track_file")"
	if [[ "$installed_version" != "$latest_version" ]]; then
		return 0
	fi
	return 3
}


# Manages a Maven local installation update, by first checking if an update is needed (using needs_update()) 
# and then performing the update if needed. This works ONLY with zip files on a Maven repository.
# 
# If a successful update is performed, updates the tracking file with the new version.
#
# Return 0 if an update was performed, 3 if no update was needed, anything else if an error occurred.
#
# WARNING: this doesn't do anything about permissions/ownership of the files at $target_dir
# This is up to the invoker of this function.
# Similarly, $target_dir must be writeable by this function.
#
function manage_zip_update
{
	track_file="$1" # The version tracking file
	package_dir="$2" # The root inside the package distro archive (eg, my-util)
	target_dir="$3" # Where to deploy the package
	# These are the same as in needs_update() and get_download_url_from_maven()
	url_base="$4"
	group_id="$5"
	artifact_id="$6"
	want_stable_release="${7:-false}"

	needs_update \
	  "$track_file" "$url_base" "$group_id" "$artifact_id" "zip" "$want_stable_release" \
	&& [[ $? == 0 ]] || return 3

	download_url="$(get_download_url_from_maven "$url_base" "$group_id" "$artifact_id" "zip" "$want_stable_release")"
	distro_path="$(mktemp /tmp/_ci-build-v2-pkg-XXXX)"

  pushd /tmp
  rm -Rf "$distro_path"
	curl -L -o "$distro_path" "$download_url"
  rm -Rf "$package_dir"
  unzip "$distro_path"
	popd # Goes back to where we were, just in case
  
  # This is to delete the target dir contents, without removing the dir itself
  # That's necessary in order to keep the target Unix membership and its 
  # GID settings, which, in turn is necessary to keep write permissions for 
  # our users
  find "$target_dir" -mindepth 1 -delete
  
  # Similarly, copies the package contents into the existing container
  cp --recursive --no-dereference --preserve=timestamps "$package_dir/." "$target_dir"
  rm -Rf "/tmp/$package_dir"

	# Eventually, get the new version again and update the tracking file
	new_version="$(get_latest_version_from_maven "$url_base" "$group_id" "$artifact_id" "zip" "$want_stable_release")"
	echo "$new_version" > "$track_file"
	return 0
}