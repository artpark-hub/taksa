#!/bin/bash

# Script to initialize and update all submodules
echo "Initializing and updating submodules for Taksa..."

# Get branch from VERSION file
VERSION_FILE="$(dirname "$0")/../VERSION"
if [ -f "$VERSION_FILE" ]; then
    BRANCH=$(grep BRANCH "$VERSION_FILE" | cut -d'=' -f2)
else
    BRANCH="release/0.0.x"
fi

echo "Target branch: $BRANCH"

git submodule update --init --recursive
git submodule foreach "git fetch && git checkout $BRANCH || true"
git submodule foreach "git pull origin $BRANCH || true"

if [ $? -eq 0 ]; then
    echo "Successfully updated all submodules."
else
    echo "Failed to update submodules. Please check your git configuration and SSH keys."
    exit 1
fi
