#!/usr/bin/env bash
# 更新 assets/branding/app_icon.png 后执行：会根据 pubspec 生成 mipmap + Adaptive Icon（含背景色，避免透明边被系统垫成白边）
set -euo pipefail
cd "$(dirname "$0")/.."
dart run flutter_launcher_icons
