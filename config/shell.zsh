# Managed by macos-setup. Personal overrides belong after the source in .zshrc.
source "${${(%):-%N}:A:h}/env.zsh"
[[ -o interactive ]] || return 0

# An already loaded Oh My Zsh/theme keeps control of the prompt.
if (( ! $+functions[omz] )) && [[ -r "${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh" ]]; then
  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  : ${ZSH_THEME=robbyrussell}
  (( ${+plugins} )) || plugins=(git)
  zstyle ':omz:update' mode disabled
  source "$ZSH/oh-my-zsh.sh"
fi

bindkey -e
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^W' backward-kill-word
bindkey '^[^?' backward-kill-word

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history hist_ignore_dups share_history
# Native AutoJump owns j; zoxide retains its separate z / zi commands and database.
if (( $+commands[autojump] )); then
  setup_autojump="${commands[autojump]:A:h:h}/share/autojump/autojump.zsh"
  if [[ -r "$setup_autojump" ]]; then
    # Replace only the old managed zoxide wrapper when reloading after an upgrade.
    setup_j_source="${functions_source[j]:-}"
    if [[ -n "$setup_j_source" && "${setup_j_source:A}" == "${${(%):-%N}:A}" &&
          "${functions[j]:-}" == $'\tz "$@"' ]]; then
      unfunction j
    fi
    unset setup_j_source
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
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
[[ -t 0 && -t 1 ]] && command -v fzf >/dev/null && source <(fzf --zsh)
alias ll='ls -lah'
alias g='git'
alias cl='claude'
alias clc='claude --continue'
# Explicit opt-in shortcuts: skip Claude permission checks / Codex approvals and sandbox.
alias cld='claude --dangerously-skip-permissions'
alias cldc='claude --dangerously-skip-permissions --continue'
alias cx='codex'
alias cxc='codex resume --last'
alias cxd='codex --dangerously-bypass-approvals-and-sandbox'
alias cxdc='codex resume --last --dangerously-bypass-approvals-and-sandbox'
alias dc='docker compose'

# Portable local shortcuts; these override colliding Oh My Zsh aliases.

# Make
alias m=make
alias mb='make build'
alias mi='make install'
alias mr='make run'
alias mt='make test'
alias mp='make preview'

# Git
alias ga='git add'
alias gaa='git add --all'
alias gcmsg='git commit --message'
alias gs='git status -s'
alias gst='git status'
alias gss='git status --short'
alias gd='git diff --no-index'
alias gdiff='git diff'
alias gds='git diff --staged'
alias gdca='git diff --cached'
alias gb='git branch'
alias gba='git branch --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch --create'
alias gl='git pull'
alias gp='git push'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias glg='git log --stat'
alias gstl='git stash list'
alias gstp='git stash pop'
alias grs='git restore'
alias grst='git restore --staged'
alias git_undo_last='git reset --soft HEAD~1'

# Go
alias gdoc='go doc -all .'
alias glist='go list -m -u all'
alias glistj='go list -m -json all'
alias grun='go run -v .'
alias gbuild='go build -ldflags "-s -w" -trimpath -v .'
alias gbuildmac='GOOS=darwin GOARCH=arm64 go build -ldflags "-s -w" -trimpath -v .'
alias gbuildmacintel='GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w" -trimpath -v .'
alias gbuildlinux='GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -trimpath -v .'
alias gbuildwindows='GOOS=windows GOARCH=amd64 go build -ldflags "-s -w" -trimpath -v .'
function gcv {
  go test -v -race -cover -covermode=atomic -coverprofile=coverage.out -count 1 ./... "$@" || return
  go tool cover -html=coverage.out -o coverage.html
}
alias gtest='go test -v -race -cover -covermode=atomic -count 1 ./...'
alias gbench='go test -parallel=4 -run=none -benchtime=2s -benchmem -bench=.'
alias gm='go mod'
alias gmi='go mod init'
alias gmt='go mod tidy'
alias gmg='go mod graph'
alias gmc='go clean --modcache'

