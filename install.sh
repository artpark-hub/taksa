#!/bin/bash

# Script to initialize and update all submodules
echo "Initializing and updating submodules for Taksa..."

git submodule update --init --recursive

if [ $? -eq 0 ]; then
    echo "Successfully updated all submodules."
else
    echo "Failed to update submodules. Please check your git configuration and SSH keys."
    exit 1
fi
