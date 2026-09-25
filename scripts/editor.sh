#!/bin/bash
# shellcheck disable=SC2034 # STEP_ACTION is consumed by setup.sh's session logger.
# Functions are sourced by setup.sh and the verifier; no work at source time.
omz_path() { printf '%s\n' "${ZSH:-$HOME/.oh-my-zsh}"; }

omz_healthy() {
  local directory=$1 file
  for file in oh-my-zsh.sh lib/git.zsh lib/cli.zsh themes/robbyrussell.zsh-theme plugins/git/git.plugin.zsh; do
    [[ -r "$directory/$file" ]] || return 1
  done
}

ensure_ohmyzsh() {
  local directory installer remote
  directory=$(omz_path)
  if omz_healthy "$directory"; then
    STEP_ACTION=skipped
    if [[ "$UPDATE" == true ]]; then
      remote=$(git -C "$directory" remote get-url origin)
      [[ "$remote" == https://github.com/ohmyzsh/ohmyzsh.git ]] || fail 'Update this Oh My Zsh fork with its original manager.'
      [[ -z $(git -C "$directory" status --porcelain) ]] || fail 'Oh My Zsh has local changes; preserve/resolve them before --update.'
      git -C "$directory" pull --ff-only
      STEP_ACTION=update-checked
    fi
  elif [[ -e "$directory" || -L "$directory" ]]; then
    fail 'Existing Oh My Zsh directory is incomplete. Repair the original installation; custom themes are preserved.'
  else
    installer=$(mktemp)
    download_installer ohmyzsh "$installer"
    ZSH="$directory" KEEP_ZSHRC=yes CHSH=no RUNZSH=no /bin/sh "$installer" --unattended
    rm -f "$installer"
    STEP_ACTION=installed
  fi
  omz_healthy "$directory" || fail 'Oh My Zsh installation is incomplete.'
}

code_cli() {
  local app
  app=$(app_path 'Visual Studio Code.app')
  "$app/Contents/Resources/app/bin/code" "$@"
}

extension_installed() {
  local extension=$1 installed
  installed=$(code_cli --list-extensions) || fail 'Unable to enumerate VS Code extensions.'
  printf '%s\n' "$installed" | tr '[:upper:]' '[:lower:]' | grep -Fx "$extension" >/dev/null
}

ensure_extension() {
  local extension=$1
  if extension_installed "$extension"; then
    STEP_ACTION=skipped
    if [[ "$UPDATE" == true ]]; then
      code_cli --install-extension "$extension" --force
      STEP_ACTION=update-checked
    fi
  else
    code_cli --install-extension "$extension"
    STEP_ACTION=installed
  fi
  extension_installed "$extension" || fail "VS Code extension is missing: $extension"
}

install_extensions() {
  local extension
  while IFS= read -r -u 3 extension; do
    [[ -n "$extension" ]] || continue
    step_run "vscode:$extension" ensure_extension "$extension"
  done 3<"$ROOT/config/vscode-extensions.txt"
}

verify_editor() {
  local extension
  omz_healthy "$(omz_path)" || fail 'Oh My Zsh is missing/incomplete.'
  while IFS= read -r -u 3 extension; do
    [[ -n "$extension" ]] || continue
    extension_installed "$extension" || fail "VS Code extension is missing: $extension"
  done 3<"$ROOT/config/vscode-extensions.txt"
}
