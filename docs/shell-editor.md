# Shell、编辑器与终端配置

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

完整清单在 [`vscode-extensions.txt`](../config/vscode-extensions.txt)，扩展可能安装自己的依赖。新环境默认 **Default Dark Modern** 主题、Zsh 登录终端。已有 `settings.json`（包括 JSONC 注释）原样保留，不强制覆盖主题、保存时格式化或项目格式化器。`--verify` 检查八个 ID 是否存在，`inventory.json` 只记录这些扩展的版本以及 Oh My Zsh 的 Git revision，不收集全部私人扩展清单。检查当前用户默认本地扩展环境；远程容器、SSH 环境或单独 VS Code Profile 需要各自安装。

## iTerm2 与真机操作

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
