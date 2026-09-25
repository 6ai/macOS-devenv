# Public environment only. Never put credentials or proxy values in this file.
typeset -U path
for setup_brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$setup_brew" ]]; then
    eval "$("$setup_brew" shellenv)"
    break
  fi
done
unset setup_brew
path=("$HOME/.local/bin" /Applications/Docker.app/Contents/Resources/bin $path)
if [[ -n ${GOBIN:-} ]]; then
  path=("$GOBIN" $path)
elif [[ -n ${GOPATH:-} ]]; then
  for setup_go in ${(s/:/)GOPATH}; do path=("$setup_go/bin" $path); done
  unset setup_go
else
  path=("$HOME/go/bin" $path)
fi
for setup_code in /Applications/'Visual Studio Code.app'/Contents/Resources/app/bin "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin"; do
  [[ -x "$setup_code/code" ]] && path+=("$setup_code")
done
unset setup_code
export PATH
