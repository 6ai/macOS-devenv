# Development guide

This document is the short entry point for contributors. Product behavior and command examples belong in the main README and topic documents; implementation contracts belong here or in [automation.md](automation.md).

## Runtime contract

- Target Apple Silicon and macOS 26 or later.
- Keep the bootstrap compatible with the system Bash 3.2. Do not require Homebrew or Python before bootstrap installs them.
- Use the system Zsh and do not change the login shell.
- Preserve personal configuration, credentials, unknown installations, and software managed by another tool.
- Treat download receipts and pending records as ownership metadata, never as proof that software is healthy.

## Repository layout

- `setup.sh` builds the plan and dispatches installation stages.
- `scripts/` contains configuration, desktop, official CLI, verification, inventory, update, manual-step, and session helpers.
- `config/` contains reviewed package lists, source URLs, and installed templates.
- `tests/` contains isolated regression tests and the full configuration golden fixture.
- `config/repository-files.txt` is the exact public file allowlist and archive manifest.

The installer reads executable download locations from `config/sources.tsv`. Documentation links do not change installation behavior.

## Change workflow

1. Update `VERSION` by one patch release for distributable product changes.
2. Change implementation, tests, and user documentation together.
3. Add or remove public paths in `config/repository-files.txt` deliberately.
4. When any file under `config/` changes, update the complete `tests/fixtures/config-golden.json` fixture after reviewing the new bytes.
5. Run `make check` from an independent Git checkout.
6. Review the Git diff, archive members, executable modes, and privacy boundary before committing.

`make check` builds `dist/macos-setup.tar.gz`, validates Zsh and shell syntax, runs shellcheck and shfmt checks, executes the Python regression suite, verifies formatting, and confirms that the repository and archive exactly match the allowlist.

## Behavioral checks

Changes to installation logic should cover a fresh install, a healthy repeat, an explicit update, managed damage repair, and preservation of an unknown or personal installation. Changes to shell files should also cover an existing `.zshrc`, migration of recognized older loader lines, duplicate collapse, unchanged repeat runs, and real interactive Zsh behavior with the declared tools installed.

Default desktop mode must download and validate selected DMGs without placing `.app` bundles. Its final guide must be derived from the current run's receipts, exclude old or unselected packages, save `manual-steps.txt` with mode `0600`, and print a strict follow-up verification command. Managed desktop mode has separate placement and Kiro integration checks.

Full installation tests belong on disposable macOS runners because they can install Homebrew packages and replace runner applications. Local development should use unit tests, archive checks, and isolated temporary homes.

## Documentation map

- [automation.md](automation.md) defines modes, stages, locks, reports, failure handling, and CI expectations.
- [sources.md](sources.md) records source-review rules and release maintenance.
- [installation.md](installation.md) explains each package manager and desktop policy.
- [shell-editor.md](shell-editor.md) defines managed templates and configuration ownership.
- [troubleshooting.md](troubleshooting.md) contains user-facing recovery procedures.

Keep public documentation free of personal paths, account details, internal repositories, credentials, test artifacts, and local release records.
