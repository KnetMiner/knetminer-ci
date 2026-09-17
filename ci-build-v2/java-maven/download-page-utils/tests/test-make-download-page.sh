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
template="download-page.md.template"

doc=$(
make_download_page \
  "RDF2NEO_CLI_SNAP_URL" "$url_base" "$group_id" "$artifact_id" "zip" "false" \
	< "$template" \
  | make_download_page "RDF2NEO_CLI_STABLE_URL" "$url_base" "$group_id" "$artifact_id" "zip" "true"
)

# Placeholders have disappeared from $doc
if [[ "$doc" =~ RDF2NEO_CLI_.+_URL ]]; then
  echo "Error: Found unresolved placeholders in the document."
  exit 1
fi

printf "The generated document is:\n%s\n" "$doc"

if [[ ! "$doc" =~ https://artifactory.knetminer.com/public/.+-SNAPSHOT/rdf2neo-cli-.+\.zip ]]; then
  echo "Error: Expected SNAPSHOT URL not found in the document."
  exit 1
fi

if [[ ! "$doc" =~ https://artifactory.knetminer.com/public/.+/[0-9.]+/rdf2neo-cli-.+\.zip ]]; then
  echo "Error: Expected stable URL not found in the document."
  exit 1
fi

printf "\nHORRAY! Test completed successfully.\n"
