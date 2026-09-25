# Machine / agent interface

## Entry point and modes

Run Bash 3.2-compatible `./setup.sh`. Source checkout: `https://github.com/6ai/macOS-devenv`.

| Arguments | Mutation | Success condition |
| --- | --- | --- |
| `--help`, `--plan` | None, no log directory created | Help/plan printed, exit 0 |
| no mode | Install development tools/AI CLIs; prepare missing desktop DMGs; apply templates | Automated tools and prepared packages verify; manual_steps lists remaining user work |
| `--managed-desktop` | Also place desktop apps and configure managed Kiro Zsh integration | All declared packages/runtime probes pass; GUI/login remain manual |
| `--with-sogou` | Also prepare the official Sogou ZIP for manual installation | Normal verification plus a checksum-verified local installer package |
| `--update` | Upgrade managed tools and refresh default desktop DMGs; managed desktop mode updates owned apps | Same mode-specific verification after update |
| `--configure-only` | Apply templates only; Python 3.11+ required | Inputs valid; writes or preserves succeed |
| `--check-updates` | Session reports and query caches only; no installers, metadata refresh, Git fetch/pull or config writes | Report complete; available updates may still exist. Partial failures preserve reports and exit 1 |
| `--verify` | Diagnostic logs/inventory; temporary runtime smoke files | All declared packages, bundles, configs and runtimes pass |
| `--diagnose` | Diagnostic logs; HTTPS requests to public official endpoints | Reachability probes have no transport/5xx failure |
| `--docker-smoke` | Build/run/remove a temporary amd64 image | Running engine builds container and expected output matches |

`--config-dir DIR` selects the seven templates; it never changes installer URLs or the package manifest. `--log-dir DIR` selects a local, private log root. All invocations using that root share its lock; do not use different roots to bypass concurrency protection. `--update` and `--with-sogou` can be combined only with install or `--plan`, including both flags together.

Default downloadable desktops are Docker Desktop, Chrome, ChatGPT, Kiro IDE and Claude Desktop. First inspect actual installed bundles; healthy copies are preserved. Missing apps get official DMGs in ~/Downloads/macos-setup and a final manual-install reminder. iTerm2/VS Code remain qualified official casks. Default Kiro CLI invokes its official installer and leaves onboarding/integration to the vendor. See installation.md for the per-app policy.

The default run has 54 stages; --with-sogou adds one preparation stage. Prepared packages are not installed apps. result.json includes desktop_mode and manual_steps. During default install only, verification may accept a freshly validated prepared DMG for an absent desktop; inventory records null plus pending_applications. Standalone --verify remains strict and fails for absent apps. --managed-desktop --verify additionally validates managed Kiro hooks. The optional Sogou ZIP always remains a manual installation in either policy.

## Desktop, editor and shell contracts

Since 0.1.40, desktop behavior is explicit: download-only by default, automatic placement only with --managed-desktop. Default missing app downloads use the official latest URL or stable feed, validate the DMG, and save a receipt with filename/source/version/SHA-256. Reuse checks real file bytes; --update refreshes downloads. Never write app bundles or custom Kiro hooks in default desktop preparation. Claude/Codex CLIs use native official scripts; healthy unknown installations stay on their original manager. Python runs only after bootstrap installs it.

Managed AI app placement checks vendor identity, Apple-trusted signature, executable and arm64 before copying. Kiro CLI additionally checks its manifest SHA-256. ChatGPT uses the fixed Codex.dmg URL and verifies its feed version/build. Claude Desktop resolves its DMG beside the ZIP named by the official release feed. Keep downloads/mounts in private temporary directories and only stage the final copy beside Applications for atomic replacement. Require apps to be closed normally; restore old copies after a failed replacement. Default Kiro instead calls the original installer with its own prompts and startup behavior; do not synthesize consent to vendor replacement/migration prompts.

Records under ${XDG_STATE_HOME:-~/.local/state}/macos-setup/official-installs identify managed ownership, never prove health. Preserve personal configuration and credentials. cask:* IDs remain stable even where the component uses an official download rather than Homebrew. Claude Desktop uses cask:claude-desktop, distinct from the claude CLI stage. Recognize ChatGPT.app and legacy Codex.app with bundle ID com.openai.codex; desktop and CLI health are independent.

