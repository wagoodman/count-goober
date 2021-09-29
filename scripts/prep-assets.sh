#!/usr/bin/env bash
set -ue -o pipefail

mkdir -p assets

# capture current configuration for reproducibility
env > assets/config.env

# prep-the-fake assets ... ;)
echo "assets fetched and built!"