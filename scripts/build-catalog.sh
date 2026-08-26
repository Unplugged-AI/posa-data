#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <source-catalog-path> <release-tag> <output-path>" >&2
  exit 2
fi

source_catalog="$1"
release_tag="$2"
output_path="$3"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
metadata_dir="$repo_root/.release-work/metadata"

metadata_count="$(find "$metadata_dir" -maxdepth 1 -type f -name '*.json' | wc -l | tr -d ' ')"
expected_count="$(jq -r '.stateCount' "$source_catalog")"

if [[ "$metadata_count" != "$expected_count" ]]; then
  echo "expected $expected_count package records, found $metadata_count" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_path")"

jq -s \
  --slurpfile source "$source_catalog" \
  --arg releaseUrl "https://github.com/Unplugged-AI/posa-data/releases/tag/$release_tag" \
  'sort_by(.stateName) as $states | {
    schemaVersion: 1,
    catalogVersion: $source[0].catalogVersion,
    generatedAt: $source[0].generatedAt,
    region: $source[0].region,
    stateCount: ($states | length),
    totalBytes: ($states | map(.byteSize) | add),
    releaseUrl: $releaseUrl,
    dataLicense: $source[0].dataLicense,
    formats: {
      archive: "ZIP",
      map: "Mapsforge v5",
      poi: "Mapsforge POI v3"
    },
    sourceSnapshotsAligned: false,
    safetyNotice: "Mapped data does not prove current access, conditions, availability, potability, operating hours, or route safety.",
    states: $states
  }' "$metadata_dir"/*.json > "$output_path"
