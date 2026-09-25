# Sources and update procedure

核对基线：2026-09-06。原生安装器地址的唯一执行清单是 [`config/sources.tsv`](../config/sources.tsv)。修改本文的链接不会偷偷改变安装行为；必须同时修改清单、golden fixture 并通过检查。

AI 官方安装入口补充核对：2026-09-25；其他桌面应用、Oh My Zsh、VS Code 扩展及 Chrome / 搜狗渠道：2026-09-07。原生脚本下载地址由 `sources.tsv` 控制；Homebrew 包的安装地址由各自官方 tap 的 formula/cask 定义控制，并从厂商分发站点获取。可选的 `--with-sogou` 扩展由 Cask 提供版本、完整 URL 和 SHA-256，`sources.tsv` 的 distribution 行另限制允许的官方分发前缀；脚本直接下载原 ZIP。

## 安装器与配置规范

| 组件 | 执行来源 | 官方说明 / 后续更新入口 |
| --- | --- | --- |
| Apple Command Line Tools | 本机 `xcode-select --install` 系统安装器 | [Apple Xcode 资源](https://developer.apple.com/xcode/resources/)，系统软件更新 |
| Homebrew | `Homebrew/install` 的 `HEAD/install.sh` | [brew.sh](https://brew.sh/)、[官方安装仓库](https://github.com/Homebrew/install)、[平台支持](https://docs.brew.sh/Support-Tiers) |
| Claude Code（自动官方安装） | `curl -fsSL https://claude.ai/install.sh \| bash` | [安装 / 版本管理](https://code.claude.com/docs/en/setup)、[settings 规范](https://code.claude.com/docs/en/settings) |
| Codex CLI（自动官方安装） | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` | [官方 CLI 安装](https://learn.chatgpt.com/docs/codex/cli)、[配置规范](https://learn.chatgpt.com/docs/config-file/config-basic) |
| ChatGPT / Codex 桌面端（默认下载 DMG） | 官方下载页，OpenAI `persistent.oaistatic.com/codex-app-prod/` 原包 | [当前官方桌面说明](https://learn.chatgpt.com/docs/app)、[当前 Cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/c/chatgpt.rb)、[旧 Codex Cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/c/codex-app.rb) |
| Kiro CLI / Zsh | 默认使用官方安装脚本和 onboarding；托管模式才解析 manifest 并配置 Zsh | [Cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/k/kiro-cli.rb)、[CLI 命令](https://kiro.dev/docs/reference/cli-commands/)、[补全](https://kiro.dev/docs/cli/autocomplete/)、[2.x 信任规则](https://kiro.dev/docs/cli/2x-reference/) |
| Kiro IDE（默认下载 DMG） | [官方下载页](https://kiro.dev/downloads/)，`prod.download.desktop.kiro.dev` 官方架构专用 DMG | [安装](https://kiro.dev/docs/getting-started/installation/)、[Cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/k/kiro.rb)、[权限规范](https://kiro.dev/docs/permissions/)、[数据保护](https://kiro.dev/docs/privacy-and-security/data-protection/) |
| Oh My Zsh | `https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh`，unattended / KEEP_ZSHRC=yes / CHSH=no / RUNZSH=no | [官方安装说明](https://github.com/ohmyzsh/ohmyzsh#unattended-install)、[主题源码](https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme) |
| Docker Desktop | 默认官方 arm64 DMG；托管模式使用官方 cask | [Mac 安装说明](https://docs.docker.com/desktop/setup/install/mac-install/)、[cask](https://formulae.brew.sh/cask/docker-desktop) |
| iTerm2 | Homebrew `iterm2` cask | [官网](https://iterm2.com/)、[Dynamic Profiles](https://iterm2.com/documentation-dynamic-profiles.html)、[按键配置](https://iterm2.com/documentation-preferences-profiles-keys.html)、[官方按键预设源码](https://github.com/gnachman/iTerm2/blob/master/plists/PresetKeyMappings.plist) |
| VS Code | Homebrew `visual-studio-code` cask | [官网](https://code.visualstudio.com/)、[cask](https://formulae.brew.sh/cask/visual-studio-code) |
| Google Chrome | 默认 Google 官方 Universal DMG；托管模式使用官方 cask | [官网](https://www.google.com/chrome/)、[Cask 下载地址与安装步骤](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/g/google-chrome.rb)、[官方 PKG 说明](https://support.google.com/chrome/a/answer/9020580?hl=zh-Hans) |
| 搜狗输入法（可选扩展、手动完成） | `--with-sogou` 下载官方 ZIP 到 Downloads；Homebrew `sogouinput` 提供 URL/校验和，安装器标记为 manual | [官网与下载入口](https://pinyin.sogou.com/mac/)、[官方更新日志](https://pinyin.sogou.com/mac/update_log.php)、[Cask 地址和 SHA-256](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/s/sogouinput.rb) |
| Go | Homebrew 无版本后缀的 `go` formula | [Go 发布](https://go.dev/dl/)、[formula](https://formulae.brew.sh/formula/go) |
| 其余命令行工具 | [`formulae.txt`](../config/formulae.txt) 中的 Homebrew 官方 formula | `https://formulae.brew.sh/formula/<token>`；页面给出上游官网、源码仓库、版本和 bottle 支持 |

0.1.40 默认采用 [安装方式汇总](installation.md) 中的分工：桌面先检查已有应用，缺失时下载官方 DMG；iTerm2/VS Code 使用 cask；AI CLI 优先官方脚本。`--managed-desktop` 保留自动放置桌面应用与 Kiro hook 配置。

ChatGPT 使用固定 `https://persistent.oaistatic.com/codex-app-prod/Codex.dmg` 和同目录 appcast；Kiro IDE 从官方下载页选择 stable/arm64 DMG；Claude Desktop 从官方 RELEASES.json 读取版本与 ZIP 文件名，下载同目录、同名的 DMG（已核对当前官方发行包）。Chrome、Docker 使用官方滚动 DMG 入口。普通重跑复用摘要一致的包，`--update` 刷新；地址均在 sources.tsv。

Claude Code CLI 与 Codex CLI 使用各自官方版本元数据和原生脚本。默认 Kiro CLI 直接运行 `https://cli.kiro.dev/install`，保留供应商的替换提示、启动及集成；托管模式才使用其官方 stable manifest 的 SHA-256 和 DMG。下载摘要用于复用/审计，不冒充独立供应商签名。

Homebrew 按官方 tap 中的 formula/cask 获取厂商软件，并检查定义中声明的校验和。不是所有 Cask 都有固定 SHA-256：Chrome 的滚动 DMG 为 `no_check`，自动化测试 另检查已安装应用的代码签名、bundle ID、arm64 架构和实际渲染；搜狗 Cask 则有固定 SHA-256；脚本拒绝非预期官方 HTTPS 地址或无固定摘要的定义，校验 ZIP 后才保存，并在报告中记录待手动安装。Homebrew 社区维护安装说明，并不代表供应商维护 Cask。脚本仍需执行的原生安装器（Homebrew、Oh My Zsh、Claude、Codex）通过 HTTPS 下载，保存本次下载的 SHA-256 后再运行；这个摘要提供审计线索，**不等于**独立供应商签名校验或版本锁定。不要把执行地址改成任意镜像、内部代理或来历不明的脚本。

搜狗官网当前列出的分发域名包括 `ime.gtimg.com`；Cask 使用官网列出的 legacy ZIP，与主下载按钮选择的 ZIP 可能不同。若要求与手动点击官网主下载按钮得到完全相同的包，以该按钮为准。只有图形安装器的发行包不应猜测静默参数、提取内部组件后拼装安装或直接写系统输入法偏好；按厂商安装向导和 Apple 输入源设置完成。

Chrome 的 自动化测试 渲染测试使用独立临时 profile、软件渲染和测试用 keychain；`--use-mock-keychain` 参考 [Google Chrome Launcher 的官方测试参数](https://github.com/GoogleChrome/chrome-launcher/blob/main/src/flags.ts)，避免无人值守环境中的钥匙串授权弹窗。参数只用于 自动化测试 启动，不写入用户浏览器配置；[Headless 官方说明](https://developer.chrome.com/docs/automation-and-testing/headless) 提供后续更新入口。


## Kiro 历史核对记录（2026-09-08；当前安装策略见 0.1.40）

IDE Cask 为 1.0.437，固定架构对应 SHA-256，通过厂商 signed DMG 分发；后续按 Cask 和官方更新日志重新核对，不锁死这个示例版本。自动化测试 检查实际代码签名、bundle ID、arm64、版本命令和重复配置摘要。用户级 permissions.yaml 的 capability/effect 规则以当前官方权限文档为准，默认 all/ask；IDE 0.x 的旧 Autopilot/Supervised 机制不能等同于新版规则。

独立 CLI 的[官方 stable manifest](https://prod.download.cli.kiro.dev/stable/latest/manifest.json)和 [CLI Cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/k/kiro-cli.rb)当时为 2.21.1；原生安装脚本另有 Amazon Q 迁移和自动启动步骤。0.1.40 仅在 --managed-desktop 模式直接校验并放置该 DMG、调用独立 Zsh dotfiles 集成；默认交给官方原生脚本和 onboarding，不自行拆解其流程。

本机实际 CLI 2.21.1 的 --help、init 和隔离 HOME 测试补充确认：status 即使选择 zsh 也返回其他 shell，必须筛选并断言 .zshrc/.zprofile；生成的加载器固定调用 ~/.local/bin/kiro-cli；CLI 会调用独立 kiro-cli-chat，因此三条命令均需可用。inline.enabled 未设时的生成代码含无效单引号，使用官方 inline disable 设置新环境偏好后语法恢复正常。已有明确选择保留。CLI settings 子命令与终端辅助应用的 inline 配置接口不同，读取其官方 CLI JSON 中单个偏好后由 inline disable 写入，避免误用新文档接口。

权限与集成必须按实际发行包验证，不能因官网已有 CLI 3.x 文档就假定 stable 包支持新版 permissions.yaml。后续升级还须检查 shell init 输出、加载器位置、JSON 状态契约及默认隐私选择，不只更新一个版本字符串。

## 编辑器、终端与环境变量配置来源

- VS Code 扩展通过[官方 CLI](https://code.visualstudio.com/docs/configure/command-line)从 Marketplace 安装；[Container Tools 官方说明](https://code.visualstudio.com/docs/containers/overview)。逐项发布页：[Go](https://marketplace.visualstudio.com/items?itemName=golang.Go)、[Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)、[Container Tools](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-containers)、[ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)、[Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)、[YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)、[TOML](https://marketplace.visualstudio.com/items?itemName=tamasfe.even-better-toml)、[ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)。这些扩展由各自发布者维护，并非全部由 Microsoft 维护。
- iTerm2 使用官方 [Dynamic Profiles](https://iterm2.com/documentation-dynamic-profiles.html) 与 [Profile Colors](https://iterm2.com/documentation-preferences-profiles-colors.html) 字段。Clean Dark 是本项目的颜色模板，Menlo 是系统字体；没有从用户配置或私人主题中复制。
- Codex [CODEX_HOME 环境变量](https://learn.chatgpt.com/docs/config-file/environment-variables) 与 Claude [CLAUDE_CONFIG_DIR](https://code.claude.com/docs/en/env-vars) 决定配置目录；脚本尊重调用者已设置的绝对路径。GUI 环境继承不能由终端 PATH 配置保证。
- Powerlevel10k 仅作为后续可选项，未纳入安装；其[字体说明](https://github.com/romkatv/powerlevel10k#fonts)是之后配置 MesloLGS NF 和向导的入口。

## Homebrew 信任与下载超时

[Tap Trust 官方说明](https://docs.brew.sh/Tap-Trust)规定 Homebrew 6 默认只加载官方或明确受信任的第三方定义。用户已有的 Bun/Turso 等 tap 警告与本项目官方 Go 包独立；不要为消除提示而信任整个第三方 tap，也不要自动卸载用户软件源。

[HOMEBREW_CURLRC 官方接口](https://docs.brew.sh/Manpage#environment)允许按绝对路径加载 curl 配置。项目只在该变量未设置时选择公开的 `config/download.curlrc`，不改写私人代理、证书或信任设置。默认 HTTP/1.1 用于避开已观察到的 HTTP/2 PROTOCOL_ERROR，保持 HTTPS 与证书校验；本项目直接调用 curl 的安装器下载、网络诊断和搜狗下载也加载此策略。协议、连接、停滞、单次传输和重试窗口限制分别参照 [curl 官方参数](https://curl.se/docs/manpage.html)：`http1.1`、`connect-timeout`、`speed-limit` / `speed-time`、`max-time`、`retry-max-time`。网络连通性本身仍需使用者的终端网络/代理可用；超时策略负责及时退出并允许重跑，不会自动切换镜像或关闭 TLS 校验。

## 外网诊断范围

只检查 `sources.tsv` 中 `connectivity` 行：Homebrew API、GitHub、ghcr、npm、Anthropic 安装入口和 OpenAI 安装入口。请求有连接/总时限，不携带用户 API key，不输出代理地址，不使用 IP 查询服务。

HTTP 401/403/429 说明服务器可达，但不保证认证、配额或下载权限；TLS/DNS/连接失败和 5xx 会被记录为异常。安装模式会提示并继续尝试具体安装，方便使用已有软件或本机缓存；`--diagnose` 遇到上述连通性异常返回非零。最终下载或验证失败始终使安装失败，不会伪造成功。

## 版本检查来源

`--check-updates` 的查询入口在 sources.tsv 的 maintenance-* 行。软件查询使用 [Homebrew 公开 API](https://formulae.brew.sh/docs/api/)；Homebrew 自身用官方仓库的 release 元数据。检查不调用 brew update，Homebrew 发行目录可能晚于供应商自己的渠道；本机领先时保留。

VS Code 扩展查询方式参考 [Microsoft 官方 Gallery 查询实现](https://github.com/microsoft/vscode/blob/main/src/vs/platform/extensionManagement/common/extensionGalleryService.ts)：按公开 ID 请求版本和属性，排除预发布、筛选 arm64/通用发行版；报告引擎要求，由 VS Code CLI 负责实际安装兼容性。Git 使用 ls-remote 查询已确认的 origin，不获取代码或自动拉取。方法、维护周期、失败与回退边界见 [维护手册](maintenance.md)。

## 本次 Homebrew / 扩展调整（2026-09-09）

Homebrew [install/reinstall/upgrade 的 no-ask 文档](https://docs.brew.sh/Manpage)以及官方源码 `install.rb` / `diagnostic.rb` 确认：默认 ask 会打印 Would install 预览；全局 preinstall 检查仍会提示 wholly untrusted taps，与指定的官方 Go 包无关。安装进程禁用 ask，并把所有受管包的解析限定到官方完整名称，保留 trust 边界与错误输出。

默认扩展为八项，新增 [Ruff 官方编辑器集成](https://docs.astral.sh/ruff/editors/setup/#vs-code)，其 Marketplace ID 仍是 `charliermarsh.ruff`。采用项目已有 lint/format 规则，不全局开启自动修复。[Python 扩展](https://marketplace.visualstudio.com/items?itemName=ms-python.python)的 Pylance、Debugger、Environments 属上游可选伴随扩展，不重复指定、不声称仅检查 Python ID 就验收了所有伴随功能。Container Tools 和 TOML 改为手动选项；Remote SSH / Dev Containers 的用途、官方文档与单项安装命令见 [终端与编辑器说明](shell-editor.md)。

Sublime Text 快捷键映射按使用者习惯保留为默认项，来源是 [Microsoft 的 Sublime Text Keymap and Settings Importer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.sublime-keybindings)。只安装扩展以加载键位贡献，不自动导入旧 Sublime 配置、不修改个人 keybindings.json；首次启动的设置导入提示由使用者决定。

## 维护步骤

1. 阅读对应供应商的官方安装、配置和发布说明，确认平台支持和安装方式是否变化。
2. 更新 `sources.tsv`、包清单或配置模板；不要把私人凭据写进仓库。
3. 仅增加 patch 版本。变更文件集时更新 `repository-files.txt`，再有意更新完整配置 golden fixture。
4. 暂存明确的文件，运行 `make check`：构建 → 回归测试 → 格式检查。
5. 在一次性测试环境验证全新/已有安装、跳过行为、配置保留和失败恢复；不要在日常工作机器上执行全量安装测试。
6. 为通过验证的正式提交创建并推送 `v<VERSION>` 注释 tag，核对远端 tag 与 VERSION/提交一致，不能移动旧 tag。
7. 对比新旧 `inventory.json` / `downloads.tsv`；以日志中的实际版本为准，而不是 README 中的历史例子。
8. 在目标 M4 真机完成 Docker 引擎与 GUI 按键验收后，才把该部分记为真机通过。

## 可复现范围

固定 setup Git 提交可以固定流程、模板、包集合及验证标准；上游 stable/latest 是滚动版本。记录版本清单、源脚本摘要和输入摘要可追踪差异，但不能保证任意日期安装到字节相同的第三方软件。需要长期保留精确二进制时，应另行保存相应供应商发行包及校验信息，并核对再分发许可；此仓库不暗中缓存或发布第三方软件。

## Charmbracelet 工具（2026-09-10 核对）

默认安装 Glow、Pop、Gum、Crush，来源为 [Charm 官方 tap](https://github.com/charmbracelet/homebrew-tap)。对应 [glow.rb](https://github.com/charmbracelet/homebrew-tap/blob/master/glow.rb)、[pop.rb](https://github.com/charmbracelet/homebrew-tap/blob/master/pop.rb)、[gum.rb](https://github.com/charmbracelet/homebrew-tap/blob/master/gum.rb)、[crush.rb](https://github.com/charmbracelet/homebrew-tap/blob/master/crush.rb) 提供 macOS arm64 的 GitHub Release 包与 SHA-256；Homebrew 完成下载校验及安装。版本随该 tap 更新，不将核对当天版本写死。

安装使用完整 `charmbracelet/tap/<name>`，按 [Tap Trust 官方规则](https://docs.brew.sh/Tap-Trust)仅授权这四个 formula，不信任整个 tap。已有 Homebrew core 副本保留原渠道。维护元数据入口为 sources.tsv 的 maintenance-charm；只读取生成式 version/revision 声明，不执行远程 Ruby，声明格式变化时明确报告 unknown。

## AI CLI 别名（2026-09-11 核对）

`cld` / `cldc` / `cxd` / `cxdc` 的名称及参数顺序参考本地 Zsh 的通用定义，只手动移植上述无账号、无路径的命令。用本机 `claude --help`、`codex --help`、`codex resume --help` 核对参数，并对照 [Claude CLI reference](https://code.claude.com/docs/en/cli-reference) 和 [OpenAI 官方 CLI 文档](https://learn.chatgpt.com/docs/developer-commands?surface=cli)。这些是显式绕过模式的快捷方式；没有改写供应商默认权限配置。后续 CLI 改动时更新模板、shell-editor.md 别名表和完整配置 golden，并用真实 Zsh 的替身命令验收所有别名及额外参数传递。

## 开发快捷命令（2026-09-11 核对）

Make / Git / Go / Docker 别名参考本地 Zsh 的通用定义，并对照本机 Oh My Zsh 的 `plugins/git/git.plugin.zsh` 检查名称冲突。只手动移植公开命令；`gd` 和 `gm` 按本地习惯覆盖插件，README 明确替代命令。多步 gpre / gps1 改为出错即停的函数，不携带固定分支、私人路径或代理配置。后续更新时同步完整配置 golden、README 映射与真实 Zsh 替身验收；安装和测试不执行实际提交、推送、镜像删除或 Go 模块缓存清理。
