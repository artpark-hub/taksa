#!/bin/bash

# Script to initialize and update all submodules
echo "Initializing and updating submodules for Taksa..."

git submodule update --init --recursive
git submodule foreach 'git fetch && git checkout release/0.0.x || true'
git submodule foreach 'git pull origin release/0.0.x || true'

if [ $? -eq 0 ]; then
    echo "Successfully updated all submodules."
else
    echo "Failed to update submodules. Please check your git configuration and SSH keys."
    exit 1
fi
