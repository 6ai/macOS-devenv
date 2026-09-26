# macOS Devenv

面向 **Apple Silicon / macOS Tahoe 26+** 的开发环境安装器。仓库：[6ai/macOS-devenv](https://github.com/6ai/macOS-devenv)。

## 开始使用

```bash
gh repo clone 6ai/macOS-devenv
cd macOS-devenv
./setup.sh --plan
./setup.sh
```

没有 GitHub CLI 时，从仓库的 **Code → Download ZIP** 下载、解压，在目录中运行 `bash setup.sh`。以普通管理员用户运行，不要加 `sudo`；如果系统提示安装 Apple Command Line Tools，完成后重跑。

## 默认安装方式

从 **0.1.40** 起，桌面应用按各自安装流程处理；CLI 优先使用官方脚本。

| 软件 | 默认方式 | 需要你完成的操作 |
| --- | --- | --- |
| Chrome、ChatGPT、Kiro IDE | 下载官方 DMG 到 `~/Downloads/macos-setup` | 打开 DMG、安装、首次登录或授权 |
| Docker Desktop | 下载官方 Apple Silicon DMG 到同一目录 | 安装、首次启动及 Docker 引擎初始化 |
| iTerm2、VS Code | Homebrew 官方 cask 自动安装 | 选择终端配置；扩展由脚本安装 |
| Codex CLI | 官方安装脚本 | 首次登录 |
| Claude Desktop、Claude Code CLI | 默认关闭；添加 `--with-claude` 才启用 | 桌面端下载 DMG 后手动安装，CLI 使用官方脚本 |
| Kiro CLI | 官方安装脚本，保留官方启动和集成流程 | 在 Kiro 中完成 onboarding / 终端授权 |
| Git、Go、Node、Python、uv、ripgrep（`rg`）、duf 等开发工具 | Homebrew formula 自动安装 | 通常无需额外操作 |

已有健康软件默认保留。桌面阶段显示为 `app:*`；启用后的 Claude 桌面端优先使用官网最新 DMG 入口。DMG 下载完成会标为 `prepared`，这表示安装包已准备好，**不表示桌面应用已安装**。运行末尾的 `[MANUAL]` 会逐项给出本轮安装包的完整路径、可复制的 `open` 命令、拖入“应用程序”与弹出镜像的步骤，以及登录、权限和首次启动事项；同一份说明保存在本次日志目录的 `manual-steps.txt`。全部完成后，执行末尾给出的严格验证命令。

需要自动放置桌面应用、配置 Kiro Zsh 集成时，显式选择托管模式：

```bash
./setup.sh --managed-desktop
```

托管模式保留已有外部安装，不接管私人配置。它也不能代替登录、系统授权或 Docker 首次启动。各软件的选择理由、来源和更新边界见 **[安装方式汇总](docs/installation.md)**。

## 重跑与更新

```bash
./setup.sh                            # 失败后重跑；复用完整 DMG，跳过健康工具
./setup.sh --update                   # 更新受管工具，并刷新桌面 DMG
./setup.sh --managed-desktop --update # 更新脚本管理的桌面应用和工具
./setup.sh --check-updates            # 只生成版本与配置差异报告
./setup.sh --configure-only           # 只应用公开配置模板
./setup.sh --verify                   # 严格检查实际安装；缺少桌面应用会失败
./setup.sh --with-claude              # 可选启用 Claude Desktop 和 Claude Code CLI
./setup.sh --with-sogou               # 可选准备搜狗安装包，手动安装和启用
./setup.sh --docker-smoke             # Docker 启动后检查容器运行
```

**Claude 默认不下载、不安装、不配置，也不纳入验证或更新检查。** 需要它们时使用 `./setup.sh --with-claude`；之后重跑、验证或更新时继续带上该参数，例如 `./setup.sh --with-claude --verify`。`--managed-desktop` 本身不会启用 Claude。已有 Claude 安装和私人配置保持不动。

Zsh 使用系统自带版本，不更改登录 shell。健康的 Oh My Zsh 普通重跑不会下载或更新；已有主题、插件和个人配置保留，受管配置变化前先备份。只有 `--update` 才对干净的官方 Oh My Zsh checkout 做快进更新；自定义或不完整目录不会被覆盖。

Vim 默认启用 UTF-8、语法高亮、行号、标尺、四空格缩进和空白字符显示，并提供常见大小写命令纠错。公共配置安装到 `~/.config/macos-setup/vimrc`，用户的 `~/.vimrc` 只增加一行加载语句；原有内容保留并在首次修改前备份，个人覆盖可放在加载行之后。

Go 安装后会解析并导出有效的 `GOPATH`，同时按 Go 官方 macOS 安装说明将显式/持久化的 `GOBIN` 或每个 `GOPATH/bin` 追加到登录与交互 Zsh 的 PATH；已有覆盖优先，不设置 `GOROOT`。Git 会补齐缺失的通用 alias、delta/VS Code、pull/push、rerere 和 global ignore 默认值。已有 Git 身份、凭据、签名、URL rewrite、include、自定义 alias 和自定义 ignore 文件不会被复制或覆盖；首次写入前会把现有 `~/.gitconfig` 备份为 0600 文件。安装结束会提示检查并自行设置 `user.name` / `user.email`。

Kiro CLI 默认沿用官方应用/CLI 的更新器。桌面 DMG 从官方滚动入口或最新稳定版元数据获取；普通重跑复用校验通过的下载，`--update` 获取新包。未知或损坏的外部安装不会被静默覆盖。0.1.41 增加了强制中断恢复测试：CLI 半成品、桌面应用替换及会话锁会在重跑时重新核查；安装子进程仍运行时会拒绝并发重跑。网络、磁盘或权限问题仍需先排除，不能保证任意断电或外部改动都能自动恢复。

更新本仓库：

```bash
git pull --ff-only
git fetch --tags
cat VERSION
git describe --tags --exact-match
```

每个正式版本都有 `v<VERSION>` tag。软件包随上游发布更新，仓库版本不是第三方软件的版本锁。

## 配置与排障

安装器保留私人 AI 配置、认证及已有应用来源；管理的 shell/终端模板发生变化时先备份。每次运行的日志路径会打印在结尾，默认位于 `~/.local/state/macos-setup`。

- [安装方式汇总](docs/installation.md)：每个应用用 DMG、cask 还是官方脚本。
- [Shell、编辑器与终端](docs/shell-editor.md)：别名、iTerm2、VS Code、AutoJump 等配置。
- [故障排查](docs/troubleshooting.md)：网络、Git 权限、安装恢复。
- [维护手册](docs/maintenance.md) / [官方来源](docs/sources.md)：版本检查与升级。
- [自动化接口](docs/automation.md)：日志、结果字段和失败处理。
- [独立 qBittorrent 服务](apps/qbittorrent/README.md)：按需部署，不随安装器启动。

## 验证与维护

在独立 checkout 中运行 `make check`，构建包为 `dist/macos-setup.tar.gz`。发布只包含 [文件清单](config/repository-files.txt) 中审阅过的内容。

自动化测试覆盖安装、重跑、下载复用、修复和 CLI 检查；GUI 登录、系统权限、交互终端及实体 Mac 的 Docker 虚拟化仍需真机验收。不要在贡献者的日常 Mac 上运行全量安装作为测试。
