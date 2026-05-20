# CryptoBox v2.0.0 推送 GitHub

## 任务背景

- **日期**: 2026-05-20
- **目标**: 将最新 `2.0.0` 版本推送到 GitHub
- **远程仓库**: `git@github.com:afadsfd/CryptoBox.git`

## 完成结果

- 创建提交: `c7e89e3 发布 CryptoBox v2.0.0`
- 推送分支: `main`
- 创建并推送 tag: `v2.0.0`
- GitHub Pages 下载包: `docs/CryptoBox-v2.0.0.apk`
- 下载页按钮已从 `v1.4.4` 改为 `v2.0.0`

## 本次踩坑

### 坑 1: 大量文件只有权限位变化

- **现象**: `git status` 显示 200 多个文件变更,但 `git diff --stat` 里多数是 0 行变化。
- **原因**: 本地文件权限从 `100644` 变成 `100755`,内容没有变化。
- **解决方案**: 设置本仓库 `core.filemode=false`,避免把 chmod 噪音提交上去。
- **预防措施**: 发布前先看 `git diff --summary`;如果大量 `mode change`,先处理权限噪音再 stage。
- **是否可复用**: 可复用,Mac 本地项目很容易出现。

### 坑 2: APK 超过 GitHub 推荐单文件大小

- **现象**: `git push` 成功,但 GitHub 提示 `docs/CryptoBox-v2.0.0.apk` 为 `60.05 MB`,超过推荐的 `50 MB`。
- **原因**: Universal Android APK 包含多架构内容,体积比 split APK 更大。
- **解决方案**: 本次继续推送,因为低于 GitHub 硬限制 `100 MB`,且用户需要 GitHub 下载最新版。
- **预防措施**: 后续如果 APK 继续变大,改用 GitHub Release 附件或 Git LFS,不要长期把大包塞进 Git 历史。
- **是否可复用**: 可复用,所有移动端发布包都要注意仓库体积。

## 本次优化

### 优化 1: 推送前做远程同步核对

- **优化前**: 直接 `git push` 可能因为远程已有新提交导致失败或覆盖风险。
- **优化后**: 先 `git fetch origin main --tags`,确认远程 `main` 是本地祖先后再推送。
- **收益**: 明确知道本地是快进推送,不会覆盖远程历史。
- **代价**: 多一次网络核查。
- **是否可复用**: 可复用,所有发布推送前都应该做。

### 优化 2: 发布包进入 docs 并同步下载页

- **优化前**: 桌面有新版 APK,但 GitHub Pages 下载按钮仍指向旧版。
- **优化后**: 将 `CryptoBox-v2.0.0.apk` 放入 `docs/`,并把首页下载链接改为 `v2.0.0`。
- **收益**: GitHub 页面下载到的就是最新版本,不会出现“代码已更新但下载旧包”的错位。
- **代价**: 仓库历史增加约 60MB。
- **是否可复用**: 可复用,但超过 50MB 后应考虑 GitHub Release。

## 学到的可复用知识

### 知识点 1: GitHub 大文件阈值

- **场景**: 向 GitHub 推送 APK、模型、视频等大文件。
- **要点**: 超过 `50 MB` 会警告,超过 `100 MB` 通常会被拒绝。
- **示例**:

```bash
git push origin main --tags
```

### 知识点 2: 发布 tag 与 main 的关系

- **场景**: 明确版本发布。
- **要点**: tag 应指向真正的发布提交;后续文档补充可以继续在 `main` 上追加,不影响版本回溯。
- **示例**:

```bash
git tag -a v2.0.0 -m "CryptoBox v2.0.0"
git push origin main --tags
```
