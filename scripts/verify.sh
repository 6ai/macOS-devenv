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
  if [[ "$package" == claude-desktop && "$WITH_CLAUDE" != true ]]; then continue; fi
  if [[ "${SETUP_ALLOW_PREPARED_DESKTOPS:-}" == 1 ]] && manual_desktop "$package" && ! app_healthy "$app"; then
    python3 "$ROOT/scripts/desktop.py" "$package" --verify-prepared
    echo "Prepared for manual installation: $app (not installed or not yet healthy)."
    continue
  fi
  app_healthy "$app"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$(app_path "$app")/Contents/Info.plist"
done 3<"$ROOT/config/casks.tsv"

for executable in git git-lfs gh go node npm python3 uv rg fd bat fzf autojump zoxide jq yq tmux tree delta tig wget htop shellcheck shfmt ffmpeg magick glow pop gum crush claude codex; do
  if [[ "$executable" == claude && "$WITH_CLAUDE" != true ]]; then continue; fi
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
if [[ "$WITH_CLAUDE" == true ]]; then claude --version; fi
codex --version
if agent_healthy kiro-cli; then
  kiro-cli --version
  zsh -lic 'command -v kiro-cli'
elif [[ "${SETUP_ALLOW_PREPARED_DESKTOPS:-}" == 1 ]]; then
  echo 'Kiro CLI app is installed; complete official onboarding to expose its terminal commands.'
else
  fail 'Complete Kiro CLI official onboarding, then rerun verification.'
fi
if [[ "$DESKTOP_MODE" == managed ]]; then
  python3 "$ROOT/scripts/kiro-shell.py" --verify --app "$(app_path 'Kiro CLI.app')"
  zsh -lic '(( $+functions[fig_preexec] && $+functions[fig_precmd] ))'
fi
if app_healthy Docker.app; then
  docker --version
  /Applications/Docker.app/Contents/Resources/cli-plugins/docker-compose version
  /Applications/Docker.app/Contents/Resources/cli-plugins/docker-buildx version
  zsh -lic 'command -v docker'
fi
python3 "$ROOT/scripts/configure.py" --verify
verify_editor
zsh -n "$HOME/.config/macos-setup/env.zsh"
zsh -n "$HOME/.config/macos-setup/shell.zsh"
if [[ "$WITH_CLAUDE" == true ]]; then zsh -lic 'command -v claude'; fi
zsh -lic 'command -v codex && command -v go && command -v code'
python3 "$ROOT/scripts/runtime-smoke.py"
python3 "$ROOT/scripts/inventory.py"
echo 'Selected installation/preparation scope verified. Manual desktop installs and first launch remain separate.'
echo 'Docker engine readiness is checked separately by --docker-smoke.'
