#!/usr/bin/env bash
# Runs the checks CI runs: formatting, static analysis and all tests.
# Uses the committed pubspec.lock exactly, so CI tests reviewed versions.
# Usage: tool/check.sh   (from anywhere inside the repository)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "==> Resolving packages"
flutter pub get --enforce-lockfile

echo "==> Checking formatting"
dart format --output=none --set-exit-if-changed .

echo "==> Analyzing"
flutter analyze

echo "==> Checking design tokens"
tool/check_tokens.sh

for package in packages/sva_core packages/sva_data; do
  echo "==> Testing ${package}"
  (cd "${package}" && dart test)
done

for package in packages/sva_ui app; do
  echo "==> Testing ${package}"
  (cd "${package}" && flutter test)
done

echo "==> All checks passed"
