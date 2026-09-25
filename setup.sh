#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODE=install
UPDATE=false
WITH_SOGOU=false
CONFIG_DIR="$ROOT/config"
LOG_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/macos-setup"
# shellcheck source=scripts/session.sh
source "$ROOT/scripts/session.sh"
# shellcheck source=scripts/editor.sh
source "$ROOT/scripts/editor.sh"

usage() {
  cat <<'HELP'
Usage: ./setup.sh [MODE] [--update] [--with-sogou] [--config-dir DIR] [--log-dir DIR]
Default: install missing tools, repair broken managed installs, preserve healthy tools.
AI apps/CLIs: check local installations only; install/update separately with official installers.
--plan            Print the plan; no writes or downloads.
--update          Explicitly update managed tools, excluding AI prerequisites (install mode only).
--check-updates   Report available versions and configuration drift; never upgrade.
--with-sogou      Optional extension: prepare official Sogou ZIP for manual installation.
--configure-only  Apply configuration only (Python 3.11+).
--verify          Check packages, executables, applications and configuration.
--diagnose        Record environment and official-source network reachability only.
--docker-smoke    Build and run a linux/amd64 container on a running Docker engine.
--config-dir DIR  Use seven external configuration templates (copy config/ first).
--log-dir DIR     Store private run logs here instead of ~/.local/state/macos-setup.
--help            Show this help.
Failures return nonzero. Fix the cause and rerun the same command; healthy tools are skipped.
HELP
}

fail() {
  ui_print error "[FAILED] ERROR: $*" >&2
  exit 1
}

activate_paths() {
  local executable
  for executable in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$executable" ]]; then
      eval "$("$executable" shellenv)"
      break
    fi
  done
  export PATH="$HOME/.local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
}

check_install_target() {
  [[ $(uname -m) == arm64 ]] || fail 'Full installation requires Apple Silicon; Homebrew no longer publishes new Intel macOS bottles.'
  local version
  version=$(sw_vers -productVersion)
  [[ "${version%%.*}" -ge 26 ]] || fail 'Full installation targets macOS Tahoe 26 or newer.'
  [[ $(id -u) -ne 0 ]] || fail 'Run as your normal user; Homebrew requests sudo when needed.'
  echo "Target: Apple Silicon, macOS $version"
}

installer_url() {
  source_url "$1" installer
}

source_url() {
  awk -F '\t' -v component="$1" -v kind="$2" '$1 == component && $2 == kind { print $3; found=1 } END { if (!found) exit 1 }' "$ROOT/config/sources.tsv"
}

download_installer() {
  local component=$1 destination=$2 url
  url=$(installer_url "$component")
  curl --config "$ROOT/config/download.curlrc" --fail --show-error --location --retry 3 --connect-timeout 15 --max-time 180 "$url" -o "$destination.part"
  mv "$destination.part" "$destination"
  if [[ -n "$RUN_DIR" ]]; then
    printf '%s\t%s\n' "$component" "$(shasum -a 256 "$destination" | awk '{print $1}')" >>"$RUN_DIR/downloads.tsv"
  fi
}

configure_downloads() {
  if [[ -z "${HOMEBREW_CURLRC:-}" ]]; then
    export HOMEBREW_CURLRC="$ROOT/config/download.curlrc"
    echo 'Homebrew downloads: HTTP/1.1, connect timeout 20s, stalled transfer timeout 60s, attempt limit 30min.'
  elif [[ "$HOMEBREW_CURLRC" != "$ROOT/config/download.curlrc" ]]; then
    echo 'Preserving your HOMEBREW_CURLRC; its download policy takes precedence over setup defaults.'
  fi
}

run_package_installer() (
  # Log/config privacy must not change permissions created by system installers.
  # A subshell restores the caller's mask even when the installer fails.
  umask 022
  # Homebrew can select a different Git from the caller's PATH. Recheck before
  # each operation, including taps added by a later formula installation.
  if [[ "$1" == brew ]]; then
    local repairing_git=false
    if [[ "${2:-} ${3:-} ${4:-}" == 'reinstall --formula homebrew/core/git' ]]; then repairing_git=true; fi
    check_git_configuration "$repairing_git"
  fi
  "$@"
)

