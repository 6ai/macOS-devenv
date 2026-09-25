#!/usr/bin/env python3
"""Install public templates; preserve personal AI settings and back up shell edits."""

import argparse
import json
import os
from pathlib import Path
import shutil
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
SOURCE_LINE = '[ -f "$HOME/.config/macos-setup/shell.zsh" ] && source "$HOME/.config/macos-setup/shell.zsh"'
ENV_SOURCE_LINE = '[ -f "$HOME/.config/macos-setup/env.zsh" ] && source "$HOME/.config/macos-setup/env.zsh"'
PROFILE_PATH = Path('Library/Application Support/iTerm2/DynamicProfiles/clean-setup.json')
PROFILE_BACKUP_PATH = PROFILE_PATH.parent.parent / 'macos-setup-backups'
VSCODE_PATH = Path('Library/Application Support/Code/User/settings.json')
KIRO_PATH = Path('.kiro/settings/permissions.yaml')


def write(path, content, preserve=False, backup_dir=None):
    if path.is_symlink():
        raise ValueError(f'Refusing to replace symlink: {path}')
    if path.exists() and (preserve or path.read_bytes() == content):
        print(f'Preserved: {path}')
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    staging = backup_dir or path.parent
    if staging.is_symlink():
        raise ValueError(f'Refusing symlink staging directory: {staging}')
    staging.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.exists():
        fd, backup = tempfile.mkstemp(prefix=path.name + '.backup-', dir=staging)
        os.close(fd)
        shutil.copy2(path, backup)
    fd, temporary = tempfile.mkstemp(prefix='.' + path.name, dir=staging)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f'Configured: {path}')


def migrate_profile_backups(home):
    """iTerm2 reads every file in DynamicProfiles, including old backup copies."""
    profile = home / PROFILE_PATH
    destination = home / PROFILE_BACKUP_PATH
    if destination.is_symlink():
        raise ValueError(f'Refusing symlink backup directory: {destination}')
    legacy = sorted(profile.parent.glob(profile.name + '.backup-*'))
    temporary_prefix = '.' + profile.name
    legacy += sorted(path for path in profile.parent.glob(temporary_prefix + '*')
                     if len(path.name) == len(temporary_prefix) + 8
                     and set(path.name[len(temporary_prefix):]) <= set('abcdefghijklmnopqrstuvwxyz0123456789_'))
    for path in legacy:
        if not path.is_file() or path.is_symlink() or (destination / path.name).exists():
            raise ValueError(f'Refusing unsafe or colliding legacy profile backup: {path}')
    if legacy:
        destination.mkdir(mode=0o700, parents=True, exist_ok=True)
        for path in legacy:
            path.rename(destination / path.name)
            print(f'Relocated iTerm2 backup: {path.name}')


def validate(claude, codex, profile):
    if not isinstance(json.loads(claude), dict):
        raise ValueError('Claude settings must be a JSON object')
    tomllib.loads(codex)
    data = json.loads(profile)
    if not isinstance(data, dict) or len(data.get('Profiles', [])) != 1:
        raise ValueError('Expected one iTerm2 dynamic profile')
    item = data['Profiles'][0]
    if not item.get('Guid') or not item.get('Name') or not item.get('Keyboard Map'):
        raise ValueError('iTerm2 profile needs Guid, Name and Keyboard Map')


def configure(home, config_dir, codex_home=None, claude_home=None, shell_home=None, with_claude=False):
    # Validate selected inputs and preserved AI files before making any changes.
    claude = (config_dir / 'claude-settings.json').read_text() if with_claude else '{}'
    codex = (config_dir / 'codex-config.toml').read_text()
    profile = (config_dir / 'iterm2-profile.json').read_text()
    shell = (config_dir / 'shell.zsh').read_bytes()
    environment = (config_dir / 'env.zsh').read_bytes()
    vscode = (config_dir / 'vscode-settings.json').read_bytes()
    kiro = (config_dir / 'kiro-permissions.json').read_bytes()
    validate_kiro(kiro)
    if not isinstance(json.loads(vscode), dict):
        raise ValueError('VS Code defaults must be a JSON object')
    validate(claude, codex, profile)
    claude_path = (claude_home or home / '.claude') / 'settings.json'
    codex_path = (codex_home or home / '.codex') / 'config.toml'
    validate(
        claude_path.read_text() if with_claude and claude_path.exists() else claude,
        codex_path.read_text() if codex_path.exists() else codex,
        profile,
    )
    shell_home = shell_home or home
    paths = ([claude_path] if with_claude else []) + [codex_path, home / PROFILE_PATH,
             home / '.config/macos-setup/shell.zsh', home / '.config/macos-setup/env.zsh',
             home / VSCODE_PATH, home / KIRO_PATH, shell_home / '.zshrc', shell_home / '.zprofile']
    for path in paths:
        if path.is_symlink():
            raise ValueError(f'Refusing to replace symlink: {path}')
    for path in (home / '.kiro', home / '.kiro/settings'):
        if path.is_symlink():
            raise ValueError(f'Refusing to configure Kiro through symlink: {path}')
    if (home / KIRO_PATH).exists():
        kiro_policy_status(home)
    migrate_profile_backups(home)
    if with_claude:
        write(claude_path, claude.encode(), preserve=True)
    write(codex_path, codex.encode(), preserve=True)
    write(home / PROFILE_PATH, profile.encode(), backup_dir=home / PROFILE_BACKUP_PATH)
    write(home / '.config/macos-setup/shell.zsh', shell)
    write(home / '.config/macos-setup/env.zsh', environment)
    # Existing VS Code settings may be JSONC. Preserve their bytes, including comments.
    write(home / VSCODE_PATH, vscode, preserve=True)
    # JSON is valid YAML. Personal YAML policies remain byte-for-byte intact.
    write(home / KIRO_PATH, kiro, preserve=True)
    report_kiro(home)
    for name in ('.zshrc', '.zprofile'):
        path = shell_home / name
        content = path.read_text() if path.exists() else ''
        line = ENV_SOURCE_LINE if name == '.zprofile' else SOURCE_LINE
        if name == '.zprofile' and SOURCE_LINE in content.splitlines():
            rows = []
            for row in content.splitlines():
                row = ENV_SOURCE_LINE if row == SOURCE_LINE else row
                if row != ENV_SOURCE_LINE or row not in rows:
                    rows.append(row)
            content = '\n'.join(rows) + '\n'
        if line not in content.splitlines():
            content = content.rstrip('\n') + '\n\n' + line + '\n'
        write(path, content.encode())