# Docker; d stays the directory stack function defined below.
alias dk=docker
alias dkc='docker container'
alias dkcm='docker compose'
alias dexec='docker exec -it'
alias di='docker images'
alias dimg='docker images'
alias dkimg='docker image ls'
alias dklg='docker logs -f'
alias dkls='docker ps -a'
alias dkps='docker ps -a'
alias dkrm='docker rm -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias drmi='docker rmi'
alias dks='docker service'
alias dksm='docker swarm'
alias dkst='docker stack'
alias dkstat='docker system df'

# Disk
alias df='df -h'

# Multi-command shortcuts stop immediately if an earlier command fails.
unalias gpre gps1 mkcd mcd d cdf o dl mktgz mkzip tfind jv jp jsonview pcat \
  sha1 sha224 sha256 sha384 sha512 gci gcia git_corb git_ignore git_readme \
  tn tad to tkss tmuxconf tds cn gcv dkclear fingerprint 2>/dev/null || true
function gpre { git status && git add --all && git diff --staged -w "$@"; }
function gps1 {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD) || return
  git push --set-upstream origin "$branch" "$@"
}

function mkcd { [[ $# == 1 && -n $1 ]] || { print -u2 "usage: mkcd <directory>"; return 1; }; mkdir -p -- "$1" && cd -- "$1"; }
function mcd { mkcd "$@"; }

# Directory stack, Oh My Zsh compatible; redefined here so it also works without OMZ.
unalias d 2>/dev/null || true
function d {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}

# Files and directories
function cdf {
  if [[ -d $1 ]]; then
    cd -- "$1"
  else
    cd -- "$(dirname "$1")"
  fi
}
function o {
  if [[ $# -lt 1 ]]; then
    open .
  else
    open "$1"
  fi
}
function dl {
  case $# in
    2) curl --fail --location --output "$2" -- "$1" ;;
    1) curl --fail --location --remote-name -- "$1" ;;
    *) echo "usage: dl <url> [output]" >&2; return 1 ;;
  esac
}
function mktgz {
  if [[ -z $1 ]]; then echo "missing source target" >&2; return 1; fi
  tar cvzf "${1%%/}.tgz" "${1%%/}/"
}
function mkzip {
  if [[ -z $1 ]]; then echo "missing source target" >&2; return 1; fi
  zip -r -8 "${1%%/}.zip" "$1"
}
function tfind {
  if [[ -z $1 ]]; then echo "missing target keyword" >&2; return 1; fi
  echo "Searching for '$*'"
  rg --ignore-case --fixed-strings --glob '*.txt' --glob '*.md' -- "$*" .
}
alias trim="awk '{\$1=\$1;print}'"
alias lsp="find . -type f -not -path '*/\.git/*' | sed 's/^\.\///g' | sort"
alias lsmax="find . -type f -not -path '*/\.git/*' -print0 | xargs -0r stat -f '%z %N' | sort -nr | head -10"
alias lslast="find . -type f -not -path '*/\.git/*' -print0 | xargs -0r stat -f '%Sm %N' -t '%Y-%m-%d %T' | sort -nr | head -10"

# Viewing (jq, bat, glow)
function jv { jq <"$1" -C . | less -R; }
function jp { jq -M . "$1"; }
function jsonview { printf '%s\n' "$*" | jq -C -r .; }
alias ccat='bat --paging=never'
alias mcat='glow'
alias readme='glow README.md'

# Clipboard and clock; now uses local time, utcnow uses UTC.
alias ppwd='pwd | pbcopy ; pbpaste'
alias pd='basename "$PWD" | pbcopy ; pbpaste'
alias pc=pbcopy
alias pp=pbpaste
alias l2l='pbpaste | paste -sd " " - | pbcopy'
alias now='date "+%Y-%m-%d %H:%M:%S %Z" | pbcopy ; pbpaste'
alias utcnow='TZ=UTC date "+%Y-%m-%d %H:%M:%S %Z" | pbcopy ; pbpaste'
function pcat {
  if [[ -z $1 ]]; then echo "missing source target" >&2; return 1; fi
  cat -- "$@" | pbcopy
}

# Hashes and encoding
function sha1 { shasum -a 1 "$@"; }
function sha224 { shasum -a 224 "$@"; }
function sha256 { shasum -a 256 "$@"; }
function sha384 { shasum -a 384 "$@"; }
function sha512 { shasum -a 512 "$@"; }
alias b64e='base64'
alias b64d='base64 -d'

# Git helpers with validation; these replace the plain gci/gcia aliases.
unalias gci gcia 2>/dev/null || true
function gci {
  if [[ -z $1 ]]; then echo "missing commit message" >&2; return 1; fi
  git commit -a -m "$*"
}
function gcia {
  if [[ -z $1 ]]; then echo "missing commit message" >&2; return 1; fi
  git commit --amend -a -m "$*"
}
alias dif='git diff --no-index'
alias gmd='git checkout master && git pull && git remote prune origin'
function git_corb {
  if [[ -z $1 ]]; then
    echo "missing remote branch name for 'git checkout remote branch'" >&2
    return 1
  fi
  git checkout -b "$1" origin/"$1"
}
function git_ignore {
  local name=.gitignore
  if [[ -z $1 ]]; then
    local curdir="$(pwd)"
    echo "/${curdir##*/}" >>"$name"
  else
    echo "$1" >>"$name"
  fi
  git add "$name"
}
function git_readme {
  local name=README.md
  if [[ -z $1 ]]; then
    local curdir="$(pwd)"
    echo "# ${curdir##*/}" >>"$name"
  else
    echo "$1" >>"$name"
  fi
  git add "$name"
}

# Editor and paths
function cn {
  if (( $# )); then code -n "$@"; else code -n .; fi
}
alias cdiff='code -n --diff'
alias rp=realpath

# tmux: retain local ts=list and tn=new conventions alongside OMZ shortcuts.
alias t=tmux
alias ts='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
function tn {
  if [[ -z $1 ]]; then
    tmux new-session
  else
    tmux new-session -s "$1"
  fi
}
for ((setup_tmux_index = 0; setup_tmux_index <= 16; setup_tmux_index++)); do
  alias ta$setup_tmux_index="tmux attach -t $setup_tmux_index"
done
unset setup_tmux_index
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
function tad {
  if [[ -z $1 || $1 == -* ]]; then tmux attach -d "$@"; else tmux attach -d -t "$@"; fi
}
function to {
  if [[ -z $1 || $1 == -* ]]; then tmux new-session -A "$@"; else tmux new-session -A -s "$@"; fi
}
function tkss {
  if [[ -z $1 || $1 == -* ]]; then tmux kill-session "$@"; else tmux kill-session -t "$@"; fi
}
function tmuxconf {
  local setup_tmux_config=${ZSH_TMUX_CONFIG:-}
  if [[ -z $setup_tmux_config ]]; then
    if [[ -f "$HOME/.tmux.conf" ]]; then
      setup_tmux_config="$HOME/.tmux.conf"
    elif [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" ]]; then
      setup_tmux_config="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
    else
      setup_tmux_config="$HOME/.tmux.conf"
    fi
  fi
  local -a setup_editor
  setup_editor=(${(z)${EDITOR:-vi}})
  "${(@Q)setup_editor}" "$setup_tmux_config"
}
function tds {
  local setup_tmux_hash setup_tmux_name
  if (( $+commands[md5] )); then
    setup_tmux_hash=$(printf '%s' "$PWD" | command md5 -q) || return
  else
    setup_tmux_hash=$(printf '%s' "$PWD" | command md5sum) || return
  fi
  setup_tmux_name="${PWD:t}"
  setup_tmux_name="${setup_tmux_name//[.:]/_}"
  tmux new-session -A -s "${setup_tmux_name:-root}-${setup_tmux_hash[1,6]}" "$@"
}

# Docker cleanup
function dkclear {
  docker system prune -f
}

# Misc
alias reload='. ~/.zshrc'
alias cls='clear'
alias e='exit'
alias ns=nslookup
alias weather='curl wttr.in'
alias webserver='python3 -m http.server'
function fingerprint {
  if [[ -z $1 ]]; then
    echo "missing target ssh key" >&2
    return 1
  fi
  ssh-keygen -E md5 -lf "$1" && ssh-keygen -E sha256 -lf "$1"
}