bootstrap() {
  local installer newly_installed=false
  configure_downloads
  # Setup already has an explicit plan/update boundary; Homebrew 6 asks by default.
  unset HOMEBREW_ASK
  export HOMEBREW_NO_ASK=1
  echo 'Homebrew: official package names; confirmation previews disabled for this setup process.'
  echo 'Unrelated untrusted-tap warnings may still appear. They are not installation failures; check the final [OK]/[FAILED] result.'
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install
    fail 'Finish the Apple Command Line Tools installer, then rerun ./setup.sh.'
  fi
  if ! command -v brew >/dev/null; then
    installer=$(mktemp)
    download_installer homebrew "$installer"
    run_package_installer /bin/bash "$installer"
    rm -f "$installer"
    activate_paths
    newly_installed=true
    STEP_ACTION=installed
  else
    STEP_ACTION=skipped
  fi
  if [[ "$newly_installed" == true || "$UPDATE" == true ]]; then
    run_package_installer brew update
    if [[ "$newly_installed" != true ]]; then STEP_ACTION=update-checked; fi
  fi
  export HOMEBREW_NO_AUTO_UPDATE=1
}

formula_command() {
  local package=${1##*/}
  case "$package" in
    python) echo python3 ;;
    ripgrep) echo rg ;;
    git-delta) echo delta ;;
    imagemagick) echo magick ;;
    *) echo "$package" ;;
  esac
}

formula_ref() {
  case "$1" in
    */*) echo "$1" ;;
    *) echo "homebrew/core/$1" ;;
  esac
}

installed_formula_ref() {
  local requested
  requested=$(formula_ref "$1")
  if brew list --formula "$requested" >/dev/null 2>&1; then
    echo "$requested"
  elif [[ "$requested" == charmbracelet/tap/* ]] && brew list --formula "homebrew/core/${1##*/}" >/dev/null 2>&1; then
    # Keep an existing core installation on its original update/repair channel.
    echo "homebrew/core/${1##*/}"
  else
    return 1
  fi
}

probe_formula() {
  local package=${1##*/} executable argument=--version
  executable=$(formula_command "$package")
  case "$package" in
    git) executable="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/git/bin/git" ;;
    go | git-lfs) argument=version ;;
    tmux) argument=-V ;;
    ffmpeg | imagemagick) argument=-version ;;
  esac
  "$executable" "$argument" >/dev/null 2>&1 || return 1
  if [[ "$package" == node ]]; then
    npm --version >/dev/null 2>&1 || return 1
  fi
}

ensure_formula() {
  local package=$1 reference
  if reference=$(installed_formula_ref "$package"); then
    if ! probe_formula "$package"; then
      warn "Managed formula $package failed its executable check; reinstalling."
      run_package_installer brew reinstall --formula "$reference"
      STEP_ACTION=repaired
    elif [[ "$UPDATE" == true ]]; then
      run_package_installer brew upgrade --formula "$reference"
      STEP_ACTION=update-checked
    else
      STEP_ACTION=skipped
    fi
  else
    run_package_installer brew install --formula "$(formula_ref "$package")"
    STEP_ACTION=installed
  fi
  hash -r
  probe_formula "$package" || fail "Installed formula is not runnable: $package"
  # A working binary can still have unreadable configuration; reinstalling it
  # does not repair personal/system config permissions.
  if [[ "$package" == git ]]; then check_git_configuration; fi
  if [[ "$package" == git-lfs ]]; then ensure_git_lfs_filters; fi
}

check_git_configuration() {
  local code executable prefix=${HOMEBREW_PREFIX:-/opt/homebrew} repairing_git=${1:-false}
  local candidates=(git)
  # The Homebrew Git shim prefers prefix/bin/git independently of PATH.
  for executable in "$prefix/bin/git" "$prefix/opt/git/bin/git"; do
    if [[ -x "$executable" ]]; then candidates+=("$executable"); fi
  done
  if [[ -n "${HOMEBREW_GIT_PATH:-}" ]]; then
    candidates+=("$HOMEBREW_GIT_PATH")
  fi
  # Parse the effective config, including includes, without logging its values.
  for executable in "${candidates[@]}"; do
    # Only the Git repair path may skip a non-runnable binary. Normal checks
    # must retain every config error (even --version can fail on bad includes).
    if [[ "$repairing_git" == true ]] && ! "$executable" --version >/dev/null 2>&1; then continue; fi
    if "$executable" config --list >/dev/null; then
      continue
    else
      code=$?
    fi
    ui_print error "[FAILED] Git configuration check failed using $executable. Repair the file named above, then rerun the same setup command." >&2
    ui_print info '[INFO] For Permission denied, inspect the exact path and parent directories with ls -lde. See README: Git configuration access.' >&2
    return "$code"
  done
  return 0
}

