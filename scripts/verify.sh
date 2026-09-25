#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=setup.sh
source "$ROOT/setup.sh"
activate_paths
configure_downloads
check_git_configuration

while IFS= read -r -u 3 package; do
  [[ -n "$package" ]] || continue
  installed_formula_ref "$package" >/dev/null
  probe_formula "$package"
done 3<"$ROOT/config/formulae.txt"

while IFS=$'\t' read -r -u 3 package app; do
  [[ -n "$package" ]] || continue
  app_healthy "$app"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$(app_path "$app")/Contents/Info.plist"
done 3<"$ROOT/config/casks.tsv"

for executable in git git-lfs gh go node npm python3 uv rg fd bat fzf autojump zoxide jq yq tmux tree delta tig wget htop shellcheck shfmt ffmpeg magick glow pop gum crush claude codex kiro-cli docker; do
  command -v "$executable"
done
git --version
git lfs version
gh --version
go version
node --version
npm --version
python3 --version
uv --version
claude --version
codex --version
kiro-cli --version
python3 "$ROOT/scripts/kiro-shell.py" --verify --app "$(app_path 'Kiro CLI.app')"
docker --version
/Applications/Docker.app/Contents/Resources/cli-plugins/docker-compose version
/Applications/Docker.app/Contents/Resources/cli-plugins/docker-buildx version
python3 "$ROOT/scripts/configure.py" --verify
verify_editor
zsh -n "$HOME/.config/macos-setup/env.zsh"
zsh -n "$HOME/.config/macos-setup/shell.zsh"
zsh -lic 'command -v claude && command -v codex && command -v go && command -v docker && command -v code && command -v kiro-cli'
zsh -lic '(( $+functions[fig_preexec] && $+functions[fig_precmd] ))'
python3 "$ROOT/scripts/runtime-smoke.py"
python3 "$ROOT/scripts/inventory.py"
echo 'Installation verified. Docker engine readiness is checked separately by --docker-smoke.'
