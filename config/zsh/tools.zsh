# Managed by macos-setup: tools. Personal overrides belong after the source in .zshrc.
# Native AutoJump owns j; zoxide retains its separate z / zi commands and database.
if (( $+commands[autojump] )); then
  setup_autojump="${commands[autojump]:A:h:h}/share/autojump/autojump.zsh"
  if [[ -r "$setup_autojump" ]]; then
    # Replace only the old managed zoxide wrapper when reloading after an upgrade.
    setup_j_source="${functions_source[j]:-}"
    setup_tools_source="${${(%):-%N}:A}"
    setup_legacy_shell="${setup_tools_source:h:h}/shell.zsh"
    if [[ -n "$setup_j_source" && ("${setup_j_source:A}" == "$setup_tools_source" ||
          "${setup_j_source:A}" == "$setup_legacy_shell") && "${functions[j]:-}" == $'\tz "$@"' ]]; then
      unfunction j
    fi
    unset setup_j_source setup_tools_source setup_legacy_shell
    # Preserve personal functions, aliases and commands, and load the hook only once.
    if (( ! $+functions[j] && ! $+aliases[j] && ! $+commands[j] )); then
      () {
        setopt localoptions noaliases
        source "$1"
      } "$setup_autojump"
    fi
  fi
  unset setup_autojump
fi
if command -v zoxide >/dev/null; then
  setup_zoxide_init=$(zoxide init zsh) || return
  # Current zoxide ends its interactive completion block with a false feature
  # check when compdef is unavailable. That is a valid initialization result,
  # so append a successful no-op without hiding generation or syntax failures.
  eval "$setup_zoxide_init"$'\n:' || return
  unset setup_zoxide_init
fi
if [[ -t 0 && -t 1 ]] && command -v fzf >/dev/null; then
  source <(fzf --zsh) || return
fi
