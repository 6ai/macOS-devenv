# 故障排查与恢复

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

## 中断后继续（0.1.41+）

等待上一轮安装子进程结束，再用同样的参数和日志目录重跑。退出码 75 表示并发保护仍在生效，不要删除 `session.lock`；这个文件在正常结束后也会保留，存在本身不表示被锁住。升级前先结束旧版本的安装进程。

安装器会重新检查软件健康状态，修复有安装归属记录的 CLI 半成品，并核查/恢复桌面应用替换事务；已下载且校验完整的 DMG 可以复用。没有 `result.json` 的旧运行视为未完成。个人配置和未知来源的损坏应用不会被强制覆盖；网络、磁盘、权限或上游安装器自己的锁仍可能需要人工处理。
