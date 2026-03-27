#!/bin/bash
set -euo pipefail

# Fill 50% of the root partition with random data
ROOT_SIZE=$(df --output=size -B1 / | tail -1 | tr -d ' ')
FILL_SIZE=$((ROOT_SIZE / 2))

dd if=/dev/urandom of=/var/filldata bs=1M count=$((FILL_SIZE / 1048576)) status=progress
