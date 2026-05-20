# Android 发布前远程同步与 APK 验收流程

## 场景

准备把 Android App 新版本推送到 GitHub,并通过 GitHub Pages 或仓库文件提供 APK 下载。

## 流程

1. `git fetch origin main --tags`
2. 确认远程 `main` 是本地祖先,避免覆盖远程更新。
3. 用 `aapt dump badging` 验证 APK 内部版本号。
4. 更新下载页链接和显示版本。
5. 扫描敏感信息。
6. 跑 `dart analyze` 和 `flutter test`。
7. commit。
8. 创建版本 tag。
9. `git push origin main --tags`

## 收益

- 远程历史安全。
- 下载页和 APK 版本一致。
- 包内版本可验证。
- 发布节点可回溯。

## 代价

- 多 5-10 分钟验收时间。
- APK 进入 Git 会增加仓库体积;超过 50MB 后建议改走 GitHub Release。

## 是否可复用

可复用。适合所有 Flutter/Android 本地发布流程。