Apply configuration before installing Oh My Zsh so `KEEP_ZSHRC=yes` preserves the managed source line. Default theme is robbyrussell with git plugin; existing loaded Oh My Zsh/theme/plugin choices survive. The unattended installer never changes the account's login shell. Default iTerm profile is Clean Setup with Clean Dark colors and Menlo 13. Fresh VS Code settings select Zsh login shell and Default Dark Modern; preserve existing JSONC bytes. Install/check every ID in `config/vscode-extensions.txt` independently; failures stop the run. Default execution skips installed extensions; --update explicitly requests upgrades.

`env.zsh` supplies deduplicated PATH in login and interactive shells; `shell.zsh` loads interactive features only. Respect existing GOBIN/GOPATH without setting GOROOT. At the configuration CLI boundary, absolute CODEX_HOME, CLAUDE_CONFIG_DIR and ZDOTDIR override the respective default directories; pass the same environment on rerun/verify. No credentials or proxy values are written into public templates or exported to GUI launch services. Seven external templates are claude-settings.json, codex-config.toml, env.zsh, shell.zsh, iterm2-profile.json, vscode-settings.json and kiro-permissions.json. Package/extension/source manifests remain repository-controlled.

Kiro IDE is an official desktop download, independent of the separately installed Kiro CLI app from the official CLI installer. Resolve system/user Kiro.app, require bundle ID dev.kiro.desktop and IDE major version >= 1. Preserve compatible copies by default; update and repair only copies recorded as installed by this setup. Do not add the IDE's internal bin directory to PATH: its `code` command would shadow VS Code.

Install kiro-permissions.json as ~/.kiro/settings/permissions.yaml (JSON subset of YAML), mode 0600 on creation. The default all/ask rule requires interactive approval across capabilities; it is not an OS sandbox. Preserve existing nonempty YAML byte-for-byte, report it as custom and unreviewed. Reject empty policies and symlink files/directories before mutation. `inventory.json.kiro_permission_template` is `default-ask` or `custom-unreviewed`, a template comparison, never a claim of effective permission enforcement. Validation checks external JSON rule structure; it does not audit personal YAML, workspace/session/enterprise rules or runtime approval behavior. Human login and allow/deny acceptance in a temporary project are required. Never auto-grant TCC/IAM, migrate Q, import credentials or install trusted MCP/hooks. Data-sharing choices remain for first-run review.

The following Kiro hook contract applies only to --managed-desktop. Default mode delegates to vendor onboarding and does not inspect or rewrite loader layout. Kiro CLI.app is resolved from system/user Applications, separately from IDE. The `kiro-shell` stage follows configuration and Oh My Zsh. Supply three runnable ~/.local/bin commands (kiro-cli, kiro-cli-chat, kiro-cli-term) needed by native loaders; preserve healthy personal commands, repair missing links or broken links resolving to the vendor app, reject unknown broken commands. Use only the official `integrations install --silent dotfiles zsh` command. Validate both Zsh rows of JSON status (the current CLI ignores the shell filter when listing), the exact contents of all four vendor loader files and syntax of all four generated init snippets. Respect ZDOTDIR; do not install SSH, input method or other integrations automatically. Native installer backs up changed dotfiles.

Before loading hooks, use `inline disable` only when inline.enabled is absent from `${KIRO_HOME:-~/.kiro}/settings/cli.json`; preserve explicit true/false choices and all other settings. This avoids the actual CLI 2.21.1 malformed opt-in notification and leaves history-based AI suggestions disabled on fresh installs. Respect absolute KIRO_HOME; refuse symlink settings. Do not infer CLI 2.x tool approval from IDE permissions.yaml. Human onboarding uses `kiro-cli launch`, a fresh iTerm2 window and `kiro-cli doctor --all` (no automatic fixes); optional input-method setup and TCC consent remain manual. Automated tests checks shell integration, not graphical completion or login. Do not publish raw Kiro settings, diagnostic reports or shell history.

Since 0.1.35, a custom KIRO_HOME requires a recognized selected CLI version >= 2.3.0, checked before creating command links or changing preferences. Older CLIs ignore that variable; never fall back to changing their default profile. Default ~/.kiro remains supported for healthy older CLIs. Native tests pin the app command directory in PATH, test default-profile integration on all supported local versions, and test either custom-profile integration or rejection without writes according to the actual version. An absent settings file after inline disable produces an actionable error.

