# qBittorrent：Mac 上独立运行的下载服务

这是 macOS Setup 的可选应用目录，**不会被 `setup.sh` 自动启动**。整个目录可单独复制使用。需要已运行的 Docker Desktop（或兼容的本机 Docker Engine）、Docker Compose V2、Python 3；无需构建镜像或安装 Python 包。

## 一次启动，以后直接启停

在此目录执行：

```bash
./qbt.sh start
# 首次隐藏输入管理员密码两次；用户名 admin。
# 之后不再询问，也不覆盖在网页里修改过的账户或设置。
```

没有可执行权限的 ZIP 副本可用 `bash qbt.sh start`。不要使用 sudo。

| 命令 | 行为 |
| --- | --- |
| `./qbt.sh start` | 首次初始化并启动；以后复用固定镜像，应用 Compose 设置，等待网页就绪 |
| `./qbt.sh stop` | 优雅停止，最多等待 60 秒；保留容器、任务、配置和下载文件 |
| `./qbt.sh restart` | 停止再启动；容器已删除时可重新创建 |
| `./qbt.sh status` | 查看容器、网页绑定、实际数据目录、固定镜像 digest |
| `./qbt.sh logs` | 最近 100 行容器日志；不持续占用终端 |
| `./qbt.sh check` | 验证容器运行和网页响应；不验证管理员密码或 BT 入站可达性 |
| `./qbt.sh update` | 显式拉取官方 latest；有新 digest 才停机、备份配置并切换镜像 |
| `./qbt.sh init` | 只初始化本地配置，暂不启动 |
| `./qbt.sh --help` | 所有参数 |

密码不写进脚本、Compose 环境变量、命令行参数或 Git。首次只保存随机盐 + PBKDF2-HMAC-SHA512 摘要（100000 次，64 字节输出），之后由 qBittorrent 管理。新 Mac 第一次启动输入自己的密码；不提供通用默认密码。

自动化可用 `--password-stdin` 从受保护文件或密码管理器读取一行。不要把密码写入命令文本、shell history、CI 日志或共享目录。

## 网页与局域网

**默认网页端口为 1024**，首次可通过 `--port` 修改。

| 用途 | 地址 / 端口 |
| --- | --- |
| 本机网页 | `http://127.0.0.1:1024` |
| 局域网其他机器 | `http://这台Mac的局域网IPv4地址:1024` |
| 网页监听 | 默认 `0.0.0.0:1024`，发布到 Mac 的所有 IPv4 网卡 |
| BT 连接 | 6881 TCP + UDP；与网页端口独立 |
| 容器重启策略 | `unless-stopped`；Docker 启动后恢复之前运行的服务，手动 stop 后保持停止 |

在 macOS“系统设置 → 网络 → 当前连接 → 详细信息 → TCP/IP”查看局域网 IPv4；可在路由器为 Mac 配置 DHCP 地址保留。另一台机器需与 Mac 网络互通，Docker/macOS 防火墙需允许该端口；访客 Wi-Fi 的客户端隔离可能阻断访问。

```bash
# 首次安装示例：固定端口、固定网卡 IP
./qbt.sh start --port 8024 --bind 192.168.1.20

# 首次仅本机使用
./qbt.sh start --bind 127.0.0.1
```

保留管理员登录、CSRF 和 Host Header 校验；域名列表 `*` 允许局域网 IP/主机名访问。没有启用 localhost/子网免密，没有使用 privileged、host network 或 Docker socket 挂载。网页使用 HTTP，适合可信局域网；不要把管理端口转发到公网。BT 入站需要时可单独映射 6881 TCP/UDP；无入站映射通常仍可主动连接 peers，但此脚本不承诺外部可达。

Docker Desktop 和 Mac 需保持运行；Mac 睡眠时下载可能暂停。此脚本不修改系统休眠、登录启动或防火墙设置。

## 下载文件保存在 Mac 哪里

默认结构：

```text
~/Downloads/qBittorrent/                         -> /downloads
  complete/       下载完成的文件
  incomplete/     未完成的数据，完成后由应用移动

~/Library/Application Support/macos-setup/qbittorrent/
  settings.json   路径、端口、Docker context、镜像 digest
  config/                                       -> /config
    qBittorrent/   应用设置、加盐密码摘要、任务与恢复信息
  backups/        真正切换新版镜像之前的配置备份
  operation.lock  操作互斥文件；进程退出后内核自动释放锁
```

`/downloads/complete` 是**容器路径**，在网页设置中使用它；Mac Finder 对应 `~/Downloads/qBittorrent/complete`。不要在网页里填写 `/Users/...`，容器看不到未映射的 Mac 目录。下载目录和配置目录相互独立。采用当前用户 UID/GID；Mac 能直接读写下载结果。

建议下载文件放本地磁盘或稳定连接的外置磁盘，避免把活动下载、任务状态和密码摘要放入 Dropbox/iCloud/Git。源码目录可以同步，运行数据不随源码复制。

首次选择外置磁盘：

```bash
./qbt.sh start --downloads '/Volumes/Media/qBittorrent'
```

