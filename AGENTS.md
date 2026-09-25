# Working on macOS Setup

Read `README.md` and `docs/automation.md` first. This directory is an independent repository; never stage, copy, search for credentials in, or publish its parent directory.

## Invariants

- Target Apple Silicon and macOS Tahoe 26+. Do not assume Mac mini-specific hardware.
- Bash 3.2 bootstrap must work before Homebrew or Python is installed.
- Default execution skips healthy tools. Only `--update` upgrades them. Broken managed installations are repaired; unmanaged applications and personal AI configuration are preserved.
- Resume by checking actual state. Never trust a completion marker as proof of installation.
- Keep package-list input separate from subprocess stdin. Do not put mutating shell functions in `if`, `!`, `&&` or `||` contexts that disable Bash `errexit`.
- Record only whitelisted environment metadata. Never dump `env`, credentials, user configuration contents, serial numbers, hostnames, proxy URLs or public IPs.
- `config/sources.tsv` is the installer URL authority; `config/repository-files.txt` is the complete publication boundary.
- Do not execute the full installer on a contributor's Mac to test a change. Use isolated unit tests and disposable test machines.

## Validation and publication

1. Use a patch version bump in `VERSION`.
2. Update the complete config golden fixture deliberately when templates or public manifests change.
3. Stage specific reviewed files. Update `config/repository-files.txt` for additions/removals.
4. Run `make check` (build → tests → format); inspect the archive and diff.
5. Commit using conventional commits and publish only reviewed source files.
6. Keep the automated-test-vs-physical-hardware distinction in the README accurate. A green CLI test is not a GUI/login/Docker-on-M4 acceptance test.
