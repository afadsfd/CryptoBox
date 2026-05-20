# CryptoBox v2.0.0 打包发布

## 任务背景

- **日期**: 2026-05-19
- **目标**: 重新打包 Android release APK,版本标记为 `2.0.0`
- **交付物**: `/Users/zero/Desktop/CryptoBox-v2.0.0.apk`

## 完成结果

- `frontend/pubspec.yaml` 版本从 `1.4.4+18` 更新为 `2.0.0+20`
- Android 构建产物已重新生成,不是旧 APK 改名
- 使用 `aapt` 验证 APK 内部版本:
  - `versionName='2.0.0'`
  - `versionCode='20'`
- APK 大小约 `60M`
- SHA256: `e9c3c812fcf0171f6ee85a252eb0b32fee746c738741fcca2463f307c9f0f456`

## 本次踩坑

### 坑 1: 本机 Flutter SDK 路径失效

- **现象**: `frontend/android/local.properties` 原本指向 `/Users/zero/Downloads/flutter`,但本机不存在该目录,无法直接打包。
- **原因**: Flutter SDK 是本地开发环境依赖,不跟随项目代码进入版本管理;旧路径漂移后构建链断开。
- **解决方案**: 下载官方 Flutter `3.44.0` macOS arm64 SDK 到 `/private/tmp`,校验 SHA256 后用临时 SDK 构建。
- **预防措施**: 后续应安装固定 Flutter SDK,并把项目打包命令封装成脚本,统一指定 `JAVA_HOME`、`ANDROID_HOME`、`PUB_CACHE`。
- **是否可复用**: 可复用,所有 Flutter 项目遇到本机 SDK 路径失效时都适用。

### 坑 2: Dart 扩展方法不会通过普通 import 传递

- **现象**: release 构建报错 `The getter 'label' isn't defined for the type 'BalanceSource'`。
- **原因**: `BalanceSource.label` 定义在 `balance.dart` 的 extension 中,页面只 import 了 `exchange_info.dart`;Dart 不会把另一个文件 import 进来的 extension 自动传递给当前文件。
- **解决方案**: 在 `add_api_page.dart` 和 `exchanges_page.dart` 显式 import `balance.dart`。
- **预防措施**: 使用 extension getter 的文件必须直接 import extension 所在文件。
- **是否可复用**: 可复用,Dart/Flutter 项目常见。

### 坑 3: Flutter wrapper 的 analyze 在当前路径下崩溃

- **现象**: `flutter analyze` 因 analysis server LSP JSON 解析异常崩溃。
- **原因**: 这是工具层崩溃,不是业务代码错误;当前项目路径包含中文字符,触发 Flutter 3.44.0 wrapper/analysis server 的异常路径。
- **解决方案**: 改用同一 SDK 下的 `dart analyze`,成功完成静态检查。
- **预防措施**: Flutter 工具链任务如遇 wrapper 崩溃,先用底层 `dart analyze` 或迁移到纯 ASCII 临时路径复核。
- **是否可复用**: 可复用,尤其适用于中文路径下的 Flutter 项目。

## 本次优化

### 优化 1: 打包环境临时隔离

- **优化前**: 构建命令默认写入用户 Home,受沙箱和环境漂移影响。
- **优化后**: 将 `HOME`、`PUB_CACHE`、`GRADLE_USER_HOME` 指向 `/private/tmp` 临时目录,并显式指定 `JAVA_HOME`、`ANDROID_HOME`。
- **收益**: 构建过程可复现,不依赖隐藏的用户缓存;依赖下载、Gradle 缓存、Flutter telemetry 都有明确位置。
- **代价**: 首次构建需要下载约 2GB Flutter SDK 和约 2GB Gradle 依赖,耗时约 30 分钟。
- **是否可复用**: 可复用,适合所有本机临时打包任务。

### 优化 2: APK 版本验收用包内信息而非文件名

- **优化前**: 只看 APK 文件名容易把旧包误认为新版本。
- **优化后**: 使用 `aapt dump badging` 读取 APK 内部 `versionName/versionCode`。
- **收益**: 能确认版本号真实写入 Android Manifest,验收更可靠。
- **代价**: 需要本机 Android build-tools。
- **是否可复用**: 可复用,所有 Android APK 发布都应该这样验收。

## 学到的可复用知识

### 知识点 1: Flutter Android 版本号来源

- **场景**: Flutter 项目打 Android APK。
- **要点**: `pubspec.yaml` 里的 `version: 2.0.0+20` 会映射到 Android 的 `versionName=2.0.0` 和 `versionCode=20`。
- **示例**:

```yaml
version: 2.0.0+20
```

### 知识点 2: APK 内部版本校验

- **场景**: 发布前确认 APK 是否真的是目标版本。
- **要点**: 用 Android SDK 自带 `aapt` 读取包信息,不要只看文件名。
- **示例**:

```bash
/opt/homebrew/share/android-commandlinetools/build-tools/35.0.0/aapt dump badging /Users/zero/Desktop/CryptoBox-v2.0.0.apk
```