def validate_kiro(content):
    data = json.loads(content)
    capabilities = {'all', 'builtin', 'filesystem', 'fs_read', 'fs_write', 'shell', 'web_fetch',
                    'web_search', 'mcp', 'subagent', 'skill', 'power', 'context', 'diagnostics', 'sandbox_network'}
    if not isinstance(data, dict) or set(data) != {'rules'} or not isinstance(data['rules'], list) or not data['rules']:
        raise ValueError('Kiro permissions must contain a nonempty rules array')
    for rule in data['rules']:
        if (not isinstance(rule, dict) or not {'capability', 'effect'} <= rule.keys()
                or not rule.keys() <= {'capability', 'effect', 'match', 'exclude'}
                or not isinstance(rule['capability'], str) or rule['capability'] not in capabilities
                or not isinstance(rule['effect'], str) or rule['effect'] not in {'ask', 'deny', 'allow'}):
            raise ValueError('Invalid Kiro permission rule')
        for key in ('match', 'exclude'):
            if key in rule and (not isinstance(rule[key], list) or not rule[key]
                                or not all(isinstance(value, str) and value for value in rule[key])):
                raise ValueError('Kiro match/exclude must be nonempty arrays of patterns')


def kiro_policy_status(home):
    content = (home / KIRO_PATH).read_bytes()
    if not content.strip():
        raise ValueError('Kiro permission file is empty; review it before using the agent')
    return ('default-ask' if content == (ROOT / 'config/kiro-permissions.json').read_bytes()
            else 'custom-unreviewed')


def report_kiro(home):
    if kiro_policy_status(home) == 'default-ask':
        print('Kiro permission template: all capabilities ask (requires IDE 1.x; approve inside Kiro).')
    else:
        print('Kiro custom policy preserved, not audited by setup. Review effective permissions inside Kiro before use.')


def verify(home, codex_home=None, claude_home=None, shell_home=None, with_claude=False):
    validate(((claude_home or home / '.claude') / 'settings.json').read_text() if with_claude else '{}',
             ((codex_home or home / '.codex') / 'config.toml').read_text(),
             (home / PROFILE_PATH).read_text())
    if list((home / PROFILE_PATH).parent.glob('clean-setup.json.backup-*')):
        raise ValueError('iTerm2 backup files remain in DynamicProfiles; rerun --configure-only to relocate them')
    if not (home / '.config/macos-setup/shell.zsh').is_file():
        raise ValueError('Missing shell configuration')
    if not (home / '.config/macos-setup/env.zsh').is_file() or not (home / VSCODE_PATH).is_file():
        raise ValueError('Missing environment or VS Code configuration')
    if any(path.is_symlink() for path in (home / '.kiro', home / '.kiro/settings', home / KIRO_PATH)):
        raise ValueError('Kiro permission file must not be a symlink')
    report_kiro(home)
    for name in ('.zshrc', '.zprofile'):
        line = ENV_SOURCE_LINE if name == '.zprofile' else SOURCE_LINE
        if ((shell_home or home) / name).read_text().splitlines().count(line) != 1:
            raise ValueError(f'{name}: expected exactly one configuration source line')
    print('Configuration files verified.')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config-dir', type=Path, default=ROOT / 'config')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--with-claude', action='store_true', default=os.environ.get('SETUP_WITH_CLAUDE') == 'true')
    args = parser.parse_args()
    # Resolve overrides only at the CLI boundary; tests that pass a temporary home stay isolated.
    directories = {'with_claude': args.with_claude}
    for variable, key in [('CODEX_HOME', 'codex_home'), ('CLAUDE_CONFIG_DIR', 'claude_home'),
                          ('ZDOTDIR', 'shell_home')]:
        if variable == 'CLAUDE_CONFIG_DIR' and not args.with_claude:
            continue
        if os.environ.get(variable):
            directory = Path(os.environ[variable]).expanduser()
            if not directory.is_absolute():
                raise ValueError(f'{variable} must be an absolute path')
            directories[key] = directory
    if args.verify:
        verify(Path.home(), **directories)
    else:
        configure(Path.home(), args.config_dir, **directories)


if __name__ == '__main__':
    main()
