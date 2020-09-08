#!/usr/bin/env bash

set -x
set -e

# like v1.4.145
latest_version=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/KhronosGroup/Vulkan-Docs/tags |
  jq --raw-output 'map(.name) | .[]' |
  sort | tail -n1)
version=${1:-$latest_version}

# For GitHub actions
echo "::set-output name=vulkan_version::$version"

if git -C generate-new/Vulkan-Docs describe --tags | grep $version; then
  echo "Vulkan-Docs is already at $version"
  exit 0
fi

echo "Updating Vulkan-Docs"
git -C generate-new/Vulkan-Docs fetch
git -C generate-new/Vulkan-Docs checkout "$version"

git add generate-new/Vulkan-Docs

if ! ./regenerate.sh; then
  echo "Failed to regenerate vulkan source"
  git restore --staged src/Vulkan src/Vulkan.hs
  git checkout src/Vulkan src/Vulkan.hs
  exit 1
fi

git add src
git add vulkan.cabal

if git diff --cached --no-ext-diff --quiet --exit-code; then
  echo "no changes"
else
  echo "Adding version bump to changelog"
  sed -i.bak "s/^## WIP$/\0\n  - Bump API version to $version/" changelog.md
  git add changelog.md

  git commit -m "Bump vulkan version to $version"
fi
