#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <state-slug> <release-tag> <catalog-path> <publish-plan-path>" >&2
  exit 2
fi

state_slug="$1"
release_tag="$2"
catalog_path="$3"
publish_plan_path="$4"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
work_dir="$repo_root/.release-work"
metadata_dir="$work_dir/metadata"

if ! [[ "$state_slug" =~ ^[a-z]+(-[a-z]+)*$ ]]; then
  echo "invalid state slug: $state_slug" >&2
  exit 2
fi

state_name="$(jq -r --arg slug "$state_slug" '.states[] | select(.slug == $slug) | .stateName' "$catalog_path")"
state_code="$(jq -r --arg slug "$state_slug" '.states[] | select(.slug == $slug) | .stateCode' "$catalog_path")"
pack_version="$(jq -r --arg slug "$state_slug" '.states[] | select(.slug == $slug) | .packVersion' "$catalog_path")"

if [[ -z "$state_name" || "$state_name" == "null" ]]; then
  echo "state not found in catalog: $state_slug" >&2
  exit 2
fi

mkdir -p "$work_dir" "$metadata_dir"
archive_name="posa-${state_slug}-${pack_version}.zip"
archive_path="$work_dir/$archive_name"

artifact_paths=()
while IFS= read -r source_path; do
  artifact_paths+=("$source_path")
done < <(jq -r --arg prefix "us/$state_slug/$pack_version/" '.objects[] | select(.key | startswith($prefix)) | .source' "$publish_plan_path")

if [[ ${#artifact_paths[@]} -lt 3 ]]; then
  echo "incomplete artifact list for $state_slug" >&2
  exit 1
fi

for source_path in "${artifact_paths[@]}"; do
  if [[ ! -f "$source_path" ]]; then
    echo "missing source file: $source_path" >&2
    exit 1
  fi
done

if [[ ! -f "$archive_path" ]]; then
  zip -0 -j -q "$archive_path" "${artifact_paths[@]}"
fi

archive_bytes="$(stat -f '%z' "$archive_path")"
archive_sha256="$(shasum -a 256 "$archive_path" | awk '{print $1}')"

gh release upload "$release_tag" "$archive_path" --clobber

jq -n \
  --arg stateCode "$state_code" \
  --arg stateName "$state_name" \
  --arg slug "$state_slug" \
  --arg version "$pack_version" \
  --arg fileName "$archive_name" \
  --arg sha256 "$archive_sha256" \
  --arg downloadUrl "https://github.com/Unplugged-AI/posa-data/releases/download/$release_tag/$archive_name" \
  --argjson byteSize "$archive_bytes" \
  '{stateCode: $stateCode, stateName: $stateName, slug: $slug, version: $version, fileName: $fileName, byteSize: $byteSize, sha256: $sha256, downloadUrl: $downloadUrl}' \
  > "$metadata_dir/$state_slug.json"