Managed package operations and metadata queries use qualified homebrew/core, homebrew/cask or the four declared charmbracelet/tap names. During bootstrap, unset the retired HOMEBREW_ASK and export HOMEBREW_NO_ASK=1 for this process only. Global untrusted-tap warnings remain visible and do not imply installation failure; never grant unrelated/whole-tap trust or remove taps. Fully qualified Charm installs grant trust only to those requested formulae. Confirmation suppression does not bypass sudo, OS permissions or vendor onboarding.

The eight default extensions are Go, Python, Ruff, ESLint, Prettier, YAML, ShellCheck and Sublime Text Keymap (ms-vscode.sublime-keybindings). Preserve user keybindings.json; do not invoke the extension's Sublime settings importer automatically. Reload VS Code to load keymap contributions. Container Tools, Even Better TOML, Remote SSH and Dev Containers are manual options documented in shell-editor.md; existing copies are not removed and optional IDs are outside setup verification/update reports. Python may install optional companion extensions; only declared IDs are verified. Preserve personal/project formatter and format-on-save settings.

## Development shell shortcuts

The interactive template explicitly defines portable Make, Git, Go and Docker aliases from the local conventions; shell-editor.md contains the complete mappings. They load after Oh My Zsh, so gd intentionally means git diff --no-index (use gdiff for repository diff) and gm means go mod (use git merge for merging). d is the Oh My Zsh-compatible directory stack function (dirs -v | head -n 10), also defined without OMZ; Docker uses dk/dc. The template also ports portable file, viewer, clipboard, hash and tmux helpers (mcd/mkcd, cdf, o, dl, mktgz/mkzip, tfind, trim, lsp/lsmax/lslast, jv/jp/jsonview, ccat/mcat/readme, pc/pp/ppwd/pd/pcat/l2l, now in the local timezone and utcnow in UTC, sha1–sha512, b64e/b64d, t/ts/ta/tk/tn and ta0–ta16, reload/cls/e/ns/weather/webserver/fingerprint). Alias names are lowercase. Additional CLI arguments retain normal shell quoting. These definitions invoke no mutations at shell startup; tests expand linear aliases against stubs and pin composite pipeline aliases by their raw definition text.

gpre and gps1 are functions: gpre runs status, add --all and diff --staged -w, stopping on failure; gps1 resolves the current symbolic branch and pushes with upstream, stopping before push on detached HEAD. gci/gcia are functions that require a commit message and fail without committing when it is missing. dkclear explicitly invokes docker system prune -f, removing stopped containers, unused networks, dangling images and build cache, without volumes; it propagates errors. Arguments append to the final diff/push command. Make targets belong to the current project. The imported gmd shortcut retains its legacy master-only checkout/pull/prune workflow; it is not suitable for main-only repositories. No private revive configuration, obsolete Go compatibility/insecure flags, proxy changes, private helper tools or hardcoded personal paths are imported. Existing personal files remain untouched; place overrides after the managed source line.

## AI shell aliases

Interactive shell.zsh defines cl/clc/cld/cldc and cx/cxc/cxd/cxdc. Plain aliases launch the CLI or resume (--continue for Claude; resume --last for Codex). The d variants explicitly add --dangerously-skip-permissions for Claude or --dangerously-bypass-approvals-and-sandbox for Codex, including the corresponding resume variant. These aliases are opt-in command invocations, not persistent CLI permission policy; only Codex's bypass flag explicitly disables its sandbox. Preserve personal CLI configuration and allow alias overrides after the managed source line. Never run bypass sessions during setup or automated tests; validate expansion using stub executables in isolated Zsh. Noninteractive shells do not define these aliases.

Existing installations can apply this template with --configure-only and open a new terminal. A caller using --config-dir must update their external shell.zsh and keep the same option. Local shell files are reference material only: no local credentials, paths, proxy wrappers or internal aliases are published.

## Charm CLI contract

formulae.txt contains four fully qualified entries: charmbracelet/tap/glow, charmbracelet/tap/pop, charmbracelet/tap/gum and charmbracelet/tap/crush. Short entries resolve to homebrew/core; executable probes use the final path component. Resolve installed vendor formula first, then an existing core counterpart; skip, repair, upgrade, verification and inventory retain that source. Missing packages use fully qualified vendor installation, whose Homebrew trust grant is item-only. No explicit whole-tap trust or untrust commands are run. Stage IDs retain the full declared entry, such as formula:charmbracelet/tap/gum.

