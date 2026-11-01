#!/usr/bin/env bash
# Fails if code outside packages/sva_ui uses raw colours or font sizes.
# Screens must use the Sva theme tokens (docs/DESIGN.md, ticket M0-4).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

pattern='Color\(0x|Color\.from(ARGB|RGBO)|Colors\.[a-z]|fontSize:'
if matches=$(grep -rnE "${pattern}" --include='*.dart' app/lib packages/sva_core/lib packages/sva_data/lib); then
  echo "Raw colours or font sizes found outside sva_ui. Use theme tokens instead:"
  echo "${matches}"
  exit 1
fi
echo "No raw colours or font sizes outside sva_ui."
