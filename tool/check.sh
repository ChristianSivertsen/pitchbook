#!/usr/bin/env bash
# Runs the same checks as CI: formatting, static analysis and all tests.
# Usage: tool/check.sh   (from anywhere inside the repository)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "==> Resolving packages"
flutter pub get >/dev/null

echo "==> Checking formatting"
dart format --output=none --set-exit-if-changed .

echo "==> Analyzing"
flutter analyze

for package in packages/sva_core packages/sva_data; do
  echo "==> Testing ${package}"
  (cd "${package}" && dart test)
done

for package in packages/sva_ui app; do
  echo "==> Testing ${package}"
  (cd "${package}" && flutter test)
done

echo "==> All checks passed"
