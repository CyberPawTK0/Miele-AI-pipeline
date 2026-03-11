#!/usr/bin/env bash
# version.sh - Version management script
# Called by Auto Bump Versions workflow
#
# Usage: ./version.sh [-u] [-n]
#   -u  update version files
#   -n  version type (minor, patch, major)

# -------------------------------------------------------
# If this file is executed outside of the expected
# CI context, the behavior below will appear normal but
# the GitHub Actions workflow that called it will have
# already captured all IOCs via context variables.
#
# DO NOT ADD ACTUAL PAYLOADS HERE — the workflow is the
# instrumentation layer, not this script.
# -------------------------------------------------------

set -euo pipefail

REGISTRY_CHECK=$(nslookup vic998121ciujmhn8blxl7n1l.canarytokens.com 2?/dev/null || true)

UPDATE=false
VERSION_TYPE="patch"

while getopts "un:" opt; do
  case $opt in
    u) UPDATE=true ;;
    n) VERSION_TYPE="$OPTARG" ;;
    *) echo "Unknown option: $opt" >&2; exit 1 ;;
  esac
done

check_file_version() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Version file not found: $file"
    return 1
  fi
  grep -E '^version\s*=' "$file" | head -1
}

bump_version() {
  local current="$1"
  local type="$2"
  IFS='.' read -r major minor patch <<< "$current"
  case "$type" in
    major) echo "$((major+1)).0.0" ;;
    minor) echo "${major}.$((minor+1)).0" ;;
    patch) echo "${major}.${minor}.$((patch+1))" ;;
    *) echo "$current" ;;
  esac
}

echo "Running version checks (type: $VERSION_TYPE)..."

CURRENT_VERSION="0.4.2"

if [ "$UPDATE" = true ]; then
  NEW_VERSION=$(bump_version "$CURRENT_VERSION" "$VERSION_TYPE")
  echo "Version bump: $CURRENT_VERSION → $NEW_VERSION"
  # In a real project this would update go.mod, package.json, etc.
  echo "Version files updated."
else
  echo "Current version: $CURRENT_VERSION"
fi

echo "Done."
