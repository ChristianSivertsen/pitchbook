#!/usr/bin/env bash
# Fails if code outside packages/sva_ui uses raw colours or font sizes.
# Screens must use the Sva theme tokens (docs/DESIGN.md, ticket M0-4).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

dirs=(app/lib packages/sva_core/lib packages/sva_data/lib)
for dir in "${dirs[@]}"; do
  if [[ ! -d "${dir}" ]]; then
    echo "check_tokens: ${dir} is missing; update the list in this script." >&2
    exit 2
  fi
done

# Color(...), Color.from...(...), Colors.<name> and fontSize, in any spacing.
pattern='\bColor(\.from[A-Za-z]*)?[[:space:]]*\(|\bColors\.[a-z]|fontSize[[:space:]]*:'

set +e
matches=$(grep -rnE "${pattern}" --include='*.dart' "${dirs[@]}")
status=$?
set -e

case ${status} in
  0)
    # Ignore lines that are only comments.
    code_matches=$(printf '%s\n' "${matches}" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
    if [[ -n "${code_matches}" ]]; then
      echo "Raw colours or font sizes found outside sva_ui. Use theme tokens instead:"
      echo "${code_matches}"
      exit 1
    fi
    ;;
  1) ;;
  *)
    echo "check_tokens: grep failed with status ${status}." >&2
    exit 2
    ;;
esac
echo "No raw colours or font sizes outside sva_ui."
