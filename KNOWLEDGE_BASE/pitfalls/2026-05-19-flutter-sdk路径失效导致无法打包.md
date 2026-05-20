# Flutter SDK 路径失效导致无法打包

## 现象

项目的 `frontend/android/local.properties` 指向旧 Flutter 路径,但本机该路径不存在,执行 `flutter build apk --release` 前无法找到 Flutter SDK。

## 原因

`local.properties` 是本机环境文件,通常不会进入 Git 管理。只要 Flutter SDK 被移动、删除或换机器,这个路径就会失效。

## 解决方案

1. 查询官方 Flutter release 元数据。
2. 下载匹配架构的 Flutter SDK。
3. 校验 `sha256`。
4. 用临时 SDK 构建 APK。
5. 使用 `aapt` 验证 APK 内部版本号。

## 预防措施

- 固定安装一个长期可用的 Flutter SDK。
- 在项目内提供打包脚本,集中设置 `JAVA_HOME`、`ANDROID_HOME`、`PUB_CACHE`、`GRADLE_USER_HOME`。
- 发布验收必须检查 APK 内部 `versionName/versionCode`。

## 是否可复用

可复用。任何 Flutter 项目只要依赖本机 SDK,都可能遇到同类问题。