ensure_git_lfs_filters() {
  local key expected current code missing=false
  check_git_configuration
  for key in clean smudge process required; do
    case "$key" in
      clean | smudge) expected="git-lfs $key -- %f" ;;
      process) expected='git-lfs filter-process' ;;
      required) expected=true ;;
    esac
    if current=$(git config --global --get "filter.lfs.$key"); then
      [[ "$current" == "$expected" ]] || fail "Custom Git LFS filter.lfs.$key found; review it before initializing Git LFS."
    else
      code=$?
      [[ "$code" == 1 ]] || return "$code"
      missing=true
    fi
  done
  if [[ "$missing" == true ]]; then git lfs install --skip-repo; fi
}

bundle_healthy() {
  local path=$1 executable
  [[ -d "$path" ]] || return 1
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$path/Contents/Info.plist" 2>/dev/null) || return 1
  [[ -x "$path/Contents/MacOS/$executable" ]] || return 1
}

bundle_identifier() { /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null; }
bundle_version() { /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$1/Contents/Info.plist" 2>/dev/null; }

kiro_bundle_healthy() {
  local path=$1 version
  bundle_healthy "$path" || return 1
  [[ $(bundle_identifier "$path") == dev.kiro.desktop ]] || return 1
  version=$(bundle_version "$path") || return 1
  [[ "$version" =~ ^[1-9][0-9]*\. ]] || return 1
}

kiro_cli_bundle_healthy() {
  local directory=$1 executable
  bundle_healthy "$directory" || return 1
  [[ $(bundle_identifier "$directory") == com.amazon.codewhisperer ]] || return 1
  for executable in kiro-cli kiro-cli-chat kiro-cli-term; do
    "$directory/Contents/MacOS/$executable" --version >/dev/null 2>&1 || return 1
  done
}

app_path() {
  local app=$1 candidate
  if [[ "$app" == Kiro.app ]]; then
    for candidate in /Applications/Kiro.app "$HOME/Applications/Kiro.app"; do
      if kiro_bundle_healthy "$candidate"; then
        printf '%s\n' "$candidate"
        return
      fi
    done
  fi
  if [[ "$app" == 'Kiro CLI.app' ]]; then
    for candidate in '/Applications/Kiro CLI.app' "$HOME/Applications/Kiro CLI.app"; do
      if kiro_cli_bundle_healthy "$candidate"; then
        printf '%s\n' "$candidate"
        return
      fi
    done
  fi
  if [[ "$app" == ChatGPT.app ]]; then
    for candidate in /Applications/ChatGPT.app "$HOME/Applications/ChatGPT.app" /Applications/Codex.app "$HOME/Applications/Codex.app"; do
      if bundle_healthy "$candidate" && [[ $(bundle_identifier "$candidate") == com.openai.codex ]]; then
        printf '%s\n' "$candidate"
        return
      fi
    done
  elif [[ "$app" == 'Google Chrome.app' || "$app" == 'Visual Studio Code.app' || "$app" == Kiro.app || "$app" == 'Kiro CLI.app' ]] && ! bundle_healthy "/Applications/$app" && bundle_healthy "$HOME/Applications/$app"; then
    printf '%s\n' "$HOME/Applications/$app"
    return
  fi
  printf '%s\n' "/Applications/$app"
}

app_healthy() {
  local app=$1
  bundle_healthy "$(app_path "$app")" || return 1
  if [[ "$app" == ChatGPT.app ]]; then
    [[ $(bundle_identifier "$(app_path "$app")") == com.openai.codex ]] || return 1
  fi
  if [[ "$app" == Kiro.app ]]; then
    kiro_bundle_healthy "$(app_path "$app")" || return 1
  fi
  if [[ "$app" == 'Kiro CLI.app' ]]; then
    kiro_cli_bundle_healthy "$(app_path "$app")" || return 1
  fi
  if [[ "$app" == Docker.app ]]; then
    /Applications/Docker.app/Contents/Resources/bin/docker --version >/dev/null 2>&1 || return 1
    /Applications/Docker.app/Contents/Resources/cli-plugins/docker-compose version >/dev/null 2>&1 || return 1
    /Applications/Docker.app/Contents/Resources/cli-plugins/docker-buildx version >/dev/null 2>&1 || return 1
  fi
}

ensure_cask() {
  local package=$1 app=$2
  # These vendor-managed tools are prerequisites, even if brew has an old receipt.
  case "$package" in
    chatgpt | kiro | kiro-cli)
      check_external_app "$package" "$app"
      return
      ;;
  esac
  if [[ $(app_path "$app") != "/Applications/$app" ]]; then
    app_healthy "$app" || fail "$app is incompatible or incomplete; update it with its original installer."
    echo "Preserving existing $app at its original location; use its own updater."
    STEP_ACTION=preserved
    return
  fi
  if brew list --cask "homebrew/cask/$package" >/dev/null 2>&1; then
    if ! app_healthy "$app"; then
      warn "Managed application $app is incomplete or incompatible; reinstalling."
      run_package_installer brew reinstall --cask "homebrew/cask/$package"
      STEP_ACTION=repaired
    elif [[ "$UPDATE" == true ]]; then
      run_package_installer brew upgrade --cask "homebrew/cask/$package"
      STEP_ACTION=update-checked
    else
      STEP_ACTION=skipped
    fi
  elif app_healthy "$app"; then
    echo "Preserving $app from its original installer; use the app's own updater."
    STEP_ACTION=preserved
  elif [[ -e "/Applications/$app" || -e "$HOME/Applications/$app" ]]; then
    fail "Unmanaged app is incomplete or incompatible: $app. Repair it with its original installer first."
  else
    run_package_installer brew install --cask "homebrew/cask/$package"
    STEP_ACTION=installed
  fi
  app_healthy "$app" || fail "Application bundle is incomplete: $app"
}

