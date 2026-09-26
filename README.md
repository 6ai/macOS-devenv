# macOS Devenv

A repeatable development environment installer for Apple Silicon Macs running macOS 26 or later.

## Install

```bash
gh repo clone 6ai/macOS-devenv
cd macOS-devenv
./setup.sh --plan
./setup.sh
```

Run the installer as your normal administrator account, without `sudo`. If `gh` is unavailable, use **Code → Download ZIP**, extract the archive, and run `bash setup.sh` from that directory. Complete the Apple Command Line Tools prompt if macOS opens it, then rerun the same command.

## What it sets up

| Area | Default behavior |
| --- | --- |
| Developer tools | Installs Git, Git LFS, Go, Node.js, Python, uv, `rg`, duf, fd, bat, fzf, AutoJump, zoxide, jq, yq, tmux, LazyGit, shellcheck, ffmpeg, ImageMagick, and related tools with Homebrew. |
| Terminal and editor | Installs iTerm2, VS Code and extensions; configures Zsh, Vim, Git defaults, a global ignore file, and modular aliases/functions. |
| Prompt and fonts | Installs Oh My Zsh, Powerlevel10k, MesloLGS Nerd Font, and JetBrains Mono Nerd Font while preserving personal themes and configuration. |
| AI command-line tools | Installs Codex CLI and Kiro CLI from their official installers. Claude Code is opt-in. |
| Desktop applications | Downloads official DMGs for Chrome, ChatGPT, Kiro IDE, and Docker Desktop when the apps are missing. |

Claude Desktop and Claude Code are disabled by default. Add `--with-claude` whenever you install, update, or verify them.

## Finish downloaded DMG installations

`prepared` means the DMG was downloaded and checked. It does **not** mean the application is installed.

At the end of a run, the installer prints a numbered guide for every package prepared in that run. Each item includes the exact package path, a shell-safe `open` command, application-specific first-launch tasks, and these required steps:

1. Open the DMG with the printed command.
2. Drag the `.app` into **Applications** and wait for the copy to finish.
3. Eject the mounted installer disk.
4. Start the app from **Applications**, sign in, and approve required macOS permissions.
5. For Docker Desktop, wait for the engine to start. Complete Kiro IDE and Kiro CLI onboarding separately.

The same guide is saved as `manual-steps.txt` in the run directory printed by the installer. After all manual work is complete, run the exact `--verify` command shown in that guide. Use the separately printed `--docker-smoke` command after Docker is running.

## Common commands

```bash
./setup.sh --plan                       # Show the selected work
./setup.sh                              # Install or repair the default selection
./setup.sh --update                     # Update managed tools and refresh DMGs
./setup.sh --verify                     # Strictly verify actual installations
./setup.sh --check-updates              # Report available updates without changing them
./setup.sh --configure-only             # Apply managed configuration templates only
./setup.sh --managed-desktop            # Place supported desktop apps automatically
./setup.sh --with-claude                # Include Claude Desktop and Claude Code
./setup.sh --with-sogou                  # Prepare the Sogou installer for manual setup
./setup.sh --docker-smoke                # Check Docker after the engine is running
```

Repeat the same selection flags when rerunning or verifying. `--managed-desktop` does not enable Claude.

## Configuration ownership

- `.zshrc`, `.zprofile`, and `.vimrc` remain user-owned. The installer updates one recognized loader line in place and preserves the content before and after it.
- Managed Zsh files live in `~/.config/macos-setup/zsh/`. Upgrades back up and atomically replace those modules; put personal overrides after the loader in `.zshrc`.
- Go exports the effective `GOPATH` and adds an explicit `GOBIN`, or each `GOPATH/bin`, to `PATH`. Existing overrides take precedence.
- Git receives missing shared defaults and a conservative global ignore file. User identity, credentials, signing, URL rewrites, includes, aliases, and an existing custom ignore file are preserved.
- Powerlevel10k preserves explicit themes and `~/.p10k.zsh`. After the first install, run `exec zsh`, then `p10k configure` if the wizard does not open, and select an installed Nerd Font in your terminal.

## Documentation

- [Installation policy](docs/installation.md)
- [Shell, editor, Git, aliases, and terminal configuration](docs/shell-editor.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Updates and maintenance](docs/maintenance.md)
- [Official software sources](docs/sources.md)
- [Automation and result files](docs/automation.md)
- [Developer guide](docs/development.md)
- [Optional qBittorrent service](apps/qbittorrent/README.md)

The current installer version is recorded in [`VERSION`](VERSION). Formal releases use a matching `v<VERSION>` tag.
