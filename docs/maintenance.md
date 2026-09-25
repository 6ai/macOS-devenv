# 维护流程：先检查，再更新，再验收

安装成功是基线，不代表以后一直最新。维护分别处理软件版本、实际可用性、脚本和配置变更；每次保存当次报告，避免拿旧成功日志判断当前机器。

## 日常入口

```bash
./setup.sh --check-updates             # 联网查版本、模板差异；不执行安装或升级
./setup.sh --verify                    # 检查当前工具和配置是否仍然可用
# 阅读本次日志目录中的 updates.md / updates.json，再决定是否更新
./setup.sh --update                    # 明确执行升级、修复与最终验收
./setup.sh --check-updates             # 再查一次，保留更新后的报告
```

外部配置目录应在每次检查、安装和配置时使用相同的 `--config-dir DIR`。检查写入本次日志和报告；第三方查询命令可能维护自己的缓存，但不运行 `brew update/upgrade/install`、安装器、`git fetch/pull` 或配置写入。查询有超时，版本查询失败不会触发自动升级。检查模式沿用安装锁、环境摘要和私有日志权限。

`--check-updates` 的退出码 0 表示检查完成，**不表示没有更新**。查看 `summary` 和每行 `status`。部分查询失败时仍保存报告，`complete: false`、退出码 1；`unknown` 不得当作最新或缺失。JSON 接口见 [`updates.schema.json`](updates.schema.json)。`--verify` 才负责运行健康检查；例如已登记但命令被删除的软件，版本检查可能仍显示相同版本，验收会发现损坏。

## 报告覆盖与来源

| 对象 | 检查方法 | 执行更新的方式 |
| --- | --- | --- |
| Homebrew 自身 | 当前命令版本对比官方 GitHub release | `brew update`；刷新 Homebrew 和包元数据，不等于升级已安装软件 |
| 所有声明的 formula | 本机已安装版本对比实时 Homebrew stable API，包含 `_revision`、官方动态别名与 pin；识别 tmux 字母后缀和 ImageMagick 数字补丁号 | `./setup.sh --update`；保留 pin，停用/弃用包先审阅替代项 |
| 非 AI 桌面应用 | 读取实际 app bundle 版本，对比当前 Cask；记录应用自行更新后的真实版本 | 默认 Chrome/Docker 刷新 DMG；托管模式的受管 cask 才自动升级。已有外部副本使用应用自己的更新器 |
| ChatGPT、Claude Desktop、Kiro IDE/CLI、Claude / Codex CLI | 实际版本对比官方最新/stable 元数据；不查询 Homebrew 参考版本 | 默认桌面准备 DMG，CLI 使用官方脚本；`--managed-desktop --update` 更新记录的 app，默认 Kiro CLI 由官方应用更新 |
| 八项 VS Code 扩展 | Marketplace 查询，排除预发布和非 arm64/通用包，列出 VS Code 引擎要求 | `--update` 调用官方 VS Code CLI；实际兼容版本由 VS Code 选择 |
| Oh My Zsh | 官方 origin 的远端 master SHA 与本地 SHA、本地改动状态 | `--update` 仅对干净的官方 checkout 做快进更新 |
| 本安装仓库 | 已确认的 origin/main SHA 与本地 SHA、本地改动状态 | 人工审阅后 `git pull --ff-only`，见下节 |
| 七份配置模板 | 对比所选模板与安装位置的字节，仅报告相同/不同/缺失 | 受管模板审阅后 `--configure-only`；私人 AI/VS Code 文件继续保留 |
| macOS / 固件 | 报告提醒人工检查系统软件更新 | 系统设置 → 通用 → 软件更新；留出重启窗口 |

Homebrew 自身版本优先查询官方 GitHub API；接口失败时读取官方 latest release 的跳转目标，不需要提供访问令牌。两个入口均失败时仍报告 unknown，不把查询失败当作最新。