Use the existing Homebrew PATH and preserve user configuration. No Pop mail credentials/delivery, Crush provider credentials/model calls, auto-approval, MCP or login setup is performed. Verify all four version commands, Glow Markdown rendering and Gum style output; GUI/TUI, mail delivery and authenticated AI use require manual acceptance. Bootstrap presentation remains independent of Gum.

## Maintenance interface

`--check-updates` writes updates.json and updates.md in the session directory; see [schema](updates.schema.json) and [runbook](maintenance.md). Keep the same --config-dir and configuration environment overrides across runs. Charm copies use version/revision text from the official tap, parsed without Ruby execution or trust changes; existing core copies keep the core catalog. Unsupported metadata returns unknown/incomplete. Homebrew stable API is the other managed-package reference; desktop comparisons use actual app versions. AI tools compare actual versions with official vendor metadata, never Homebrew reference versions. New or recorded copies use manager=native and suggest setup/update as appropriate; other copies retain manager=original and their original_updater. Metadata failures remain unknown/partial, never current. Marketplace selects stable arm64/universal candidates and reports editor engine requirements; VS Code resolves compatibility at install time. Git checks use ls-remote only against validated origins, without fetching objects or claiming a direction for differing revisions. Compare template bytes but never export their contents or hashes.

Exit 0 means the check completed, not all tools are current. Inspect summary/status and next_action; complete=false returns 1 while preserving partial evidence. Never interpret unknown as current or execute report text as a command. Review before running --update; that command performs its own verification. Recheck afterward and retain both reports. --verify remains the executable/configuration health gate; version equality alone is not proof of health. No background upgrade service is installed.

## Terminal presentation

SETUP_COLOR=auto|always|never and SETUP_ICONS=auto|emoji|ascii control presentation only. Auto requires a TTY, non-dumb TERM and no automated tests/GITHUB_ACTIONS marker; emoji auto additionally requires a UTF-8 locale. Nonempty NO_COLOR or TERM=dumb disables color even with always. Invalid values exit 2 before session creation. Capture TTY state before creating the logging pipeline.

Status labels are [OK], [SKIP], [KEEP], [WARN], [MANUAL], [FAILED], [DONE], [INFO]; stage headers retain [index/total] and show a 20-cell ASCII bar with the percentage of completed stages. Internal warnings append a warning/notice events.tsv row; a completed warning stage still has success/warning, not a failed result. A session with setup warnings has a yellow summary. Vendor warnings remain verbatim and are not counted/classified as setup warnings. Machine schemas and exit semantics are unchanged; parse JSON/TSV instead of decorated console output.

tee copies raw command bytes straight to the original stdout, including unterminated prompts; only the log branch strips SGR escapes and known status icons using system awk (no bootstrap Python dependency). Flush complete log lines, wait for all pipeline components, and preserve command failures. A logger failure after an otherwise successful command or resulting SIGPIPE returns 74 and corrects result.json; an independent command failure retains its own code. Health/existence probes stay quiet, but repair paths emit explicit warnings.

## Exit codes

| Code | Meaning / next action |
| --- | --- |
| 0 | Selected mode completed; inspect scope, not just status |
| 1 | Validation/precondition/probe failed; inspect failed stage |
| 74 | Log writer failed; repair log destination and retry |
| 75 | Lock busy or ambiguous; inspect `install.lock/owner.pid` |
| 130 / 143 | Interrupted by SIGINT / SIGTERM |
| other nonzero | Underlying command's status (for example curl 22); inspect `run.log` |

Invalid arguments and unsupported operating systems fail before creating a session. Once a session starts, `result.json` is written atomically on normal completion, failure and catchable interruption. SIGKILL, power loss or a full filesystem can prevent finalization: absence of `result.json` means **incomplete**, never success. `events.tsv` provides the last started stage. A subsequent run rechecks actual state and recovers a lock with a dead owner PID. A missing/malformed/live/reused PID is handled conservatively; inspect it before removing a lock.

## Run directory

Default root: `${XDG_STATE_HOME:-$HOME/.local/state}/macos-setup`.
Each invocation creates `YYYYMMDDTHHMMSSZ-random/`, mode 0700 (new files 0600).

