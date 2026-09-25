# 安装方式与人工步骤

默认选择让桌面应用沿用供应商安装和首次启动流程。`--managed-desktop` 保留自动放置应用和配置 Kiro shell 的能力，供明确需要托管的人使用；它不代表 GUI 登录或系统授权也能无人值守。

| 软件 | 默认方式 | `--managed-desktop` | 来源、更新与注意事项 |
| --- | --- | --- | --- |
| Google Chrome | 官方 Universal DMG | 官方 cask | 默认由 Chrome 自己更新；DMG 固定入口随官方版本滚动。保留已有浏览器和 profile。 |
| ChatGPT / Codex 桌面端 | 官方 DMG | 校验签名、架构和版本后放置 app | 使用 OpenAI 当前桌面分发入口和更新 feed；与 Codex CLI 分别判重，识别旧 Codex.app 名称。 |
| Kiro IDE | 官方 stable/arm64 DMG | 校验官方 DMG 后放置 app | 默认由用户完成官方首次启动；不在默认模式拆分处理 IDE 与终端集成。 |
| Claude Desktop | 默认关闭；`--with-claude` 准备官方 DMG | 仍需 `--with-claude`，校验 DMG 后放置 Claude.app | 启用后优先官方 latest DMG 入口，下载失败回退到官方版本 feed；--update 刷新下载。同一桌面应用包含 Claude Code 桌面功能，不是另装一个 CLI。 |
| Docker Desktop | 官方 arm64 DMG | 官方 cask | 涉及首次启动、系统组件和引擎初始化，默认留给官方 GUI 完成；`--docker-smoke` 单独检查引擎。 |
| iTerm2 | 官方 cask | 同默认 | 官方分发为 ZIP，cask 负责放置应用；无需人为转换成 DMG。已有配置保留。 |
| VS Code | 官方 cask | 同默认 | 官方分发为架构对应的应用包；cask 同时提供 code 命令，后续安装扩展需要它。 |
| Codex CLI | 官方 shell 安装器 | 同默认 | 最新版本从官方元数据解析；已有其他渠道的健康安装保留。 |
| Claude Code CLI | 默认关闭；`--with-claude` 使用官方 Bash 安装器 | 同默认，仍需显式启用 | 使用官方原生安装流程，不经 npm 或 Homebrew 绕一层。 |
| Kiro CLI | 官方 Bash 安装器及其原生启动流程 | 官方 manifest 的 DMG + 显式 Zsh 集成 | 默认保留官方交互、替换提示和 onboarding；托管模式才单独校验放置 app、建立 CLI 链接、调用原生 Zsh dotfiles 集成。 |
| 搜狗输入法 | 仅 `--with-sogou` 下载官方 ZIP | 同默认 | 安装输入法与启用输入源始终由用户完成。 |

## 两种模式的结果含义

默认模式安装开发工具、iTerm2/VS Code 和所选 AI CLI，并准备需要人工处理的桌面 DMG。下载记录保存文件名、来源、版本信息及 SHA-256；复用前重新检查文件摘要，损坏文件会重新下载。安装器不会自动打开这些 DMG 或替换对应的 Applications 副本。

日志的 `prepared` 表示安装包完整。`result.json` 的 `desktop_mode` 记录策略，`with_claude` 记录是否启用 Claude，`manual_steps` 列出待人工安装或 onboarding 的项目；`desktop-installers.json` 记录本轮准备的包。默认运行成功表示所选自动步骤和下载准备成功，不等于所有桌面应用都已安装。清单中未安装的应用在 inventory 中为 null，并列入 pending_applications。

Claude Desktop 与 Claude Code CLI 由 `--with-claude` 一起启用。未选择时不下载、配置、检查或更新它们，也不删除已有安装。重跑、`--verify`、`--check-updates`、`--configure-only` 或 `--update` 需要继续带上该参数；托管桌面模式不隐含启用。

`./setup.sh --verify` 始终检查所选软件的真实安装状态，不用下载记录冒充 app；默认模式不强制我们自己的 Kiro Zsh hook 布局。选择 `--managed-desktop --verify` 才额外验证托管 hook 契约。

## 更新与管理归属

- 普通运行保留健康应用与 CLI，复用完整下载包。
- `--update` 更新受管开发工具和官方 CLI，并从官方 latest/stable 源刷新桌面 DMG；已安装桌面应用仍由用户运行安装包或使用应用内更新器。
- `--managed-desktop --update` 才自动更新脚本记录的 AI app；Chrome、Docker、iTerm2、VS Code 沿用其原来的受管 cask。健康的手动/其他渠道副本保留原更新器。
- 默认 Kiro CLI 的官方应用负责集成和更新。已有安装被保留；损坏安装交回官方安装器的原生提示，不静默删除或替换。
- 私人配置、认证和登录不纳入接管；脚本安装记录只判断归属，不能替代健康检查。

## 来源依据

执行地址以 [sources.tsv](../config/sources.tsv) 为准。桌面 DMG 先下载到用户的私有临时目录并验证镜像完整性，再保存到 Downloads；系统配置目录不用于暂存下载。托管模式在复制 app 前另外检查签名、bundle ID 和 arm64，替换失败保留恢复路径。

官方说明：[Chrome](https://www.google.com/chrome/)、[ChatGPT 桌面端](https://learn.chatgpt.com/docs/app)、[Kiro 安装](https://kiro.dev/docs/getting-started/installation/)、[Claude 下载](https://claude.com/download)、[Docker Mac 安装](https://docs.docker.com/desktop/setup/install/mac-install/)、[iTerm2](https://iterm2.com/downloads.html)、[VS Code Mac](https://code.visualstudio.com/docs/setup/mac)、[Claude Code CLI](https://code.claude.com/docs/en/setup)、[Codex CLI](https://learn.chatgpt.com/docs/codex/cli)。