Homebrew 目录是本项目的发行版本基准，可能晚于供应商原生通道；不能把目录版本冒充所有渠道的最新版本。已安装版本领先时标为 `ahead`，不建议降级。无法可靠比较的预发布或特殊版本标为 `manual`。扩展报告给出当前稳定发行候选与引擎要求，不声称它一定兼容旧编辑器；先更新 VS Code，再由其官方安装器选择兼容版本。查询只携带公开扩展 ID，不发送工作区、代码或私人扩展列表。

## 如何处理状态

| status | 处理 |
| --- | --- |
| `current` | 与本次参考版本/模板相同；仍需独立验收可用性 |
| `update_available` | 有可比较的新版本；阅读更新说明，安排升级 |
| `ahead` | 本机领先参考目录，保留；不要为对齐目录降级 |
| `missing` / `repair_needed` | 受管工具跑普通 `./setup.sh` 修复；CLI 使用官方脚本；默认缺失桌面应用下载 DMG，托管模式才自动放置；未知来源损坏副本使用原安装器 |
| `different` | 模板或 Git revision 有差异，先审阅；Git 差异可能是领先、落后或分叉 |
| `preserved` | 私人 AI/编辑器配置不同，正常保留；不会因重跑自动覆盖 |
| `manual` | pin、停用包、自定义 origin、特殊版本或系统更新，需要人工维护 |
| `unknown` | 查询失败或数据不足，修复网络/工具后重查；不能据此判定最新 |

报告中的 `next_action` 是建议类别，绝不直接执行其中的文本。`setup` 对应普通安装/修复；`update` 对应明确升级；`original_updater` 用原管理器；`review` 先审阅；`none` 无版本操作。修复配置缺失时也可只运行 `--configure-only`。`attention_required` 包含人工检查项，不仅指有新版；准确的更新数量看 `summary.update_available`。

## 更新安装脚本与配置

```bash
git status --short
git diff                              # 先确认自己的修改已保存
git pull --ff-only                     # 不强制覆盖、不重置私人修改
git fetch --tags
git describe --tags --exact-match       # 正式发布提交应有 v<VERSION> tag
./setup.sh --plan
./setup.sh --check-updates
```

版本检查仅通过 `ls-remote` 获取 SHA，不下载远端提交，所以只报告“有差异”，不会猜测是否能快进。分叉或未提交修改应先由维护者处理，禁止 `reset --hard`、自动覆盖或强推。ZIP 安装、自定义 fork、没有 origin 的副本标为人工维护；从公开项目仓库获取新版本，不把父目录或私人配置打包上传。

阅读新版本 README 和 `docs/sources.md`，确认新增包、模板与官方权限规范。外部配置目录新增模板时，只补入缺少的文件，不用新的整个 config 目录覆盖旧私人设置。受管 env/shell/iTerm2 模板审阅后应用，原有备份保留；Claude、Codex、Kiro IDE、VS Code 的个人配置差异需要人工合并。

Kiro CLI 的 Zsh hooks 和历史补全选择由其专门的安装/验收逻辑管理，不是对私人 CLI JSON 做模板覆盖。供应商改了初始化代码或权限格式时，应更新脚本、完整契约测试，再验证 CLI 实际加载；不能只改一个版本号。

## 建议周期与更新窗口

| 时机 | 工作 |
| --- | --- |
| 每周、准备新项目或发现异常时 | `--check-updates`，查看未知项与可更新项；异常时补 `--diagnose` / `--verify` |
| 每月一次或有需要的修复时 | 关闭相关应用、保存工作，记录更新前报告，执行 `--update`，保留更新后报告 |
| macOS 大版本、Docker/Kiro/终端集成变化后 | 真机检查 Docker 引擎、iTerm2 按键/补全、AI 登录和工具审批 |
| 修改安装脚本或来源时 | patch 版本、完整清单/配置契约测试、构建→测试→格式、同一版本的隔离验证 |

不安装后台自动升级任务，不自动申请权限、解除 pin、清除缓存/旧包或批量卸载回滚。更新失败保留已完成步骤，按日志修复后重跑同一命令。需要退回某个软件版本时，先确认厂商支持的回退方式和数据兼容性；Git 回退安装脚本并不会回退已经安装的软件。

版本检查必须在目标 Mac 本地执行；另一台机器的测试结果无法替代本机的软件盘点。