The session keeps umask 077 for private logs and project configuration. Since 0.1.35, run_package_installer uses a subshell with umask 022 for Homebrew bootstrap and brew update/install/upgrade/reinstall. Since 0.1.40, the separate official AI installer process and native CLI subprocesses also use umask 022; receipts remain 0600 and session logs retain the caller's 077 mask. This prevents the logger's restrictive mask from leaking into software installation and restores the caller's mask on both success and failure. Do not call this mutating wrapper in if/!/&&/|| contexts. Keep real exit codes and subprocess stdin; never repair existing config ownership recursively or automatically. Tests simulate installer-created files and verify that failed/successful sessions still write only 0600 log files.

| File | Schema / use |
| --- | --- |
| `run.log` | stdout/stderr with ANSI SGR decoration and known status icons removed; every warning/message retained; complete before process returns |
| `result.json` | `docs/result.schema.json`; outcome, mode, update flag, failed/last stage, timestamps, counts |
| `events.tsv` | `timestamp`, `step`, `status`, `action`; append-only, one row per stage transition |
| `environment.json` | Version 1: OS, OS version, architecture, model identifier, memory bytes, proxy-present boolean |
| `network.tsv` | `component`, `http_status`, `transport_exit`; only official endpoint identifiers |
| `inputs.sha256` | Script/config/input SHA-256 values, relative paths |
| `downloads.tsv` | Installer component and SHA-256 of successfully downloaded installer bytes |
| `sogou-installer.json` | Only with --with-sogou; absent when not requested. Version 1: prepared status, downloaded/reused action, manual_install_required=true, version, vendor source URL, SHA-256 and filename (no home path) |
| `desktop-installers.json` | Prepared desktop packages; manual_install_required=true; not proof of app installation |
| `inventory.json` | Successful selected-scope verification: script version/revision, declared formula installed versions, application bundle versions, AI/Docker/Go versions, declared vscode_extensions versions, ohmyzsh_revision |
| `updates.json` / `updates.md` | Maintenance checks only; complete or partial version/configuration report, statuses and suggested actions; see `docs/updates.schema.json` |

Machine example:

```bash
./setup.sh --log-dir "$HOME/.local/state/macos-setup"
# Locate the directory printed as "Logs:"; do not infer success from an old run.
python3 -m json.tool /absolute/path/to/that-run/result.json
```

Stage IDs: `maintenance`, `target`, `network`, `homebrew`, `formula:<token>`, `cask:<token>`, `configuration`, `ohmyzsh`, `kiro-shell`, `vscode:<extension-id>`, `claude`, `codex`, `verification`, `sogou-installer`; standalone Docker uses `docker-runtime`. Success actions include `checked`, `skipped`, `installed`, `repaired`, `preserved`, `update-checked`, `installed-or-updated`, `prepared`. Network warnings are recorded as `warning` when an install continues with cached/existing software. On failure, `action` contains the exit code.

Do not log or transmit credentials. `environment.json` deliberately excludes account names, serial numbers, hostnames, public/private IPs and proxy values. Raw third-party command output can still contain local paths or service-specific details: inspect `run.log` before sharing. The installer never uploads local logs. Automated tests artifacts come only from disposable runners without personal API keys.

## Reproduction and recovery

Use the same Git commit, public manifests and templates to reproduce configuration and acceptance criteria. The initial install resolves then-current official stable packages; this is not a byte-for-byte package lock. Preserve `inventory.json`, `inputs.sha256` and `downloads.tsv` with the run when comparing machines. Homebrew and native installers may change upstream; do not claim identical binary versions merely because the setup commit is unchanged.

Homebrew downloads default to `config/download.curlrc` through the process-local HOMEBREW_CURLRC: HTTP/1.1 to avoid HTTP/2 PROTOCOL_ERROR on affected connections, a 20-second connection deadline, 60 seconds below 1 byte/second aborts a stalled transfer, 1800 seconds per attempt and a 1800-second retry-start window. A final attempt may outlast that window; this is not a whole-install timeout. Preserve an existing HOMEBREW_CURLRC (including its legacy boolean form) and leave proxy/TLS/trust settings unchanged. Caller-supplied Homebrew curl policies own their deadlines and protocol choice. Direct project curl calls (native installer download, connectivity checks and optional Sogou download) also load this public policy, retaining their shorter command-specific deadlines. Unrelated untrusted-tap warnings do not mean a core formula failed; never auto-trust or remove those taps.

