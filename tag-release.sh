#!/bin/bash

set -e

VERSION=""
MODE="patch"
TAG_FILE="CHANGELOG.md"
RELEASE_NOTES="RELEASE_NOTES.md"
AUTO_BUMP=true

function print_help() {
  echo "Usage: ./tag-release.sh [--version X.Y.Z] [--major|--minor|--patch] [--info] [--file FILE]"
  echo ""
  echo "Options:"
  echo "  --version X.Y.Z   Set a specific version"
  echo "  --major           Increment major version"
  echo "  --minor           Increment minor version"
  echo "  --patch           Increment patch version (default)"
  echo "  --file FILE       Changelog file to read version from (default: CHANGELOG.md)"
  echo "  --info            Show current latest version"
  echo "  --help            Show this help message"
}

function get_latest_version() {
  git tag --sort=-v:refname | head -n 1 | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+"
}

function increment_version() {
  local version=$1
  local mode=$2
  IFS='.' read -r major minor patch <<< "$version"

  case $mode in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
  esac

  echo "$major.$minor.$patch"
}

function append_to_logs() {
  local version=$1
  local date=$(date +"%Y-%m-%d")
  local files=$(git diff --name-only $(git describe --tags --abbrev=0)..HEAD)

  if [[ -z "$files" ]]; then
    echo "ℹ️  No file changes since last tag."
    return
  fi

  echo -e "## [v$version] — $date\n### Changed" >> "$TAG_FILE"
  echo -e "## [v$version] — $date\n### Changed" >> "$RELEASE_NOTES"
  for file in $files; do
    echo "- $file" >> "$TAG_FILE"
    echo "- $file" >> "$RELEASE_NOTES"
  done
  echo -e "" >> "$TAG_FILE"
  echo -e "" >> "$RELEASE_NOTES"
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION=$2; AUTO_BUMP=false; shift ;;
    --major) MODE="major" ;;
    --minor) MODE="minor" ;;
    --patch) MODE="patch" ;;
    --file) TAG_FILE=$2; shift ;;
    --info)
      echo "Current Version: $(get_latest_version)"
      exit 0
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      print_help
      exit 1
      ;;
  esac
  shift
done

CURRENT_VERSION=$(get_latest_version)

# Determine new version
if [[ -z "$VERSION" ]]; then
  VERSION=$(increment_version "$CURRENT_VERSION" "$MODE")
else
  if git tag | grep -q "v$VERSION"; then
    echo "❌ Tag 'v$VERSION' already exists. Try a different version or use auto bump."
    exit 1
  fi
fi

# Append changelog and notes
append_to_logs "$VERSION"

# Final commit and tag
git add "$TAG_FILE" "$RELEASE_NOTES"
git commit -m "Release v$VERSION"
git tag "v$VERSION"
git push origin main --tags

echo "✅ Released version $VERSION with auto notes"