先挂载真实磁盘；脚本拒绝未挂载的 `/Volumes/磁盘名`，不会在内置硬盘悄悄创建同名路径。必要时在 Docker Desktop Settings → Resources → File sharing 允许所选目录。路径可有空格，使用引号；不支持符号链接路径。后续启动若目录丢失会报错，不会静默换成新空目录。

## 重跑、变更与恢复

每次从私有 `settings.json` 读取设置，不以源码所在目录决定下载位置。启动不拉取 latest，也不重置密码、下载路径或任务。初始固定的是 2026-09-12 核对的官方多架构 digest；ARM Mac 使用 `linux/arm64`，x86 Docker 使用 `linux/amd64`。同一 state 目录的启停互斥，命令失败返回非零，可以修复问题后再次 `start`。

首次会保存当前本机 Docker context，后续命令显式使用它，避免切换 context 后误操作另一套 Docker。远程 context 不支持。不要同时手工用另一套 Compose 参数操作相同的数据目录。首次中断且未产生容器时，再次启动可继续密码初始化；已有容器但应用配置丢失时会停止并要求恢复。

**修改端口或绑定地址**：先 stop，编辑 state 目录下 `settings.json` 的 `web_port` 或 `bind`，再 start。脚本令主机端口、容器端口、`WEBUI_PORT` 三者一致，避免 CSRF 端口问题。BT 端口修改 `bt_port`，同时用于 TCP/UDP 和 `TORRENTING_PORT`。已有设置时再次传入不同的首次参数会报错，防止误迁移。

**迁移下载目录**：先 stop，把整个下载目录（含 `complete` 和 `incomplete`）复制到新磁盘，校验文件后修改 `settings.json` 的 `downloads` 为新绝对路径，再 start 并在网页核对任务。容器内 `/downloads` 保持不变。确认恢复成功前保留原文件；脚本不自动搬动或删除下载数据。

**更新**：`update` 拉取失败不停止已有容器；digest 未变化时不做版本切换。确有新版时先 stop，使恢复信息落盘，然后备份整个 config 和旧 settings 到 `backups/时间/`，保存新 digest 并启动。下载文件独立保留。备份失败会中止；此时可能已经停止，修复后可 start 或重试 update。新版本仍可能有上游迁移变化，不能以测试替代自己的数据备份。

**回退**：先 stop；把当前 config 改名保留，再从对应 `backups/时间/` 恢复 config 和 settings.json，然后 start。旧镜像按 digest 拉取，不只回退镜像而混用新版配置。备份不包含实际下载文件；较早任务备份可能需要在网页重新校验已下载文件。

**备份或迁移 Mac**：停止后同时备份 state 和下载目录。新 Mac 的 `settings.json` 需要核对绝对路径、UID/GID、context、架构；通常重新 init，再在停止状态恢复应用 config 更直观。将备份当作含账户信息的私人数据管理。

停止和脚本没有“删除下载文件”操作；网页里选择“同时删除文件”仍会真的删除映射目录中的文件。删除脚本或容器也不等于备份，重要文件应另外备份。

## 验证与来源

```bash
python3 smoke-test.py
```

测试使用随机密码、临时目录、独立 Compose 项目和临时端口：实际下载自建 64 KiB 种子、校验 Mac 映射文件、拒绝匿名 API、验证改密后重复启动/停止/重启/重建容器保留账户与任务，并执行 update 查询和网页检查。测试只删除自己的临时容器和数据，不接触正式服务。

测试中的 web seed 在容器内部回环地址，需要仅对临时服务关闭 SSRF mitigation；下载完成立即恢复。正式配置保持应用默认的 SSRF mitigation。测试不添加公开种子或下载第三方内容，不测试路由器入站映射。Linux ARM/amd64 CI 与 Mac 上 Docker 的文件共享、局域网防火墙仍需在目标机器确认。

| 来源 | 用途 |
| --- | --- |
| [用户指定的 Docker Hub](https://hub.docker.com/r/linuxserver/qbittorrent) | LinuxServer 镜像说明 |
| [LinuxServer 官方文档](https://docs.linuxserver.io/images/docker-qbittorrent/) | 官方 registry `lscr.io`、ARM64、PUID/PGID、端口、目录映射、升级方式 |
| [qBittorrent 密码实现](https://github.com/qbittorrent/qBittorrent/blob/master/src/base/utils/password.cpp) | PBKDF2 摘要格式和参数 |
| [qBittorrent 首选项实现](https://github.com/qbittorrent/qBittorrent/blob/master/src/base/preferences.cpp) | WebUI 配置键 |
| [qBittorrent Web API](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-5.0)) | 登录、设置、任务验收；新版可能使用 204 和按端口命名的 session cookie |
| [Docker Compose services](https://docs.docker.com/reference/compose-file/services/) | bind mount、restart、端口与优雅停止 |

维护入口：`qbt.py` 的 `IMAGE`/`PIN`、`compose.yaml` 和 `smoke-test.py`。更改初始 digest、密码格式或挂载/端口契约后，必须再次运行真实镜像测试。运行 `update` 只改变本机私有 settings，不修改仓库的初始 digest。