For recovery, rerun the same command (same `--config-dir`, `--with-sogou` choice and log root). Completed healthy tools skip work; missing/broken managed tools are installed/repaired; missing CLI tools use official scripts; desktop downloads or app repair follow the selected desktop policy. Configuration uses backups and atomic replacement; personal AI files are preserved. There is no destructive global rollback of system packages. To intentionally refresh versions, use `--update` and retain the prior inventory for comparison.

## Publication and maintenance

`make build` checks the independent Git root and the **entire** tracked-file list against `config/repository-files.txt`. The distribution archive uses that same explicit list. Additions require a deliberate manifest/golden update. Unreviewed files in source directories fail the check. Never replace archive creation with a recursive copy of the parent folder.

Ignore only Finder .DS_Store and existing __pycache__ artifacts when scanning source directories; tracked Finder files must still fail the exact publication-list comparison. Report missing/symlinked listed files by name and explain the independent-checkout requirement when .git is absent.

Read `docs/sources.md` before changing upstream URLs. Build, test and format before committing; validate fresh and existing installations only on disposable test machines. Do not run installers on a user's real Mac just because an agent is allowed to inspect the repository.

## Rerun and recovery contracts

Git LFS global filters are read before initialization; correctly initialized filters cause no install call or global config rewrite. Missing standard entries initialize once. A custom filter or config read error stops before initialization so existing values are preserved. Personal overrides belong after the managed source line; managed shell/env/iTerm2 template changes intentionally replace those files after backup.

Since 0.1.34, check effective Git configuration (including includes) after the Git binary check, before LFS filter inspection, and at the start of standalone verification. Discard configuration values, preserve Git's original error/exit status and provide a permissions/ACL recovery hint. A successful git --version does not establish configuration readability. Keep configuration failures separate from executable health so they do not trigger brew reinstall. Do not chmod/chown private or system configuration automatically, initialize LFS with sudo/--system, or bypass system settings with GIT_CONFIG_NOSYSTEM. Repair access on the affected host and rerun; initialized filters and healthy packages remain unchanged. Isolated tests reproduce an unreadable system file with real Git and verify recovery without package or configuration mutation.

Since 0.1.36, check Git candidates from PATH, executable HOMEBREW_PREFIX/bin/git and HOMEBREW_PREFIX/opt/git/bin/git, and explicit HOMEBREW_GIT_PATH. Homebrew can select a different Git from the invoking shell; the 0.1.34–0.1.35 PATH-only check could miss its configuration error. Repeat the read-only check before every mutating brew call, including later automatic taps. Probe the managed Git binary directly for formula health; a healthy Apple Git must not hide a broken managed installation. Only the Git reinstall preflight may skip candidates that cannot run --version, so binary repair remains possible; require the managed executable and configuration checks after installation. Normal checks must retain configuration errors even when --version also fails. Regression tests use isolated real-Git wrappers with different system config files and cover recovery, later permission changes and broken managed executables without running Homebrew installations.

Downloaded installer scripts use private temporary files; vendor CLI installers and Homebrew own their package extraction and final placement. Official desktop downloads and mounts use private temporary directories before the verified final app copy. HOMEBREW_PREFIX/etc/gitconfig is persistent system configuration, not an extraction staging file. Never relocate or remove it to hide a permissions failure. A script update and umask isolation cannot restore an existing root-owned file; verify ownership and readability using the Homebrew Git on the affected host before resuming.

0.1.37 changes recovery documentation only. When a successful ownership repair is followed by another root-owned mode-0600 file, trace writes rather than repeat chown. Git config updates copy the existing mode onto a newly created lock file and atomically replace the target, so a privileged writer can restore root ownership while preserving 0600. For a confirmed root:admin system file intended to be readable by local administrators, a human may verify admin membership and add only group read permission (0600 -> 0640), preserving ownership and contents. Recheck after an observed background update; a writer that resets modes or groups needs its own configuration corrected. No automatic chmod/chown, world-readable workaround, configuration bypass or process termination is authorized by this diagnosis. Filter fs_usage output to the exact system-config path and lock-file prefix; never collect configuration contents or process arguments. Read/stat observations do not prove which application launched the writing Git, and fs_usage's numeric suffix is a thread ID rather than a PID. Local temporary-file experiments verified Git's mode preservation under umask 077 and 022; they do not establish the target machine's writer identity or successful recovery.

