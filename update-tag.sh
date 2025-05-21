#!/bin/bash

# Default to v1 if VERSION is not set
VERSION=${VERSION:-v1}
echo "Updating tag: $VERSION"

# Check if the tag exists locally
if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
  echo "Deleting existing $VERSION tag locally"
  git tag -d $VERSION
else
  echo "No local $VERSION tag found"
fi

# Check if the tag exists on remote
if git ls-remote --tags origin | grep -q "refs/tags/$VERSION"; then
  echo "Deleting existing $VERSION tag on remote"
  git push --delete origin $VERSION
else
  echo "No remote $VERSION tag found"
fi

# Create a new tag at the current HEAD
echo "Creating new $VERSION tag at current HEAD"
git tag $VERSION

# Push the new tag to the remote repository
echo "Pushing $VERSION tag to remote"
git push origin $VERSION

echo "Tag $VERSION has been updated to point to the current HEAD"