install_packages() {
  local package app
  while IFS= read -r -u 3 package; do
    [[ -n "$package" ]] || continue
    step_run "formula:$package" ensure_formula "$package"
  done 3<"$ROOT/config/formulae.txt"
  while IFS=$'\t' read -r -u 3 package app; do
    [[ -n "$package" ]] || continue
    step_run "cask:$package" ensure_cask "$package" "$app"
  done 3<"$ROOT/config/casks.tsv"
}

agent_healthy() { "$1" --version >/dev/null 2>&1; }

official_install_hint() {
  local name=$1 interpreter='bash' url
  case "$name" in
    claude | codex | kiro-cli)
      if [[ "$name" == codex ]]; then interpreter='sh'; fi
      url=$(installer_url "$name")
      printf 'Install with the official command, then rerun setup:\n  curl -fsSL %s | %s\n' "$url" "$interpreter" >&2
      ;;
    chatgpt | kiro)
      url=$(source_url "$name" documentation)
      printf 'Install the desktop app from the official download page, then rerun setup:\n  %s\n' "$url" >&2
      ;;
    *) fail "No official installation instructions for $name" ;;
  esac
}

check_external_app() {
  local name=$1 app=$2
  if app_healthy "$app"; then
    STEP_ACTION=preserved
    echo "$app is installed; installation and updates are managed by the vendor."
    return
  fi
  official_install_hint "$name"
  fail "$app is missing, incomplete or incompatible. Complete the official installation first."
}

check_agent() {
  local name=$1
  if agent_healthy "$name"; then
    STEP_ACTION=preserved
    "$name" --version
    return
  fi
  official_install_hint "$name"
  fail "$name is missing or not runnable. Complete the official installation first."
}

ensure_kiro_shell() {
  STEP_ACTION=$(python3 "$ROOT/scripts/kiro-shell.py" --app "$(app_path 'Kiro CLI.app')")
  echo 'Kiro Zsh hooks ready. First launch and system permissions remain manual; see README.'
}

apply_configuration() { python3 "$ROOT/scripts/configure.py" --config-dir "$CONFIG_DIR"; }
verify_installation() { /bin/bash "$ROOT/scripts/verify.sh"; }
prepare_sogou_installer() {
  python3 "$ROOT/scripts/prepare-sogou.py"
  STEP_ACTION=prepared
}