## Optional applications

apps/qbittorrent is independent of setup.sh and has its own README, Compose manifest and lifecycle wrapper. Run qbt.sh start explicitly. State and password hashes stay outside the checkout; publication includes source files only. The optional smoke test downloads a self-generated torrent and checks container lifecycle behavior. Router/firewall and physical Mac sleep behavior require separate acceptance.

## Directory jump compatibility

AutoJump is a default Homebrew formula since 0.1.28; install, repair, skip, explicit update, inventory and verification follow the standard formula contract. Preserve personal j functions, aliases and executables. Replace the exact legacy j-to-z wrapper only when its recorded source is this same managed template. When j is absent, source share/autojump/autojump.zsh relative to the resolved executable installation prefix, with alias expansion locally disabled. Repeated loads do not source that integration again. Keep zoxide's z and zi separate; never create a substitute j when AutoJump is absent. Configuration-only does not install AutoJump. Do not import, reset or merge jump histories or initialize interactive hooks in noninteractive shells. The runtime smoke test uses an isolated HOME to check real AutoJump weighted selection, unchanged statistics across repeated sourcing and native j queries, and exactly one registered hook.

Since 0.1.29, the smoke test clears inherited AUTOJUMP_SOURCED/AUTOJUMP_ERROR_PATH and loads the official integration before any native database write or query, all inside the same isolated Zsh process. A separate child login shell cannot initialize the installer parent. Regression tests exercise absent, false and already-initialized parent flags without touching personal error logs. This fixes the 0.1.28 first-install verification failure; rerunning setup preserves healthy packages.

Native Homebrew regression tests require AutoJump and zoxide on macOS; portable mocked shell tests run without them.

## Terminal defaults and portable shortcuts (0.1.31)

The Clean Setup Dynamic Profile explicitly enables Unlimited Scrollback with Scrollback Lines 0, xterm-256color and mouse reporting. Retain the complete existing keyboard/color/font contract. This updates only the managed Dynamic Profile, not ordinary user profiles or live tmux options. Unlimited terminal history is independent of tmux history-limit and mouse scroll step size.

Preserve local ts=list, tn=new, ta/tk and numbered attach conventions. Add OMZ-compatible tl, tad, to, tkss, tksv, tmuxconf and tds without requiring the plugin. tds uses the current path's MD5 suffix and sanitizes tmux-invalid name characters. Resolve the personal tmux config and editor only when tmuxconf is invoked. Do not start servers, import tmux environment variables or rewrite ~/.tmux.conf during setup. Tests use a separate socket and isolated HOME to exercise session creation, naming and termination without touching the user's tmux server. Portable cn/cdiff/rp, four Go target aliases and failure-propagating gcv are also declared in the shell template; full config golden coverage applies.

Managed iTerm2 backups and staging files live in Library/Application Support/iTerm2/macos-setup-backups, outside the recursively watched DynamicProfiles folder. Before applying templates, relocate legacy clean-setup.json.backup-* and recognizable interrupted temporary files, preserving bytes and metadata. Reject symlinks and name collisions without overwriting backups. --verify reports leftover legacy backups with a configure-only recovery instruction. Migration snapshots retain stable logical backup keys relative to the managed profile even after physical relocation; content/mtime/mode preservation is still checked. Other configuration backups remain adjacent to their files.

## iTerm2 file drop behavior (0.1.33)

Upstream 3.7.2 and 3.7.3 route ordinary file drops in remotely classified sessions to a non-text paste dialog; single remote files/directories have no paste-path action. Finder file paste also enters this helper. These versions have no separate preference restoring legacy path-only drops. Never silence NoSyncPasteNonTextFile/NoSyncPasteNonTextFiles by a saved action index: the same index can select upload under different host/file conditions. Do not spoof host identity or disable shell integration to hide this behavior. shell-editor.md documents copying a pathname as plain text and the official 3.6.11 fallback. Configuration-only does not replace the app or fix upstream GUI behavior; app replacement requires a separate explicit operation after normal exit, preserving application/settings backups and active work.

Each published VERSION has an annotated v<VERSION> tag pointing to the tested release commit. Never silently move a published tag to another commit.
