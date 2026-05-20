# 临时 Flutter SDK 隔离打包流程

## 场景

本机没有固定 Flutter SDK,或者旧 SDK 路径失效,但需要快速打出可信 release APK。

## 模式

将所有构建依赖放到临时目录,显式指定环境变量,避免依赖用户 Home 或旧路径。

## 关键步骤

1. 下载官方 Flutter SDK。
2. 校验 `sha256`。
3. 解压到 `/private/tmp/flutter_sdk_xxx`。
4. 设置临时缓存:
   - `HOME=/private/tmp/flutter_home`
   - `PUB_CACHE=/private/tmp/pub-cache`
   - `GRADLE_USER_HOME=/private/tmp/gradle-home`
5. 显式指定:
   - `JAVA_HOME=/opt/homebrew/Cellar/openjdk@17/17.0.18/libexec/openjdk.jdk/Contents/Home`
   - `ANDROID_HOME=/opt/homebrew/share/android-commandlinetools`
6. 构建 release APK。
7. 用 `aapt dump badging` 验证版本。

## 收益

- 构建过程可复现。
- 不污染用户 Home。
- 能绕开旧 `local.properties` 路径失效问题。
- 适合一次性发布或救急打包。

## 代价

- 首次下载体积大,Flutter SDK 约 2.1GB,Gradle 缓存约 2.2GB。
- `/private/tmp` 后续可能被系统清理,不适合作为长期 SDK 路径。

## 是否可复用

可复用。建议后续抽成 `scripts/build_android_release.sh`。
