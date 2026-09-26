#!/usr/bin/env python3
"""Explain the remaining human steps using only this session's prepared packages."""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import tempfile

ROOT = Path(__file__).resolve().parents[1]
APPS = {
    'docker-desktop': ('Docker Desktop', 'Docker.app', '首次打开 Docker，按官方向导完成设置，等待 Docker 引擎启动。'),
    'google-chrome': ('Google Chrome', 'Google Chrome.app', '从“应用程序”打开 Chrome；按需登录，默认浏览器选择由你决定。'),
    'chatgpt': ('ChatGPT / Codex 桌面端', '镜像中的 ChatGPT.app 或 Codex.app', '从“应用程序”打开刚安装的应用，完成登录，并按需处理权限提示。'),
    'kiro': ('Kiro IDE', 'Kiro.app', '从“应用程序”打开 Kiro，完成登录和首次使用向导；IDE 与 Kiro CLI 分别初始化。'),
    'claude-desktop': ('Claude Desktop', 'Claude.app', '从“应用程序”打开 Claude 并登录；桌面端与 Claude Code CLI 分别完成首次登录。'),
}


def read_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def package_path(directory, record, prefix, extension):
    """Never turn an unrelated/stale report or an escaping filename into an open command."""
    name = record.get('filename') if isinstance(record, dict) else None
    if (not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', name)
            or not name.startswith(prefix) or not name.endswith(extension)):
        return None
    path = directory / name
    return path if path.is_file() and not path.is_symlink() else None


def instructions(run_dir, config_dir, home=None, root=ROOT):
    result = read_json(run_dir / 'result.json', {})
    if result.get('mode') != 'install':
        return ''
    home = (home or Path.home()).resolve()
    directory = home / 'Downloads/macos-setup'
    complete = result.get('status') == 'success'
    claude = result.get('with_claude') is True
    pending = list(dict.fromkeys(name for name in result.get('manual_steps', [])
                                if name in (*APPS, 'sogou-installer', 'kiro-cli-onboarding')
                                and (name != 'claude-desktop' or claude)))
    rows = read_json(run_dir / 'desktop-installers.json', [])
    packages = {row.get('component'): row for row in rows if isinstance(row, dict)} if isinstance(rows, list) else {}
    lines = []
    downloads = [name for name in pending if name != 'kiro-cli-onboarding']
    if downloads:
        lines += ['[MANUAL] 以下安装包已准备，仍需你手动完成安装：',
                  '下载完成不代表应用已安装。按下列顺序逐项操作；命令仅供复制，不会自动执行。',
                  '打开安装包文件夹：', '  ' + shlex.join(['open', str(directory)])]
        if not complete:
            lines += ['本轮安装尚未全部完成。可先安装下面已有的包，再修复上方错误并重跑原命令。']
        for number, name in enumerate(downloads, 1):
            if name == 'sogou-installer':
                record = read_json(run_dir / 'sogou-installer.json', {})
                path = package_path(directory, record, 'SogouInput-', '.zip')
                title = '搜狗输入法'
            else:
                path = package_path(directory, packages.get(name), name + '-', '.dmg')
                title = APPS[name][0]
            lines += ['', f'{number}. {title}']
            if path:
                lines += ['   安装包：' + str(path), '   打开命令：' + shlex.join(['open', str(path)])]
            else:
                lines += ['   本轮记录无法定位安装包；请检查上方下载文件夹，或重跑原命令重新准备。']
            if name == 'sogou-installer':
                lines += ['   ① 双击 ZIP 解压，再打开解压目录中的官方安装器，按向导完成安装。',
                          '   ② 打开 系统设置 → 键盘 → 文字输入 → 编辑，添加搜狗输入法。',
                          '   ③ 在菜单栏切换到搜狗，在文本编辑器里实际测试中文输入。']
            else:
                lines += ['   ① 打开 DMG，将 ' + APPS[name][1] + ' 拖入 Applications（应用程序），等待复制完成。',
                          '   ② 弹出 Finder 侧栏中的安装磁盘，从“应用程序”打开已复制的应用。',
                          '   ③ ' + APPS[name][2]]
        lines += ['', '如出现同名应用的替换提示，先正常退出旧应用，再按你的更新意愿确认。']
    if complete:
        lines += ['', '[MANUAL] 首次使用与登录（已完成的项目可跳过）：',
                  '• 新开一个 iTerm2 窗口，让 PATH 和 shell 配置生效。按需在 Profiles 中选择 Clean Setup。',
                  '• Codex CLI：在新终端运行 codex，按提示完成登录。']
        if claude:
            lines += ['• Claude Code CLI：在新终端运行 claude，按提示完成登录。']
        if 'docker-desktop' not in downloads:
            lines += ['• Docker Desktop：运行 open -a Docker，完成首次启动设置并等待引擎启动。']
    if complete or 'kiro-cli-onboarding' in pending:
        lines += ['• Kiro CLI：在新终端运行 kiro-cli launch，按官方向导完成登录和终端集成。',
                  '  如果提示 command not found，运行 open -a "Kiro CLI" 完成 onboarding，再新开终端重试。',
                  '  需要诊断时运行 kiro-cli doctor --all；系统权限由你按实际需要确认。']
    if complete:
        command = ['/bin/bash', str(root / 'setup.sh'), '--verify']
        if claude:
            command.append('--with-claude')
        if result.get('desktop_mode') == 'managed':
            command.append('--managed-desktop')
        if config_dir.resolve() != (root / 'config').resolve():
            command += ['--config-dir', str(config_dir.resolve())]
        command += ['--log-dir', str(run_dir.parent)]
        lines += ['', '[CHECK] 完成上述安装和首次启动后，在新终端复制执行：',
                  '  ' + shlex.join(command),
                  '此命令检查实际安装；只有 DMG、尚未安装应用时会报缺失。保留安装时的自定义目录环境变量。',
                  'Docker 引擎启动后，再单独检查容器运行：',
                  '  ' + shlex.join(['/bin/bash', str(root / 'setup.sh'), '--docker-smoke', '--log-dir', str(run_dir.parent)]),
                  '搜狗输入切换、GUI 登录和系统授权仍需你实际确认。' if 'sogou-installer' in pending
                  else 'GUI 登录和系统授权仍需你实际确认。']
    return '\n'.join(lines).strip() + '\n' if lines else ''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-dir', type=Path, required=True)
    parser.add_argument('--config-dir', type=Path, required=True)
    args = parser.parse_args()
    run_dir = args.run_dir.resolve()
    text = instructions(run_dir, args.config_dir)
    if not text:
        return
    destination = run_dir / 'manual-steps.txt'
    fd, temporary = tempfile.mkstemp(prefix='.manual-', dir=run_dir)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        os.replace(temporary, destination)
    finally:
        Path(temporary).unlink(missing_ok=True)
    print(text, end='')
    print('\n操作说明已保存：' + str(destination))


if __name__ == '__main__':
    main()