execute_mode() {
  activate_paths
  case "$MODE" in
    check-updates)
      STEP_TOTAL=1
      step_run maintenance python3 "$ROOT/scripts/check-updates.py" --config-dir "$CONFIG_DIR"
      ;;
    diagnose)
      STEP_TOTAL=1
      step_run network network_check
      ;;
    docker-smoke)
      STEP_TOTAL=1
      step_run docker-runtime /bin/bash "$ROOT/scripts/docker-smoke.sh"
      ;;
    configure-only)
      STEP_TOTAL=1
      step_run configuration apply_configuration
      ;;
    verify)
      STEP_TOTAL=1
      step_run verification verify_installation
      ;;
    install)
      STEP_TOTAL=$((9 + $(awk 'NF { n++ } END { print n+0 }' "$ROOT/config/formulae.txt") + $(awk 'NF { n++ } END { print n+0 }' "$ROOT/config/casks.tsv") + $(awk 'NF { n++ } END { print n+0 }' "$ROOT/config/vscode-extensions.txt")))
      if [[ "$WITH_SOGOU" == true ]]; then STEP_TOTAL=$((STEP_TOTAL + 1)); fi
      step_run target check_install_target
      step_run network network_check
      step_run homebrew bootstrap
      install_packages
      activate_paths
      step_run configuration apply_configuration
      step_run ohmyzsh ensure_ohmyzsh
      step_run kiro-shell ensure_kiro_shell
      install_extensions
      step_run claude check_agent claude
      step_run codex check_agent codex
      step_run verification verify_installation
      echo 'Open iTerm2 with Clean Setup. Run claude and codex to sign in.'
      echo 'Open Kiro.app for the IDE. Run kiro-cli launch for terminal integration onboarding, then reopen iTerm2.'
      echo 'Complete first launch in Docker.app, then run ./setup.sh --docker-smoke.'
      if [[ "$WITH_SOGOU" == true ]]; then step_run sogou-installer prepare_sogou_installer; fi
      ;;
  esac
}

main() {
  local mode_set=0
  ui_init
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plan | --configure-only | --verify | --docker-smoke | --diagnose | --check-updates)
        [[ "$mode_set" == 0 ]] || fail 'Choose only one mode.'
        MODE=${1#--}
        mode_set=1
        shift
        ;;
      --update)
        UPDATE=true
        shift
        ;;
      --with-sogou)
        WITH_SOGOU=true
        shift
        ;;
      --config-dir | --log-dir)
        [[ $# -ge 2 && -n "$2" ]] || fail "$1 requires a directory."
        if [[ "$1" == --config-dir ]]; then CONFIG_DIR=$2; else LOG_ROOT=$2; fi
        shift 2
        ;;
      --help | -h)
        usage
        return
        ;;
      *) fail "Unknown argument: $1" ;;
    esac
  done
  [[ "$UPDATE" == false || "$MODE" == install || "$MODE" == plan ]] || fail '--update is only valid for installation or --plan.'
  [[ "$WITH_SOGOU" == false || "$MODE" == install || "$MODE" == plan ]] || fail '--with-sogou is only valid for installation or --plan.'
  [[ -d "$CONFIG_DIR" ]] || fail "Missing configuration directory: $CONFIG_DIR"
  if [[ "$MODE" == plan ]]; then
    echo "Mode: install; update existing tools: $UPDATE"
    cat "$ROOT/config/formulae.txt" "$ROOT/config/casks.tsv" "$ROOT/config/vscode-extensions.txt" "$ROOT/config/sources.tsv"
    echo "Configuration templates: $CONFIG_DIR"
    echo 'AI tools are check-only, including --update: ChatGPT, Kiro IDE/CLI, Claude Code and Codex CLI.'
    echo 'Install missing AI tools separately from their official installers before running setup.'
    echo "Logs: $LOG_ROOT"
    if [[ "$WITH_SOGOU" == true ]]; then
      echo "Final step: prepare official Sogou ZIP in $HOME/Downloads/macos-setup; install manually."
    fi
    return
  fi
  if [[ "$MODE" != docker-smoke && "$MODE" != diagnose ]]; then
    [[ $(uname -s) == Darwin ]] || fail 'This installer requires macOS.'
  fi
  run_session "$LOG_ROOT"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
