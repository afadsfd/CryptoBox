#!/usr/bin/env bash
# 发布用 arm64-v8a 分包（体积最小真机架构），产物：
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build apk --release --split-per-abi
echo "Primary artifact: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
