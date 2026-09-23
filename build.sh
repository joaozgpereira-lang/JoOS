#!/usr/bin/env bash
# JoOS — build the ISO locally. Mirrors what CI does.
# Requires: archiso, running as root (or with privileges) on Arch/containers.
set -euo pipefail

cd "$(dirname "$0")"

echo "==> regenerando wallpapers (pure Python)"
python3 tools/gen-wallpapers.py

echo "==> mkarchiso"
if [[ -d work ]]; then
  rm -rf work
fi
mkdir -p out
mkarchiso -v -w work -o out configs/releng

echo "==> resultado"
ls -lh out/*.iso