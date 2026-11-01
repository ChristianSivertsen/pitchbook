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

echo "==> Checking generated database code"
generated=packages/sva_data/lib/src/database/sva_database.g.dart
before="$(mktemp)"
cp "${generated}" "${before}"
(cd packages/sva_data && dart run build_runner build --delete-conflicting-outputs >/dev/null)
if ! cmp -s "${before}" "${generated}"; then
  echo "The generated database code was out of date and has been rebuilt."
  echo "Commit ${generated}."
  exit 1
fi

for package in packages/sva_core packages/sva_data; do
  echo "==> Testing ${package}"
  (cd "${package}" && dart test)
done

for package in packages/sva_ui app; do
  echo "==> Testing ${package}"
  (cd "${package}" && flutter test)
done

echo "==> All checks passed"
