# Git worktree 隔离开发模式

## 场景

当主项目目录里已经有大量未提交改动,但又需要创建一个干净环境继续开发、验证或打包时,使用 `git worktree` 比复制整个项目更稳。

## 做法

```bash
git worktree add "/Users/zero/Desktop/项目库/资产聚集app-worktree" -b worktree/main
```

## 收益

- 主目录的未提交改动不会被覆盖。
- 新目录是一个独立工作区,可以单独切分支、跑测试、打包。
- 共享同一个 `.git` 对象库,比完整复制项目更省空间。

## 注意

- 同一个分支不能同时被两个 worktree 检出,所以需要创建单独分支,例如 `worktree/main`。
- 如果要把 worktree 的成果合回主分支,需要走 commit/merge/cherry-pick,不要直接复制覆盖。

