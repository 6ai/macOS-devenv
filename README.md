# macOS Devenv

面向 **Apple Silicon Mac / macOS Tahoe 26+** 的开发环境安装脚本。完整安装需要普通管理员用户和网络。

项目仓库：[`6ai/macOS-devenv`](https://github.com/6ai/macOS-devenv)。

- **普通使用者**：从“快速开始”阅读。
- **自动化 / AI agent**：阅读 [`docs/automation.md`](docs/automation.md)、[`AGENTS.md`](AGENTS.md) 和 [`result.schema.json`](docs/result.schema.json)。
- **维护者**：阅读 [`docs/sources.md`](docs/sources.md) 中的来源、升级入口与维护流程。


## 项目范围

| 部分 | 默认行为 |
| --- | --- |
| `setup.sh` | 安装开发工具、应用公开配置并验收；下列 AI 应用和 CLI 只检查本地安装 |
| `--with-sogou` | 可选下载输入法安装包；人工完成安装及输入源启用 |
| `apps/qbittorrent` | 独立启停，不随 `setup.sh` 自动部署 |
| 日志、账户、下载数据 | 保存在使用者本机，不属于源码或分发包 |

## 独立应用

[qBittorrent Docker 下载服务](apps/qbittorrent/README.md)：可单独复制 `apps/qbittorrent` 使用，提供局域网网页、持久下载目录、启停、主动更新和真实容器测试。默认网页端口 1024；首次可修改。不会随 `setup.sh` 自动部署。

## 1. 快速开始

### 先用官方方式安装 AI 工具

从 0.1.38 起，ChatGPT、Codex CLI、Claude Code、Kiro IDE 和 Kiro CLI 由你通过官方安装方式准备。`setup.sh` 只检查这些工具是否已安装且可用；缺失或损坏时显示官方入口并停止，安装完成后重跑。`--update` 同样只检查，包括以前由 Homebrew/npm 安装的副本。

按需执行缺少的 CLI 对应命令：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh  # Codex CLI
curl -fsSL https://claude.ai/install.sh | bash       # Claude Code
curl -fsSL https://cli.kiro.dev/install | bash       # Kiro CLI
```

来源：[Codex CLI](https://learn.chatgpt.com/docs/codex/cli)、[Claude Code](https://code.claude.com/docs/en/setup)、[Kiro CLI](https://kiro.dev/cli/)。官方安装器的首次启动、迁移和登录提示由你处理。桌面应用从 [ChatGPT 官方下载页](https://learn.chatgpt.com/docs/app) 和 [Kiro 官方下载页](https://kiro.dev/downloads/) 安装；这两个桌面入口是应用下载，不是 CLI 安装命令。保留原有个人配置，项目的配置模板和 Kiro Zsh 集成仍按下文规则处理。

### 已有 GitHub CLI 的 Mac

```bash
gh repo clone 6ai/macOS-devenv
cd macOS-devenv
./setup.sh --plan
./setup.sh
```

### 全新 Mac，还没有 GitHub CLI

1. 打开 [公开仓库](https://github.com/6ai/macOS-devenv)，Code → Download ZIP，解压后在终端进入项目目录。
2. 先运行 `bash setup.sh --plan` 阅读清单，再运行 `bash setup.sh`。
3. 若脚本打开 Apple Command Line Tools 安装提示，完成系统安装后重新运行同一个命令。

不要用 `sudo ./setup.sh`。Homebrew 需要管理员权限时会自行请求密码；脚本不会收集或保存密码。不要把访问令牌写进 clone URL、命令行、模板或提交。

## 2. 安装、恢复与主动升级

```bash
./setup.sh                         # 安装/修复受管工具；AI 工具只检查本地安装
./setup.sh                         # 失败后直接重跑；不用清空环境或删除进度标记
./setup.sh --update                # 主动更新受管工具；AI 工具仍由官方方式维护
./setup.sh --with-sogou            # 可选扩展：最后准备搜狗包，提示手动安装
./setup.sh --verify                # 独立验收已安装结果
./setup.sh --check-updates         # 只查版本/模板差异，生成维护报告，不升级
./setup.sh --diagnose              # 仅检查环境和官方外网入口，不安装软件
./setup.sh --help
```

### 每次如何决定是否执行

| 实际状态 | 默认安装 | `--update` |
| --- | --- | --- |
| Homebrew 不存在 | 官方安装器安装 | 同左 |
| Homebrew 已存在 | 复用 | 更新元数据 |
| formula 已登记且命令可运行 | 跳过 | 请求升级 |
| formula 已登记但命令不可运行 | `brew reinstall` 修复 | 同左 |
| formula 缺失 | 安装 | 安装 |
| 非 AI 受管 app bundle 缺失/不完整 | 重装对应 cask | 同左 |
| 健康的非 AI 受管 app | 跳过 | 请求升级 |
| 健康的非 Homebrew app | 保留，使用原应用更新器 | 同左 |
| 不完整的非 Homebrew app | 报错，要求先用原安装方式修复 | 同左 |
| 健康 ChatGPT、Kiro IDE/CLI、Claude/Codex CLI | 检查后保留，不调用安装器或管理器 | 同左 |
| 上述 AI 工具缺失/损坏/不兼容 | 显示官方安装入口并停止，人工安装后重跑 | 同左 |

恢复依靠**实际状态检查**，不是“完成标记”。日志中的成功记录用于排查；删掉一个已完成工具后重跑，脚本仍会检测并修复。Homebrew 下载默认使用 HTTP/1.1（避免部分连接上的 HTTP/2 PROTOCOL_ERROR）、20 秒连接超时、连续 60 秒低于 1 字节/秒的停滞检测、单次尝试最长 30 分钟，并限制新重试的启动时间窗口为 30 分钟；已有 Homebrew 重试次数设置保持不变。最后一次重试可能超出重试启动窗口，因此这不是整个安装的总时限。策略在 `config/download.curlrc`，Homebrew 通过本次进程的 `HOMEBREW_CURLRC` 加载；本项目的安装器脚本下载、外网诊断、搜狗下载也直接加载同一策略，并保留各自更短的连接/总时限，不写用户 `.curlrc`。调用者已设置 `HOMEBREW_CURLRC` 时保留其策略；如仍会无限等待，需要在自己的 curl 配置中加入超时。Homebrew 自身的下载缓存可以减少重新下载；我们不维护另一套包缓存或隐藏版本锁。

任何关键安装、修复或最终验证失败都会立即停止并返回非零状态。已完成的安装保留；修复网络、权限或磁盘问题后重跑。不会自动卸载所有软件回滚，也不会覆盖私人 AI 配置。

### 旧版本安装过，更新脚本后能否直接再跑？

可以按实际状态增量执行，使用 `./setup.sh`，不要为补别名加 `--update`。健康软件和已装扩展跳过；新增缺失项安装；损坏的受管项修复。上述 AI 工具例外：仅检查，缺失或损坏需先用官方方式处理。Git LFS 的四个全局 filter 已正确配置时不再初始化或重写 `.gitconfig`；自定义 filter 保留并提示审阅。

配置按文件处理：AI / VS Code 私人设置保留；项目管理的 shell/env/iTerm2 模板有变化时先备份、再替换，没有变化时连修改时间也不更新。`.zshrc` / `.zprofile` 的 source 行只添加一次，其他内容保留。只补别名也可运行 `./setup.sh --configure-only`，之后新开终端。自定义 `--config-dir` 需要同步自己的模板并保持原参数。

这不是对整台机器“绝无副作用”的承诺：每次会写独立日志，验收会产生临时文件/工具缓存；新的同名 alias 会按 README 的覆盖规则生效；手改项目管理的模板会在备份后被新模板替换。新增软件的依赖由 Homebrew 处理，未来新增其他包时仍需检查依赖变化。


### Homebrew tap 警告与安装预览

`The following taps are not trusted` 是 Homebrew 对原有第三方源的提醒，不是 Go 的错误。官方源始终受信任。本脚本显式使用 `homebrew/core/<formula>`、`homebrew/cask/<cask>` 和下文四项 `charmbracelet/tap/<formula>`，覆盖安装、升级、修复、验收和包元数据读取，避免同名第三方包参与解析。

Homebrew 6 默认 ask 模式也会输出 `Would install ...`；这行本身不代表失败或只做了演练。脚本在安装进程中设置 `HOMEBREW_NO_ASK=1` 并清除已停用的 `HOMEBREW_ASK`，省去重复预览/确认，不写 shell 配置。sudo 密码、系统权限和厂商登录仍按原流程处理。

trust 警告可能继续出现，因为 Homebrew 的安装前检查会扫描全部 tap。脚本保留原始警告和真实退出码，不解除隔离，也不卸载旧源。以 `[OK] formula:go` / `[FAILED]`、本次 `result.json` 和 `go version` 判断实际结果。若长时间停住，保留随后下载/网络错误；不要只截取前面的 trust 提示。

若你仍使用日志中的三个旧工具，并已确认信任它们的来源，可自行仅信任对应包：

```bash
brew trust --formula libsql/sqld/sqld
brew trust --formula oven-sh/bun/bun
brew trust --formula tursodatabase/tap/turso
```

这会允许 Homebrew 加载对应包的定义；不是修复 Go 所必需的步骤，也不会授权整个 tap 的其他包或命令。[官方 Tap Trust 说明](https://docs.brew.sh/Tap-Trust)

### 后续维护

运行 `./setup.sh --check-updates`，在本次日志目录生成 `updates.md`（供人阅读）与 `updates.json`（供程序读取）。覆盖当前工具清单、稳定发行候选、配置差异和仓库 revision；未知项保留为未知，不静默升级或改写私人设置。

建议采用 **检查 → 审阅 → 更新 → 验收 → 再检查**：每周查一次，需要更新时保存工作后运行 `--update`（自带最终验收），再保存一份更新后报告。脚本、软件与私人配置分别维护，详见 [维护手册](docs/maintenance.md) 和 [报告接口](docs/updates.schema.json)。

## 3. 进度与日志

默认完整安装按 53 个阶段显示进度；显式添加 `--with-sogou` 时为 54 个阶段。工具清单变化时总数自动计算：

```text
[1/53] [....................] 0% target
[OK] target (checked)
...
[4/53] [#...................] 5% formula:git
[SKIP] formula:git (skipped)
...
[FAILED] formula:go, exit 1. Correct the cause and rerun the same command.
[FAILED] Result: failed. Completed: 6/53. Logs: /.../macos-setup/20260906T120000Z-xxxxxx
```

交互终端默认使用 ANSI 颜色；UTF-8 终端同时使用少量 emoji。阶段开始显示 20 格 ASCII 进度条和**已完成阶段**的百分比，下载时第三方命令输出继续实时显示。进度表示安装阶段，不估算剩余下载时间。

| 状态 | 显示 | 颜色 |
| --- | --- | --- |
| 进行中 | ⏳ `[7/53] [##..................] 11% formula:go` | 青色 |
| 完成 | ✅ `[OK]` / `[DONE]` | 绿色 |
| 已安装，跳过 | ⏭️ `[SKIP]` | 蓝色 |
| 保留个人副本/配置 | 📌 `[KEEP]` | 蓝色 |
| 警告 | ⚠️ `[WARN]` | 黄色 |
| 失败 | ❌ `[FAILED]` | 红色 |

网络异常、受管工具损坏后准备重装会明确提示 warning；带警告完成的阶段显示 `[WARN]`，脚本产生过 warning 时，最终摘要也显示黄色 `with setup warnings`。第三方原始 warning/error 和多行说明完整透传，不按关键词丢弃；只用于判重的内部存在性检查仍保持安静。

```bash
./setup.sh                                      # 自动选择颜色与 emoji
SETUP_ICONS=ascii ./setup.sh                    # 彩色 ASCII 标签
NO_COLOR=1 SETUP_ICONS=ascii ./setup.sh          # 完全使用纯文本标签
SETUP_COLOR=always SETUP_ICONS=emoji ./setup.sh  # 显式开启装饰输出
```

`SETUP_COLOR=auto|always|never`，`SETUP_ICONS=auto|emoji|ascii`。自动模式在非 TTY、自动化测试 或 TERM=dumb 时使用纯文本；非 UTF-8 locale 自动使用 ASCII 图标。非空 NO_COLOR 或 TERM=dumb 会禁用 ANSI 颜色。不要依赖颜色或 emoji 解析结果，机器读取 result.json/events.tsv。

日志分支去掉 ANSI SGR 颜色和上述状态图标，保留 `[WARN]` 等文字、所有警告正文与错误。终端直接接收原始字节，不等待换行才显示提示；完整日志在命令退出前写完。

默认日志根目录：`~/.local/state/macos-setup`；若设置了 `XDG_STATE_HOME`，则使用其下的 `macos-setup`。可指定 `--log-dir /绝对路径`。每次执行创建独立目录，日志实时同步到终端与文件；新目录权限为 0700，新文件为 0600。

从 0.1.35 起，Homebrew 引导、包安装/更新/重装在单独子进程中使用 `umask 022`，避免日志用的 `077` 影响软件安装权限。日志与项目配置仍使用私有权限；安装器失败也不会改变日志权限或丢失真实退出码。这不更改系统中已有文件的归属，也不能据此判断已有 root 文件由哪个进程创建。

| 文件 | 内容 |
| --- | --- |
| `run.log` | 执行输出和失败信息，去掉颜色及状态 emoji，保留警告原文 |
| `result.json` | 成败、退出码、模式、脚本版本、最后阶段、起止时间、已完成数量 |
| `events.tsv` | 每个阶段的开始、结果及 installed/skipped/repaired 等动作 |
| `environment.json` | 系统版本、架构、硬件型号、内存、是否配置代理 |
| `network.tsv` | 官方外网入口的 HTTP 状态及连接错误码 |
| `inputs.sha256` | 仓库公开脚本与默认配置的摘要 |
| `downloads.tsv` | 本次成功下载的官方安装器摘要 |
| `sogou-installer.json` | 仅 `--with-sogou`：搜狗包来源、版本、SHA-256、复用/下载动作、待手动安装标志 |
| `updates.md` / `updates.json` | 仅 `--check-updates`：版本、来源类别、状态、后续动作和查询失败项；不含私人配置内容 |
| `inventory.json` | 完整验证成功时的实际软件和八项扩展版本、Oh My Zsh revision、脚本版本和 Git 提交 |

脚本不打印完整环境变量，不读取私人配置内容用于报告，不采集序列号、主机名、账号、代理 URL 或公网 IP，也不上传本机日志。第三方程序的原始输出仍可能包含本机路径等信息，分享 `run.log` 前请检查。**不要把日志、私人模板、token 或备份提交到仓库。**

安装锁避免相同日志根目录下的两次执行互相干扰。正常失败、Ctrl+C 和终止会释放锁；检测到死 PID 的锁时可以恢复。若机器掉电或进程被强杀，可能没有最终 `result.json`，此时必须视为“未完成”。无 PID、活 PID 或身份不明的锁返回 75，先检查是否仍有安装进程，再处理锁目录。

## 4. 安装清单

| 类别 | 工具 |
| --- | --- |
| AI 编程 | Claude Code CLI、Codex CLI、包含 Codex 的新版 ChatGPT 桌面应用、AWS Kiro IDE、Kiro CLI 与 Zsh hooks |
| Shell | Zsh、Oh My Zsh（基础主题 robbyrussell）、独立 PATH / 快捷键配置 |
| 语言 | Go、Node.js/npm、Python（Homebrew 稳定版）、uv |
| 开发 | Git、Git LFS、GitHub CLI、VS Code、Docker Desktop、iTerm2 |
| 浏览器 | Google Chrome（官方 DMG，通过 Homebrew Cask 安装） |
| 搜索与终端 | ripgrep、fd、bat、fzf、autojump、zoxide、tmux、tree、htop |
| 数据与脚本 | jq、yq、wget、ShellCheck、shfmt |
| Git 与媒体 | delta、tig、FFmpeg、ImageMagick |
| Charmbracelet | glow、pop、gum、crush（厂商官方 tap） |

完整清单：[`config/formulae.txt`](config/formulae.txt)、[`config/casks.tsv`](config/casks.tsv)。后者也保留 ChatGPT、Kiro IDE/CLI 的检查条目及历史 `cask:*` 阶段 ID，便于报告兼容；这些条目不会调用 Homebrew 安装或更新。Go 使用无版本后缀的 `go` formula；全新安装取当时官方稳定版本，已有版本使用 `--update` 更新。不会写死某个过期 Go 或 AI 模型版本。

Homebrew 已停止为 Intel Mac 发布新的二进制包，所以完整安装入口明确拒绝 Intel，避免意外触发大量源码编译。[官方平台支持说明](https://docs.brew.sh/Support-Tiers)

### Charmbracelet：默认安装四项

通过 [Charm 官方 Homebrew tap](https://github.com/charmbracelet/homebrew-tap) 安装当时发布的 macOS arm64 包；来源完整名称保存在 formulae.txt。

| 工具 | 用途 | 安装后的简单检查 |
| --- | --- | --- |
| [glow](https://github.com/charmbracelet/glow) | 在终端阅读 Markdown | `glow README.md` |
| [pop](https://github.com/charmbracelet/pop) | 在终端编写、发送邮件 | `pop --version` |
| [gum](https://github.com/charmbracelet/gum) | 给 Shell 脚本添加选择、输入、样式等交互 | `gum style 'Hello'` |
| [crush](https://github.com/charmbracelet/crush) | 终端 AI 编程助手 | `crush --version` |

新安装分别调用 `brew install --formula charmbracelet/tap/glow`、`charmbracelet/tap/pop`、`charmbracelet/tap/gum`、`charmbracelet/tap/crush`。[Homebrew 的完整名称安装机制](https://docs.brew.sh/Tap-Trust)只信任指定包，不授予整个 tap 信任。已有该 tap 或 Homebrew core 的健康副本直接跳过；`--update` 和损坏修复沿用已有来源，不强制迁移。不改动其他第三方 tap。

四项使用现有 Homebrew PATH，无额外全局环境变量。保留已有个人设置；Pop 的邮箱/SMTP/服务凭据、Crush 的模型提供商与登录在首次使用时自行配置，脚本不写入凭据、不发送邮件、不触发模型调用或开启自动审批。安装器的进度显示继续使用 Bash，启动不依赖 gum 已安装。

`--verify` 检查四项版本命令，并实际运行 Glow 本地 Markdown 渲染与 Gum 样式输出；这不代表邮件投递、模型账号或交互 TUI 已验收。`--check-updates` 按实际来源查询：Charm 副本读取官方 tap 的公开 version/revision 文本，已有 core 副本读取 Homebrew API；不会执行远程 Ruby 或增加信任。

### Codex 桌面应用与 CLI：分别安装、分别判重

[OpenAI 官方桌面说明](https://learn.chatgpt.com/docs/app) 提供包含 Codex 的桌面应用下载。桌面应用与 Codex CLI 分别通过官方方式安装，脚本分别检查，不再调用 Homebrew 下载桌面包。
桌面端依次检查 `/Applications/ChatGPT.app`、`~/Applications/ChatGPT.app`、`/Applications/Codex.app`、`~/Applications/Codex.app`，必须有可执行 bundle 且标识为 `com.openai.codex`。已有健康副本直接复用；旧 Codex.app 和用户目录版本保留原更新方式。旧 ChatGPT Classic 的标识不同，不算 Codex 桌面端；如果它占用了目标文件名，先手动保留或移动它，再重跑脚本。

CLI 独立检查 `codex --version`，Claude Code 同样检查 `claude --version`。可运行则保留，缺失或异常则提示官方安装命令并停止；桌面端存在不会代替 CLI 检查。普通安装和 `--update` 均不调用这些工具的安装器、Homebrew 或 npm 管理命令。打开桌面应用和 CLI 后分别完成登录，不复制认证文件。

### AWS Kiro：安装与权限

先从 [Kiro 官方下载页](https://kiro.dev/downloads/) 安装 **Kiro IDE 1.x 或更新版**。脚本检查 `/Applications/Kiro.app` 或 `~/Applications/Kiro.app`，要求 bundle ID `dev.kiro.desktop` 和主版本至少为 1，避免旧 IDE 0.x 忽略新版权限规则。健康副本保留，缺失、损坏或旧版提示先用官方方式安装/升级；`--update` 也不下载或替换 IDE。

新环境将公开模板 `config/kiro-permissions.json` 写入 `~/.kiro/settings/permissions.yaml`（JSON 是 YAML 的有效子集，新文件权限 0600）：

```yaml
rules:
  - capability: all
    effect: ask
```

按 [Kiro 官方权限规范](https://kiro.dev/docs/permissions/)，该用户级规则覆盖所有项目的工具能力，包括读写文件、Shell、联网和 MCP：操作前询问，内置禁止规则仍然有效。这会比默认设置频繁确认，适合作为先安装、后精调的基础。它是应用内审批规则，**不是操作系统沙箱**；批准的 Shell 命令仍具有当前用户的文件和网络访问能力。

已有个人权限 YAML 原样保留，脚本不解析或审计其有效策略；日志会明确提示，inventory 记录 `custom-unreviewed`。新默认模板记录 `default-ask`，只表示文件匹配公开模板，不代表已登录并验证每个工具的实际审批。空文件、目标或 Kiro 配置目录的符号链接会停止配置，避免静默沿用空策略或改写其他配置管理器的目标。已有规则需要直接编辑安装位置，重跑不会覆盖。

| 权限层 | 安装脚本的处理 |
| --- | --- |
| Kiro 工具审批 | 新环境按上述规则询问；已有策略请在应用中审阅 |
| macOS 权限 | 不开启完全磁盘访问、辅助功能或自动化授权；首次使用按实际功能需要选择 |
| AWS / 账号 | 手动登录；不导入 AWS 凭据、不创建 IAM 角色或授予管理员策略 |
| 扩展与服务 | 不迁移 Amazon Q、不自动导入 VS Code 配置、不添加 MCP、Hooks 或后台启动项 |
| 隐私与数据共享 | 首次启动在 Settings → User → Application → Telemetry and Content 检查使用统计和内容收集选项；脚本没有擅自猜测设置键或声称已关闭收集 |

首次使用仅打开需要工作的项目目录，登录后用临时文件验证读写和 Shell 操作是否出现确认，先拒绝一次确认没有执行，再批准一次检查结果。公司受管配置与已有个人规则应在应用中一起审阅。数据选项位置来自[官方数据保护说明](https://kiro.dev/docs/privacy-and-security/data-protection/)。

### Kiro CLI 接入 iTerm2 / Zsh

先用上面的官方一键命令安装独立的 **Kiro CLI.app**，脚本检查本地应用后配置 Zsh shell hooks。这部分用于终端补全与命令上下文接入；IDE 的 `kiro` 编辑器启动命令与 `kiro-cli` 独立。已有系统或用户 Applications 目录的健康 CLI app 复用，已有可运行的个人 CLI 命令保留。脚本补齐 `~/.local/bin/kiro-cli`、`kiro-cli-chat`、`kiro-cli-term`，因为官方 hooks 固定调用这个位置；丢失的链接和指向旧 Kiro app 的失效链接可修复，未知来源的损坏命令要求先人工处理。

安装配置和 Oh My Zsh 后，只运行官方命令 `kiro-cli integrations install --silent dotfiles zsh`，把 pre/post 块放到 `.zshrc` / `.zprofile` 的首尾；尊重绝对路径 `ZDOTDIR`，保留个人内容，原生安装器备份改动的 dotfiles。辅助加载文件位于 `~/Library/Application Support/kiro-cli/shell/`。重跑查询实际集成状态、命令和四个官方加载文件的完整内容；缺失或内容损坏时修复，不反复追加 hooks。不会运行 `integrations install all`，也不改 SSH、其他 shell、登录启动项或 agent 的自动执行 hooks。

**历史补全需要明确选择。** 如果 `${KIRO_HOME:-~/.kiro}/settings/cli.json` 中尚未设置 `inline.enabled`，脚本调用官方 `kiro-cli inline disable`，默认关闭 AI 行内历史补全；已有 true/false 选择保留，其他 CLI 设置保留。这也避开了实际 2.21.1 生成脚本中“尚未选择历史补全”提示的引号错误。每次安装和验收都会用真实 `kiro-cli init` 生成四段代码并用 Zsh 检查语法，出错会停止。没有通过改写厂商代码绕过错误。普通图形下拉补全与 AI 行内补全是[两个独立功能](https://kiro.dev/docs/cli/autocomplete/)。

自定义 `KIRO_HOME` 需要所选 CLI **2.3.0+**，这是[官方加入该变量的版本](https://kiro.dev/changelog/cli/2-3/)。从 0.1.35 起，旧版或无法识别的版本会在创建链接、改写设置之前提示先用原管理器更新；不会静默修改默认 `~/.kiro`。没有自定义该变量时，健康旧版仍沿用默认目录，不强制升级。

安装后在 **iTerm2** 完成一次接入：

```bash
kiro-cli launch                         # 打开终端辅助应用的官方首次启动向导
# 完成向导后关闭并新开 iTerm2 窗口
kiro-cli --version
kiro-cli integrations status dotfiles zsh
kiro-cli doctor --all                    # 只诊断，不自动修复或授权
kiro-cli chat --trust-tools=             # CLI 2.x：不预先信任工具，登录后检查 /tools
```

在新窗口输入 `git `、`docker ` 检查补全，再检查 Ctrl/Option 跳词和删除键。Kiro hooks 会接触终端命令、目录和提示符等上下文；辅助应用首次启动如要求辅助功能或输入法集成，应在官方向导中逐项确认。需要修复输入法集成时，可手动运行 `kiro-cli integrations install input-method` 并完成系统提示。脚本不代替你开启系统授权，不关闭终端安全输入，不读取完整 shell 历史用于安装日志。界面补全、输入源和按键必须在实际 Tahoe / iTerm2 上验收，自动化测试无登录和系统授权，不能证明弹出补全已可用。

若明确接受服务使用历史上下文生成建议，再手动运行 `kiro-cli inline enable`；关闭用 `kiro-cli inline disable`。CLI 2.21.1 的工具信任设置与 IDE 1.x 权限文件不同：IDE 的 `permissions.yaml` 不能被当作旧 CLI 的审批保障。已有自定义 agent/权限必须在 CLI 的 `/tools` 中检查；脚本不增加 `--trust-all-tools`、AWS 凭据或 IAM 授权。Kiro CLI 的账号与模型调用也需手动验收。

### Chrome、搜狗与官方 DMG / PKG

Homebrew Cask 可以下载厂商发布的安装包，并完成挂载 DMG、复制应用或调用 PKG 安装器等步骤。Cask 是 Homebrew 社区维护的安装说明，软件本体应来自厂商；不是把闭源应用重新编译一份。安装方式必须按每个包的实际内容决定，DMG 内不一定是可直接拖入 Applications 的 app。

**Chrome 已纳入默认安装和验收。** 当前 [Cask 定义](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/g/google-chrome.rb) 下载 Google 的 [官方 Universal DMG](https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg)，新安装放到 `/Applications/Google Chrome.app`。脚本会检查 `/Applications/Google Chrome.app` 和 `~/Applications/Google Chrome.app`：已有健康副本就复用（两处都有时优先系统目录），默认不再运行 Cask 安装。用户目录或手动安装的 Chrome 沿用自己的更新器；只有显式 `--update` 才升级 Homebrew 管理的系统目录版本。没有健康副本时，受 Homebrew 管理的损坏安装会修复；不完整的非受管副本提示使用原安装器修复。验收和版本清单使用同一个实际路径。也可以单独执行：

```bash
brew install --cask google-chrome
```

Google 也提供 [官方 PKG 部署方式](https://support.google.com/chrome/a/answer/9020580?hl=zh-Hans)。本项目使用 DMG 路径；不要同时用多个安装方式反复覆盖同一个应用。首次登录、设为默认浏览器等按个人需要在 GUI 完成。

**搜狗是可选扩展，默认不下载。** 需要时运行 `./setup.sh --with-sogou`，才会在最后一步下载到本地并提示你手动安装。 截至 2026-09-07，[搜狗官网](https://pinyin.sogou.com/mac/) 发布的是 ZIP 内的 `.app` 安装器；[Homebrew 定义](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/s/sogouinput.rb) 也明确使用 `installer manual`。

脚本通过 Homebrew 查询官方下载地址和固定 SHA-256，再直接从官网关联的 `ime.gtimg.com` 以 HTTPS 下载原包，校验 SHA-256 和 ZIP 完整性后，原子保存到：

```text
~/Downloads/macos-setup/SogouInput-<版本>-<摘要前缀>.zip
```

结束时会在终端用中文显示实际路径和安装提醒。已有完整包直接复用，损坏包重新下载；下载失败不发布半成品，也不会删除其他版本的包。失败后重跑 `./setup.sh --with-sogou`，前面已安装的健康工具仍会跳过。

1. 双击保存的 ZIP 解压，再打开其中的搜狗安装器，按官方向导完成安装。
2. 安装后在系统设置 → 键盘 → 文字输入 → 编辑中添加并切换到搜狗；具体输入源操作见 [Apple 官方说明](https://support.apple.com/zh-cn/guide/mac-help/mchl84525d76/26/mac/26)。如安装器要求注销，完成后再检查。
3. 在文本编辑器和 iTerm2 中实际输入中文，确认候选框、上屏和中英文切换；系统授权按屏幕提示自行选择。

当前 Homebrew 选择的是官网列出的 legacy 分发包，同样来自厂商，但不保证与官网主下载按钮得到的包逐字节相同。如需主按钮对应的发行包，可直接从官网下载。脚本不启动搜狗安装器、不自动授权、不修改系统输入源，也不使用未知静默安装参数。

`sogou-installer.json` 单独记录包版本、来源、SHA-256、文件名、downloaded/reused 动作以及 `manual_install_required: true`。启用此扩展后，setup 成功只表示**这个安装包已准备好**；搜狗安装和启用仍需完成上述步骤。`./setup.sh --verify` 和 `inventory.json` 覆盖默认清单中的 Chrome，不把搜狗当作已安装软件。搜狗已装后的更新使用官方应用内更新器或官网安装器。

## 5. 独立配置模板

| 文件 | 安装位置与行为 |
| --- | --- |
| `claude-settings.json` | `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`；中文、默认权限模式；已有文件保留 |
| `kiro-permissions.json` | `~/.kiro/settings/permissions.yaml`；新环境所有工具操作询问，已有个人 YAML 保留并提示审阅 |
| `codex-config.toml` | `${CODEX_HOME:-~/.codex}/config.toml`；工作区写入、按需确认；已有文件保留 |
| `env.zsh` | `~/.config/macos-setup/env.zsh`；Homebrew、AI CLI、Docker、Go 工具和 VS Code 的 PATH |
| `shell.zsh` | `~/.config/macos-setup/shell.zsh`；Oh My Zsh、历史、快捷键、常用别名 |
| `vscode-settings.json` | `~/Library/Application Support/Code/User/settings.json`；仅新环境写入，已有 JSON/JSONC 原样保留 |
| `iterm2-profile.json` | `~/Library/Application Support/iTerm2/DynamicProfiles/clean-setup.json` |

配置仅补齐缺少的模板，已有私人 AI 配置保留；不创建 `auth.json`，不预填 API key、代理或第三方模型服务。安装后分别运行 `claude`、`codex`，按官方流程登录。

```bash
cp -R config local-config
# 编辑 local-config 中的七个模板
./setup.sh --config-dir ./local-config
# 只应用配置，需要 Python 3.11+
./setup.sh --configure-only --config-dir ./local-config
```

若升级前已创建外部配置目录，需要先把新增的 `config/kiro-permissions.json` 复制到该目录，保留原来六个私人模板；缺少新模板时配置步骤会明确报错。

外部目录只控制七个模板，不改变包清单和执行下载地址。已有 AI 文件始终保留；需要变更现有 AI 配置时直接编辑其安装位置。旧环境迁移时，旧 shell 或 AI 配置里的个人代理设置也会保留，需要使用者主动审阅。

覆盖项目管理的 env/shell/iTerm2 文件前会生成 `.backup-*` 备份；修改 `.zshrc`/`.zprofile` 时也备份原文件。写入采用同目录临时文件与原子替换，相同内容跳过，source 行不重复添加。目标文件为符号链接时退出，避免破坏其他 dotfiles 管理器。

恢复配置时，在相关应用退出后，从相应 `.backup-*` 中选取需要的版本，先检查内容，再复制回同名原文件。没有自动批量删除备份或恢复私人设置的命令。

### Zsh、Oh My Zsh 与环境变量

- 登录 shell 从 `.zprofile` 加载 `env.zsh`；交互 shell 从 `.zshrc` 加载 `shell.zsh`。旧版 `.zprofile` 的项目 source 行自动迁移，不在非交互 shell 中初始化主题。设置了绝对路径 `ZDOTDIR` 时，使用其下的 `.zprofile` / `.zshrc`。
- 缺少 Oh My Zsh 时使用[官方 unattended 安装器](https://github.com/ohmyzsh/ohmyzsh#unattended-install)，保留 `.zshrc`，不运行 `chsh`。iTerm2 和新 VS Code 终端明确使用 `/bin/zsh -l`；其他终端的默认 shell 可自行调整。
- 新环境采用 **robbyrussell** 主题、`git` 插件；提示符简洁显示目录和 Git 状态，无需 Nerd Font。已有 Oh My Zsh 实例、显式主题（包括空主题）和插件列表保留。个人覆盖可写在 `.zshrc` 项目 source 行之后。
- 已有完整 Oh My Zsh 默认跳过；`--update` 只更新无本地修改的官方 Git checkout。自定义 fork 或不完整目录提示使用原方式维护，避免覆盖私人主题。项目加载的 Oh My Zsh 关闭自动更新提示，由显式 `--update` 管理；已有独立加载配置沿用原设置。
- PATH 去重，加入 `~/.local/bin`、Docker CLI、VS Code CLI。Go 工具优先使用已有 `GOBIN`，其次每个 `GOPATH/bin`，未设置时用 `~/go/bin`；不固定 `GOROOT` 或改写 Go 环境变量。
- 已有 `CODEX_HOME` / `CLAUDE_CONFIG_DIR` 被配置步骤尊重，要求绝对路径。不把 API key、代理、账号写进模板，也不导出到全局 GUI 环境。由 Finder 启动的应用不能假定自动继承终端环境变量；按应用官方设置独立配置。

**暂不安装 Powerlevel10k。** 它需要另行选择字体和运行配置向导；如果之后选用，可参照[项目字体与配置说明](https://github.com/romkatv/powerlevel10k#fonts)安装 MesloLGS NF、切换 iTerm2 字体并运行 `p10k configure`。目前 Menlo + robbyrussell 已能直接使用。

### Make、Git、Go、Docker 快捷命令

以下采用本地 Zsh 的小写名称，`m` / `g` / `dk` 分别对应 Make / Git / Docker；`d` 是与 Oh My Zsh 一致的目录栈函数；不是大写 `M` / `G` / `D`。显式写入公共模板，因此即使使用个人 Oh My Zsh 插件列表，也可以使用这些快捷命令。模板在 Oh My Zsh 后加载，本地习惯优先；你的进一步覆盖放在项目 source 行之后。

| 组 | 别名 → 命令 |
| --- | --- |
| 基础 | `g` → `git`；`dk` → `docker`；`dc` → `docker compose`；`ll` → `ls -lah`；`d` → 目录栈（函数，`dirs -v \| head -n 10`） |
| Make | `m` → `make`；`mb` → `make build`；`mi` → `make install`；`mr` → `make run` |
| Make | `mt` → `make test`；`mp` → `make preview` |
| Git | `ga` → `git add`；`gaa` → `git add --all`；`gci` / `gcia` → `git commit -a -m` / `git commit --amend -a -m`（函数，缺提交信息时报错） |
| Git | `gcmsg` → `git commit --message`；`gs` → `git status -s`；`gst` → `git status`；`gss` → `git status --short` |
| Git | `gd` → `git diff --no-index`；`gdiff` → `git diff`；`gds` → `git diff --staged`；`gdca` → `git diff --cached` |
| Git | `gb` → `git branch`；`gba` → `git branch --all`；`gco` → `git checkout`；`gcb` → `git checkout -b` |
| Git | `gsw` → `git switch`；`gswc` → `git switch --create`；`gl` → `git pull`；`gp` → `git push` |
| Git | `glo` → `git log --oneline --decorate`；`glog` → `git log --oneline --decorate --graph`；`glg` → `git log --stat`；`gstl` → `git stash list` |
| Git | `gstp` → `git stash pop`；`grs` → `git restore`；`grst` → `git restore --staged`；`git_undo_last` → `git reset --soft HEAD~1` |
| Go | `gdoc` → `go doc -all .`；`glist` → `go list -m -u all`；`glistj` → `go list -m -json all`；`grun` → `go run -v .` |
| Go | `gbuild` → `go build -ldflags "-s -w" -trimpath -v .`；`gtest` → `go test -v -race -cover -covermode=atomic -count 1 ./...`；`gbench` → `go test -parallel=4 -run=none -benchtime=2s -benchmem -bench=.`；`gm` → `go mod` |
| Go | `gmi` → `go mod init`；`gmt` → `go mod tidy`；`gmg` → `go mod graph`；`gmc` → `go clean --modcache` |
| Docker | `dexec` → `docker exec -it`；`di` → `docker images`；`dimg` → `docker images`；`dps` → `docker ps` |
| Docker | `dpsa` → `docker ps -a`；`drmi` → `docker rmi`；`dkc` → `docker container`；`dkcm` → `docker compose` |
| Docker | `dkimg` → `docker image ls`；`dklg` → `docker logs -f`；`dkls` / `dkps` → `docker ps -a`；`dkrm` → `docker rm -f` |
| Docker | `dks` → `docker service`；`dksm` → `docker swarm`；`dkst` → `docker stack`；`dkstat` → `docker system df` |
| Disk | `df` → `df -h` |
| 目录/文件 | `mcd` / `mkcd` 目录 → `mkdir -p` 并进入；`cdf 路径` → 进入文件所在目录；`o [路径]` → `open` 当前或指定路径 |
| 目录/文件 | `dl url [输出名]` → 跟随重定向下载，HTTP 错误返回失败；`mktgz 目录` / `mkzip 目录` → 打包 tgz/zip；`tfind 关键词` → 用 rg 在 txt/md 中做不区分大小写的字面搜索 |
| 目录/文件 | `trim` → awk 折叠连续空白；`lsp` → 列出仓库文件；`lsmax` / `lslast` → 按大小 / 修改时间列出前 10 个文件 |
| 查看 | `jv 文件` → jq 彩色分页查看；`jp 文件` → `jq -M .`；`jsonview` → 从参数读取 JSON；`ccat` → `bat --paging=never`；`mcat` / `readme` → `glow` |
| 剪贴板 | `pc` → `pbcopy`；`pp` → `pbpaste`；`ppwd` / `pd` → 复制当前目录 / 目录基名；`pcat 文件…` → 复制文件内容；`l2l` → 多行转单行空格分隔 |
| 时间 | `now` / `utcnow` → 本地 / UTC 当前时间，复制并回显 |
| 哈希/编码 | `sha1` / `sha224` / `sha256` / `sha384` / `sha512` 文件 → `shasum -a …`；`b64e` / `b64d` → `base64` 编 / 解码 |
| Git 补充 | `dif` → `git diff --no-index`；`gmd` → 切回 legacy master 并 pull/prune（只有 main 的仓库不适用）；`git_corb 分支` → 检出远端同名新分支；`git_ignore [条目]` / `git_readme [行]` → 追加并 `git add` |
| tmux | `t` → `tmux`；`ts` → `tmux ls`；`ta` → `tmux attach -t`；`tk` → `tmux kill-session -t`；`tn [名称]` → 新建会话；`ta0`…`ta16` → attach 对应编号会话 |
| 杂项 | `reload` → 重读 `.zshrc`；`cls` → `clear`；`e` → `exit`；`ns` → `nslookup`；`weather` → `curl wttr.in`；`webserver` → `python3 -m http.server`；`fingerprint 密钥` → SSH 密钥 MD5/SHA256 指纹 |

另有多步快捷函数：`gpre` 依次查看状态、暂存全部改动、查看暂存差异；`gps1` 把当前分支推送到 origin 并设置 upstream。任一步失败立即停止；detached HEAD 下 `gps1` 直接报错，不执行推送。`dkclear` 手动执行 `docker system prune -f`，会删除所有停止的容器、未使用网络、悬空镜像和构建缓存，不删除卷；失败立即返回非零。

```bash
mb                         # 当前项目的 make build 目标
mt                         # 当前项目的 make test 目标
gs                         # Git 简短状态
gdiff                      # 当前仓库未暂存差异
gd old.txt new.txt         # 比较两个文件；存在差异时 Git 返回 1
gci "fix: explain change"  # 提交已跟踪文件的修改
dps                        # 运行中的容器
dexec container-name sh    # 进入指定容器
gtest                      # Go race / coverage 测试
```

`gd` 保留本地的 `git diff --no-index`，覆盖 Oh My Zsh 同名的 `git diff`；仓库差异用 `gdiff`。`gm` 保留本地的 `go mod`，覆盖插件同名的 Git merge；合并时使用 `git merge`。`d` 与 Oh My Zsh 的目录栈行为一致并在无 Oh My Zsh 时也可用；Docker 用 `dk` / `dc`。`gci` / `gcia` 是函数：缺少提交信息时报错返回，不执行空提交。`gpre` / `gaa` 会暂存全部修改，`gcia` 会 amend 最近提交，`git_undo_last` 会撤回最近提交并保留暂存内容，`grs` 会恢复工作区文件，`drmi` 会删除指定镜像；它们仅在你明确输入时执行。Make 别名要求项目已有相应 target。

依赖私人 revive 配置的 `glint`、独立 godoc 服务、旧 Go 1.16/1.17 兼容参数及 `go get -insecure` 没有导入；依赖私人工具（kpwdgen、kocc、zb64、barkme、kgetip 等）、写死个人路径或工作环境的定义同样未导入。原来的个人定义保留在用户自己的文件中。配置更新和终端生效步骤同下方 AI 别名。

### Claude / Codex 常用别名

交互 Zsh 提供以下八个快捷命令。参数可以直接追加，如 `cxc --help`。

| 别名 | 展开命令 | 行为 |
| --- | --- | --- |
| `cl` | `claude` | 普通启动 |
| `clc` | `claude --continue` | 继续当前目录最近的会话 |
| `cld` | `claude --dangerously-skip-permissions` | 跳过权限检查 |
| `cldc` | `claude --dangerously-skip-permissions --continue` | 跳过权限检查并继续会话 |
| `cx` | `codex` | 普通启动 |
| `cxc` | `codex resume --last` | 继续最近会话 |
| `cxd` | `codex --dangerously-bypass-approvals-and-sandbox` | 跳过审批并禁用沙箱 |
| `cxdc` | `codex resume --last --dangerously-bypass-approvals-and-sandbox` | 跳过审批、禁用沙箱并继续会话 |

带 `d` 的四项需要你显式输入才会启用对应模式，适合已另行隔离、可信的工作环境。普通别名沿用 CLI 的个人配置；安装不会改写全局权限设置，也不会自动启动这些命令。[Claude 参数说明](https://code.claude.com/docs/en/cli-reference)、[Codex 参数说明](https://learn.chatgpt.com/docs/developer-commands?surface=cli)。

已有机器只更新配置即可：

```bash
git pull --ff-only
./setup.sh --configure-only
# 完成后新开一个 iTerm2 / VS Code 终端
alias cld cldc cxd cxdc
```

若使用 `--config-dir`，同步自己的 shell.zsh 模板后用相同参数重跑；个人别名覆盖放在 `.zshrc` 的项目 source 行之后。未导入本地代理、凭据、内部工具或旧 `go get -insecure` 等定义；`dc` 继续使用已安装的 Docker Compose v2 命令 `docker compose`。

### VS Code 扩展与默认设置

脚本通过 [VS Code 官方 CLI](https://code.visualstudio.com/docs/configure/command-line)安装下列八项扩展；先执行 `--list-extensions` 判重，默认跳过已装项，`--update` 才显式请求更新。扩展枚举或安装失败会停止安装，并允许重跑。VS Code 自身的后台自动更新策略保留原设置。

| 功能 | Marketplace 扩展 ID |
| --- | --- |
| Go | `golang.go` |
| Python | `ms-python.python` |
| Ruff：Python 检查、格式化、整理 import | `charliermarsh.ruff` |
| ESLint | `dbaeumer.vscode-eslint` |
| Prettier | `esbenp.prettier-vscode` |
| YAML | `redhat.vscode-yaml` |
| ShellCheck | `timonwong.shellcheck` |
| Sublime Text 快捷键映射 | `ms-vscode.sublime-keybindings` |

保留 [Microsoft 的 Sublime Text Keymap](https://marketplace.visualstudio.com/items?itemName=ms-vscode.sublime-keybindings)，延续 Sublime Text 的常用操作习惯。安装后重载 VS Code 即可加载映射；它不是完整复刻所有 Sublime Text 功能。脚本不改写用户的 `keybindings.json`，也不自动执行扩展的 “Import Sublime Text Settings” 命令；首次启动如出现导入提示，按需选择，避免把旧主题和其他偏好一并迁入。

这份默认清单按 Go/Python/Node 与 Shell 开发选择。Ruff 使用 [Astral 官方扩展](https://docs.astral.sh/ruff/editors/setup/#vs-code)，补充 Python 的 lint/格式化；它不能替代 Python 扩展的解释器、调试或 Pylance 类型分析。Python 扩展通常自动附带 Pylance、Python Debugger 和 Python Environments，它们是上游可选依赖，因此“八项”是本项目主动选择的数量，不是最终扩展总数；本项目只逐项验收声明的八个 ID。

ESLint 检查 JS/TS 代码问题，Prettier 负责排版；遵循项目自己的依赖和配置，不全局启用保存时自动修复。Ruff 也不强行取代已有项目的 Black 等格式化器。YAML 用于 Actions/Compose 配置，ShellCheck 检查 Shell 脚本。原有 Container Tools/TOML 从默认清单移出后，已安装的个人副本仍保留，不执行卸载。

按实际工作选择下面的扩展，无需一次全装：

| 使用场景 | 可选扩展 | 安装命令 |
| --- | --- | --- |
| 管理 Docker 镜像、容器、Compose | [Container Tools](https://code.visualstudio.com/docs/containers/overview) | `code --install-extension ms-azuretools.vscode-containers` |
| 经常编辑 pyproject.toml / Cargo.toml / Codex 配置 | [Even Better TOML](https://marketplace.visualstudio.com/items?itemName=tamasfe.even-better-toml) | `code --install-extension tamasfe.even-better-toml` |
| 从 MacBook 连接 Mac mini 或 Linux 开发机 | [Remote SSH](https://code.visualstudio.com/docs/remote/ssh) | `code --install-extension ms-vscode-remote.remote-ssh` |
| 项目提供 devcontainer 配置 | [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) | `code --install-extension ms-vscode-remote.remote-containers` |

这些手动可选扩展由 VS Code 管理更新，不进入本脚本的必装验收和维护报告。安装 Remote SSH 不会自动开放 Mac 的远程登录；安装 Dev Containers 也不代表 Docker 引擎已经就绪。内置 Git、JS/TS、JSON、Markdown 支持优先使用，不默认增加 GitLens、Code Runner、主题包或第二套 AI 编程扩展。

完整清单在 [`vscode-extensions.txt`](config/vscode-extensions.txt)，扩展可能安装自己的依赖。新环境默认 **Default Dark Modern** 主题、Zsh 登录终端。已有 `settings.json`（包括 JSONC 注释）原样保留，不强制覆盖主题、保存时格式化或项目格式化器。`--verify` 检查八个 ID 是否存在，`inventory.json` 只记录这些扩展的版本以及 Oh My Zsh 的 Git revision，不收集全部私人扩展清单。检查当前用户默认本地扩展环境；远程容器、SSH 环境或单独 VS Code Profile 需要各自安装。

## 6. iTerm2 与真机操作

在 Profiles 菜单选择 **Clean Setup**，可在 Settings → Profiles → Other Actions 设为默认。它使用 Zsh 登录 shell，配合上面的 Oh My Zsh 配置。

**主题为 Clean Dark**：深灰背景、浅色文字、蓝色光标和完整 16 色 ANSI 配色；字体为系统自带 **Menlo 13**，关闭透明和模糊，不需要额外字体。颜色、字体、键位都写在独立的 Dynamic Profile 中，其他 Profile 保留。要持久修改，可编辑外部 `iterm2-profile.json` 模板后重新配置，或把此 Profile 复制成自己的普通 Profile。

| 按键 | 行为 |
| --- | --- |
| Ctrl / Option + ← / → | 向前 / 向后跳词 |
| Cmd + ← / →、Home / End | 行首 / 行尾 |
| Ctrl + A / E | 行首 / 行尾 |
| Ctrl + W、Option + Backspace | 删除前词 |
| Delete | 删除光标后的字符 |
| Ctrl + R | fzf 历史搜索（真实交互终端） |

左右 Option 都发送 Esc，终端映射与 Zsh 绑定同时配置。如果 Ctrl + ←/→ 切换了桌面，在系统设置 → 键盘 → 键盘快捷键 → Mission Control 中关闭相应空间切换快捷键。脚本不擅自更改系统全局快捷键。

常用命令：`j 目录关键词`、`z 目录关键词`、`ll`、`mcd 目录`（或 `mkcd`）、`d`（目录栈）、`clc`、`cxc`、`dk`（`docker`）、`dc`（`docker compose`）。

### 文件、文件夹拖入后出现上传提示

核对日期：2026-09-23。iTerm2 **3.7.2 / 3.7.3** 的普通拖放会根据会话的本地/远程判定分流：本地会话直接粘贴路径，远程会话显示文件操作对话框；单个远程文件或目录没有“Paste Path”选项。Finder 复制文件后直接 Cmd+V 也会进入新的文件操作流程。本地终端出现上传选项时，说明该会话被识别成了远程；仅换 Profile 不会关闭这段逻辑。

这两个版本没有独立的“始终拖入路径”设置。不要用 `NoSyncPasteNonTextFile` / `NoSyncPasteNonTextFiles` 的记住选择值来伪装修复：菜单按本地/远程、单个/多个文件改变，同一个选项序号可能变成上传。项目不写入这些值，也不关闭 shell integration 或伪造远程主机身份。

- **保留 3.7**：在 Finder 选中文件或目录，按 **Option+Cmd+C（复制为路径名称）**，再到终端粘贴纯文本路径；本地和 SSH 会话都可使用。路径含空格或 shell 特殊字符时，需要适当引用/转义。该方法绕过文件上传菜单，不改变普通拖放行为。
- **恢复旧拖放行为**：官方 **3.6.11** 在本地和 SSH 会话都将普通拖入处理为路径；只有按住 Option 拖入才请求上传。版本回退需先保存工作并正常退出 iTerm2，保留原应用和本机设置备份，再替换应用；不要强制结束现有会话。之后的 iTerm2 自身更新或 `./setup.sh --update` 可能再次升级，需单独检查。

源码依据：[3.7.2 拖放分流](https://github.com/gnachman/iTerm2/blob/v3.7.2/sources/TerminalView/PTYTextView.m)、[3.7.3 文件粘贴选项](https://github.com/gnachman/iTerm2/blob/v3.7.3/sources/Pasting/iTermNonTextPasteHelper.swift)、[3.6.11 拖放逻辑](https://github.com/gnachman/iTerm2/blob/v3.6.11/sources/PTYTextView.m)。官方旧版下载见 [iTerm2 Downloads](https://iterm2.com/downloads.html)。同步本项目和运行 `--configure-only` 不会替换 iTerm2，也不能移除 3.7 的这段应用行为。

### 滚动历史与 tmux 快捷命令

`Clean Setup` 从 0.1.31 起显式设置 **Unlimited Scrollback = true**、`Scrollback Lines = 0`（无限模式下不使用固定行数）；同时明确 `xterm-256color` 和鼠标事件报告。左右箭头逐字符移动；Ctrl/Option + 左右箭头跳词；Cmd + 左右箭头跳到行首/行尾。原有完整键位见上表。

这是终端保存的输出历史，不是鼠标滚轮一次滚动几行；无限历史也可能占用较多内存，见 [iTerm2 官方说明](https://iterm2.com/documentation-preferences-profiles-terminal.html)。动态 Profile 只更新 **Clean Setup**：更新后新开该 Profile 的窗口使用；普通 Default 或手工复制的 Profile 需在设置中自行开启 Unlimited Scrollback。

**更新备份位置**：`~/Library/Application Support/iTerm2/macos-setup-backups/`。iTerm2 会读取 `DynamicProfiles` 中所有文件，不按扩展名过滤；因此备份和临时文件必须放在加载目录外。旧版留下的 `clean-setup.json.backup-*` 会在 `--configure-only` / 普通安装时迁移并保留原始内容；重复执行不会重复搬移。若看到动态配置/GUID 冲突提示，可先执行 `./setup.sh --configure-only`；参阅 [iTerm2 动态 Profile 说明](https://iterm2.com/documentation-dynamic-profiles.html)。

终端统一使用 `ts` 列表、`tn` 新建的约定，并提供以下通用入口；即使没有启用 Oh My Zsh tmux 插件也能使用：

| 命令 | 行为 |
| --- | --- |
| `t` | 启动 tmux，保留已加载的个人 tmux wrapper |
| `ts` / `tl` | 列出会话（`ts` 保留本地含义，区别于 OMZ 插件原来的新建含义） |
| `tn [名称]` | 新建会话；`ta 名称` / `ta0`…`ta16` 接入已有会话 |
| `to 名称` | 会话存在则接回，否则创建；转发额外参数 |
| `tad 名称` | 接入会话并断开该会话的其他客户端 |
| `tk 名称` / `tkss 名称` | 结束指定会话；`tkss` 无参数时按 tmux 默认结束当前会话 |
| `tksv` | 结束整个 tmux server 及其全部会话，仅在明确输入时执行 |
| `tds` | 按当前目录接回/创建会话：目录名 + 完整路径 MD5 的前六位；同名不同路径使用不同会话 |
| `tmuxconf` | 使用 `$EDITOR`（未设时 `vi`）打开配置；优先 `$ZSH_TMUX_CONFIG`，再 `~/.tmux.conf`、XDG 配置，均不存在则打开新的 `~/.tmux.conf` |

`tds` 使用 macOS 自带 `md5` 生成目录会话名；目录名的点号/冒号转换为下划线以满足 tmux 命名约束。不会在登录时自动新建或接入 tmux，也不自动结束其他会话。已有个人 tmux 配置保持原状。

项目不创建或改写个人 tmux 配置。未自行改键时，tmux 自带的前缀是 `Ctrl+B`：先按前缀再按 `%` 左右分屏、`"` 上下分屏、方向键切换 pane、`d` 暂离会话、`[` 进入历史/复制模式、`]` 粘贴。**tmux 的 pane 历史有独立的 `history-limit`，iTerm2 Unlimited 不会将它变成无限**；需要更长历史时，在自己的 tmux 配置中设置 `set -g history-limit 100000`（影响新建 pane）。参阅 [tmux 官方使用说明](https://github.com/tmux/tmux/wiki/Getting-Started)。

其他通用命令：`cn [路径…]` 在 VS Code 新窗口打开（无参数打开当前目录），`cdiff 文件1 文件2` 比较文件，`rp 路径` 求绝对路径；`gbuildmac` / `gbuildmacintel` / `gbuildlinux` / `gbuildwindows` 分别构建 darwin/arm64、darwin/amd64、linux/amd64、windows/amd64；环境变量只对该次命令生效，涉及 CGO 的项目可能还需对应交叉工具链。`gcv` 运行 Go race/coverage 测试，成功后生成 `coverage.html`，测试失败则不生成新报告。

模板只包含通用命令，不包含业务域名、代理、凭据或个人路径。依赖未声明的 Cursor/goimports/goreturns 等工具的命令，以及旧版 Go 兼容参数仍由个人配置管理。

只更新这些配置，在同步后的项目目录执行 `./setup.sh --configure-only`，然后打开新的 **Clean Setup** 终端；已有配置备份后更新，重复执行不会重复追加或产生相同内容的备份。

### `j` / autojump 目录跳转

从 0.1.28 起默认通过 Homebrew 安装真正的 **AutoJump**，`j` 使用其官方 Zsh 集成和本机原有权重数据库；`z` / `zi` 继续使用 zoxide。两者的排序算法和历史数据库独立，权重数值不能直接比较。旧版只提供 zoxide 的 `j` 兼容函数，没有安装 AutoJump，因此 `whence -w j` 显示 function 并不能证明 AutoJump 已安装。

在需要修复的那台 Mac 上，从更新后的脚本目录执行：

```bash
./setup.sh                 # 补装 AutoJump；跳过已安装且健康的工具
# 完成后新开一个 iTerm2 / VS Code 终端
command -v autojump
autojump --version
j --stat                   # 查看 AutoJump 自己的目录权重
```

只修复这一项时，可先 `brew install homebrew/core/autojump`，再执行 `./setup.sh --configure-only` 并打开新终端。**单独 `--configure-only` 不会安装缺失的软件。** 先 `cd` 访问目录后再用 `j 关键词`；新机器的历史需要逐渐积累，脚本不导入另一台机器或 zoxide 的私人历史。

已有个人 `j` 函数、alias 或外部命令保持原定义；重新加载时只替换同一受管模板此前定义的 `j` → `z` 包装函数。重复加载不会重复注册 AutoJump 的目录变化 hook，也不会主动重置已有权重。AutoJump 缺失时不再用 zoxide 冒充 `j`；`z` / `zi` 仍可独立使用。个人覆盖可放在 managed source 行之后。

来源：[autojump](https://github.com/wting/autojump)、[zoxide](https://github.com/ajeetdsouza/zoxide)。

## 7. Docker 与安装后验收

1. 打开 Docker.app，完成首次初始化，等待引擎就绪。
2. 运行 `./setup.sh --docker-smoke`：实际构建、运行并清理一个 `linux/amd64` 测试镜像，断言输出。
3. 运行 `./setup.sh --verify`：检查全部受管包、可执行文件、app bundle、配置、Go 编译运行、Node 执行和 uv Python 环境。
4. 新开 iTerm2 的 Clean Setup 窗口，人工试用跳词、删除、行首行尾、Ctrl+R。
5. 按 Kiro 小节完成登录和审批验收。登录 Claude/Codex 后完成一次个人账号下的实际对话；自动测试不使用个人 token。

## 8. 检查与验收范围

开发检查使用 `make check`，包括 Bash/Zsh 语法、ShellCheck、单元测试、完整配置契约、发布清单和格式。测试使用临时目录与替身命令；部分原生工具测试在依赖不可用时会跳过。不要在日常工作的 Mac 上运行全量安装来测试改动。

`./setup.sh --verify` 检查目标机器上当前的工具、配置和运行时。命令行检查通过不代表桌面启动、账号登录、系统授权、iTerm2 补全或 Docker 虚拟化已经验收；这些项目必须在目标 Mac 上按第 7 节手动确认。

## 9. 常见故障与恢复

| 情况 | 处理 |
| --- | --- |
| 0.1.28 最后验证报 `Please source the correct autojump file` | AutoJump 可能已经安装成功；该版本验证脚本在 shell 初始化前调用了它。更新至 0.1.29+ 后直接重跑 `./setup.sh`，无需卸载；已有健康包会跳过。完成后新开终端 |
| CLT 尚未安装 | 完成系统安装提示后重跑 |
| `The following taps are not trusted` | Homebrew 6 默认要求显式信任第三方 tap。此警告不表示官方 Go 安装失败；本脚本不需要日志中的旧第三方源，不对它们自动 trust 或 untap；四项 Charm 工具安装仅信任对应包。只在你确实需要某个第三方包时按官方说明单独信任该项 |
| `curl: (92) HTTP/2 ... PROTOCOL_ERROR` | 下载连接的 HTTP/2 协议错误。更新到 0.1.12+ 后重跑，默认下载策略使用 HTTP/1.1 并保持 HTTPS 证书校验；若自定义了 HOMEBREW_CURLRC，在自己的配置里加入 `http1.1` |
| 停在 `Would install` / 下载阶段很久 | 检查 `network.tsv` 是否为 HTTP 000 / transport 28（超时），以及后续 run.log。日志模式下 Homebrew 可能隐藏下载进度；先 Ctrl+C，修复终端的网络/代理后用新版脚本重跑，不清空已装工具或下载缓存 |
| DNS/TLS/下载失败 | 查看 `network.tsv` 与具体下载错误，修复网络/代理后重跑；不要关闭 TLS 校验 |
| sudo 权限不足 | 使用普通管理员账号，处理系统授权后重跑 |
| formula 登记存在但不能运行 | 重跑会尝试重装；仍失败则查看该包输出与 Homebrew 官方说明 |
| Git / Git LFS 报 `gitconfig: Permission denied` | Git 配置不可读；按下文检查该文件与父目录权限，修复后直接重跑 |
| 现有 AI 配置无效 | 修复对应 JSON/TOML 后重跑；脚本不会强行覆盖它 |
| 外部 app 损坏 | 用原安装器修复后重跑，避免脚本误删个人 app |
| 返回 75 | 检查相同日志根目录下的安装锁及进程；不要强行启动第二份 |
| `result.json` 不存在 | 上次未正常结束；检查 events/run 日志后重跑，不能视为成功 |
| Docker 引擎未启动 | 打开 Docker.app 并完成首次初始化，再跑 smoke test |

### Git configuration access

若 Git LFS 已显示安装成功，随后报 `fatal: unable to access '/opt/homebrew/etc/gitconfig': Permission denied`，失败的是 Git 读取系统配置。脚本只向用户配置初始化 LFS；Homebrew 提示中的 `git lfs install --system` 不是脚本执行的命令。`git --version` 成功也不能证明配置可读。

从 0.1.36 起，检查覆盖 PATH 中的 Git、Homebrew 的 `bin/git` / `opt/git/bin/git` 和显式设置的 `HOMEBREW_GIT_PATH`，并在每次 Homebrew 安装、重装、升级或刷新前复查。0.1.34–0.1.35 只检查 PATH 中的 Git，可能漏掉 Homebrew 内部使用的另一份 Git。Git 安装阶段、LFS 初始化前和独立验收也执行检查；配置读取失败保留原始错误和退出码，并注明使用的 Git。检查不输出配置值，也不自动更改权限或绕过系统配置。二进制损坏仍按受管包规则修复，配置权限错误不会触发无效的重装。[Git 配置作用域说明](https://git-scm.com/docs/git-config)

项目下载的安装器脚本使用 `mktemp` 临时文件，软件包的下载、解压和安装由 Homebrew 或官方安装器管理。`/opt/homebrew/etc/gitconfig` 是 Homebrew Git 的持久系统配置位置，不是本项目的解压暂存目录；把它搬进临时目录不能解决配置访问问题，还可能丢失原有设置。安装器的 `umask 022` 防止新文件继承日志的私有权限，但不会纠正已有文件的 root 归属。

在报错的机器上先检查元数据，不必公开配置内容：

```bash
ls -lde /opt/homebrew /opt/homebrew/etc /opt/homebrew/etc/gitconfig
```

若 `gitconfig` 是当前用户拥有的普通文件，且只是缺少所有者读取位，可执行 `chmod u+r /opt/homebrew/etc/gitconfig`。若属于其他账户、是符号链接、存在拒绝访问的 ACL 或父目录不可进入，应由管理员按实际归属修复相应权限；不要递归修改整个 Homebrew，也不要用 `sudo ./setup.sh` 或禁用系统配置来掩盖错误。重新安装 Git/LFS 不保证修复已有配置文件的权限。

已确认是当前用户管理的 Homebrew、该普通文件发生一次性的错误归属，且没有后台程序管理它时，可仅恢复这一个文件的所有者，保留其 600 权限与内容：

```bash
sudo chown "$(id -un)" /opt/homebrew/etc/gitconfig
ls -lde /opt/homebrew/etc/gitconfig
```

修复后执行：

```bash
/opt/homebrew/bin/git config --list >/dev/null   # 明确检查 Homebrew Git，不输出配置内容
# 上一步成功后：
./setup.sh                    # 保留原有选项；已安装的健康工具会跳过
```

单独升级脚本不会修复该文件的访问权限。如果修复成功后文件又变为 root，不要继续反复 chown；需要检查后台写入。可先在一个终端运行 60 秒追踪，仅显示该路径及锁文件相关操作，不读取配置内容：

```bash
sudo fs_usage -w -f filesys -t 60 |
  awk 'index($0, "/opt/homebrew/etc/gitconfig") { print; fflush() }'
```

在另一个终端进行一次受控的权限修复，暂不运行安装器。留意 `gitconfig.lock` 的创建、chmod 和 rename；普通 stat/open 读取不能证明那个程序发起了改写。`fs_usage` 的进程名后数字是线程 ID，不要直接当作 PID。未捕获写入也不能排除周期性改写。

若确认是后台特权流程通过 Git 重写配置，替换后的普通文件仍为 `root:admin / 600`，并且该系统配置应允许本机 admin 组读取，可保留 root 所有权，只补组读取位。先确认当前用户属于 admin：

```bash
/usr/sbin/dseditgroup -o checkmember -m "$(id -un)" admin
# 上一步确认 yes 后：
sudo chmod g+r /opt/homebrew/etc/gitconfig
ls -lde /opt/homebrew/etc/gitconfig
/opt/homebrew/bin/git config --list >/dev/null
```

对于原来的 600，这会得到 640：root 可读写、admin 组可读，其他用户仍无权限。[Git 的配置写入实现](https://github.com/git/git/blob/master/config.c)会将旧文件的权限位复制到锁文件，再原子替换配置；因此仅 chown 后，root 写入者仍会创建 root 所有的新文件，并沿用 600。应观察下一次实际后台写入后是否仍为 `root:admin / 640` 且 Git 读取成功，再重跑安装器。若又被设回 600 或属组改变，需要修正写入程序的权限设置；不要自动循环改权限或停用尚未确认用途的后台程序。

0.1.37 修订了上述恢复说明，安装逻辑沿用 0.1.36。现有机器可直接进行针对性的权限修复，无需先升级脚本。脚本不会自动扩大系统或私人配置的读取范围。

## 10. 仓库边界、维护与可复现性

```text
macOS-devenv/            项目目录
  setup.sh              安装入口
  config/               包、来源、发布文件清单与公开模板
  scripts/              会话、配置、验收与构建检查
  tests/                回归测试与完整 golden 快照
  docs/                 机器接口、结果 schema、来源与维护说明
```

[`config/repository-files.txt`](config/repository-files.txt) 列出完整发布边界。构建要求 tracked files 与它完全一致，分发包也仅使用这份名单。新增文件必须明确审阅；禁止从父目录递归打包。私人配置、日志、认证文件和备份由 `.gitignore` 排除。

Finder 的 `.DS_Store` 不参与格式检查或打包；若误被 Git 跟踪，发布边界检查仍会失败。缺少清单文件会明确列出文件名。ZIP 解压后的副本可用于安装；开发构建和发布应在独立 Git checkout 中进行。

```bash
make check              # 构建 → 测试 → 格式检查
# 输出：dist/macos-setup.tar.gz，仅包含审阅过的文件
```

固定 Git 提交能复现流程、模板、包集合和验收标准；第三方 stable/latest 版本仍会滚动变化。`inventory.json`、输入摘要与安装器摘要用于审计和比较，不能冒充完整二进制版本锁。主动升级后应保存新旧记录，再运行完整验证。

所有安装器、工具、配置规范与后续更新入口集中在 **[来源与更新说明](docs/sources.md)**。机器操作约定见 **[自动化说明](docs/automation.md)**。
