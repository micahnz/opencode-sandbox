# AGENTS.md

## Environment

You are running as the unprivileged user `agent` inside a Debian-based Docker container.

- User: `agent`
- Home directory: `/home/agent`
- Workspace: `/home/agent/Projects`
- OpenCode configuration: `/home/agent/.config/opencode`
- Nix store: `/nix/store`
- Default shell: Bash
- Package manager: Nix (experimental-features = nix-command flakes)
- Root and `sudo` access: unavailable and not permitted

The container is disposable, but the operator may persist the following Docker volumes between runs:

- `/nix` — Nix store, profiles, and installed packages
- `/home/agent/.nix-defexpr` — channel expressions
- `/home/agent/.nix-channels` — channel configuration
- `/home/agent/.cache/nix` — Nix download and evaluation cache

Do not assume that a package installed during a previous run is available. Check first.

## Workspace

Work on project files under:

```text
/home/agent/Projects
```

The host's project directory is mounted there, and changes are visible to the operator.

The OpenCode configuration is mounted separately at:

```text
/home/agent/.config/opencode
```

Do not modify files outside the workspace or your home directory unless explicitly instructed.

## Core Principle: Context Economy

Prefer tools that produce compact, structured output (`rg`, `fd`, `jq`, `sd`) over
verbose equivalents (`grep`, `find`, `cat`, `sed`). Large outputs waste context
and slow everything down. Extract exactly the fields you need rather than
printing whole files.

## Available CLI Tools

Everything in this section is preinstalled via Home Manager. Do not install
these again. If a tool you need repeatedly is missing, propose it to the
operator (see "Recording Newly Installed Tools") rather than installing it
persistently yourself.

You can verify what's installed:

```bash
home-manager packages
```

### Search & Discovery

- `rg` (ripgrep) — fast, gitignore-aware code search. Prefer over `grep`.
- `fd` — fast, gitignore-aware file finding. Prefer over `find`.
- `tree` — directory overview. Use to orient in unfamiliar code.
- `ast-grep` (`sg`) — structural code search/rewrite by AST pattern
  (`sg run -p 'PATTERN'`).
- `comby` — structural find-and-replace across languages.
- `fzf` — interactive fuzzy finder (for the human, not scripts).

### View & Diff

- `bat` — syntax-highlighted file viewer. Prefer over `cat` for reading.
- `delta` — structured git diffs; already wired into `git diff`.
- `difftastic` (`difft`) — AST-aware diffing, less noisy for refactors.
  Invoke as `difft <file1> <file2>` or `git difftool -t difftastic`.
- `sd` — sane `sed` replacement for find-and-replace.
- `jq` — parse/slice JSON. Use to extract exact fields instead of printing
  whole files.
- `yq` (Nix attribute `yq-go`) — same, for YAML/XML/TOML.

### Inspection & Meta

- `scc`, `tokei` — code stats (languages, LOC, complexity) per directory.
- `hyperfine` — statistically sound command benchmarking (preinstalled;
  use it rather than ad-hoc `time` loops).
- `watchexec` — rerun a command on file changes (test loops).
- `file`, `lsof`, `procps` (`ps`, `top`), `less`, `which` — standard
  inspection utilities.

### Quality & Validation

- `shellcheck` — always run on shell scripts before shipping.
- `cppcheck` / `valgrind` — C static analysis and memory checking.
- `golangci-lint` — Go linting (check for config in repo root first).
- `oxlint` / `oxfmt` / `biome` — TS/JS lint+format. Follow the repo's existing
  config; if none exists, default to `biome check`.
- `clang-tools` — provides `clangd`, `clang-format`, `clang-tidy` for C/C++.

### Platforms

- `gh` — GitHub CLI: PRs, issues, CI status; `gh api` + `jq` for raw queries.
  Auth is preconfigured.
- `go` (`go_latest`), `delve` (`dlv`), `gopls` — Go toolchain, debugger, LSP.
- `node` (`nodejs_26`), `bun`, `tsc` (`typescript`), `vtsls` — TS/JS runtimes,
  compiler, LSP.
- `go-jsonnet` — Jsonnet toolchain (`jsonnetfmt`, evaluation).
- `nixd` — Nix LSP.
- `opencode` — this agent.

### Getting Help

- `<tool> --help` first; `man <tool>` for full docs.
- To browse Nix package attributes: <https://search.nixos.org/packages>.
- Upstream docs: <https://github.com/BurntSushi/ripgrep>,
  <https://github.com/sharkdp/fd>, <https://ast-grep.github.io/>,
  <https://difftastic.wilfred.me.uk/>, <https://comby.dev/>,
  <https://github.com/chmln/sd>, <https://jqlang.github.io/jq/>,
  <https://github.com/mikefarah/yq>, <https://cli.github.com/>,
  <https://github.com/boyter/scc>, <https://github.com/sharkdp/hyperfine>,
  <https://github.com/watchexec/watchexec>, <https://biomejs.dev/>,
  <https://github.com/dandavison/delta>.

## Checking for Tools

Before installing anything, check whether it is already available:

```bash
command -v git jq python3 go
```

Note: `command -v` prints only the commands it finds and exits non-zero if any
are missing — compare the printed output against your full list, don't rely on
the exit code alone.

## Installing Tools with Nix

Use Nix rather than `apt`, `sudo`, or manual system-wide installation.

### Temporary Tool for One Command

Prefer this when a tool is only needed once:

```bash
nix-shell -p <package> --run '<command>'
```

Examples:

```bash
nix-shell -p imagemagick --run 'magick --version'
nix-shell -p python3Packages.requests --run 'python3 script.py'
nix-shell -p postgresql --run 'psql --version'
```

The package is available inside that command only. It is not added to the
default profile.

### Temporary Interactive Shell

Use this when several commands need the same extra tool:

```bash
nix-shell -p cargo rustc
```

When the shell exits, the package is no longer on `PATH`, although its store
paths may remain cached in `/nix`.

### Persistent Installation (use sparingly)

Only for tools needed across many separate tasks in this session:

```bash
nix profile install nixpkgs#<attribute>
```

If a tool is needed repeatedly across sessions, propose it as an image default
(see below) instead of relying on this.

## Finding Nix Package Names

The command name and the Nix package attribute are not always the same
(e.g., `yq` is the attribute `yq-go`; `delta` provides the `delta` command;
`clang-tools` provides `clangd`).

Search the configured channel:

```bash
nix search nixpkgs <keyword>
```

Or verify a specific attribute exists:

```bash
nix eval --raw nixpkgs#<attribute>.name
```

For browsing, use <https://search.nixos.org/packages>.

## What Should Be Temporary vs. Persistent

Use `nix-shell` for task-specific tools:

- Image conversion tools
- Database clients
- Cloud provider CLIs
- One-off data-processing utilities
- Specialized language runtimes
- Specialized profilers (e.g., `perf`)
- Temporary code generators

Tools used repeatedly across many tasks should be proposed for inclusion in
the image defaults rather than installed manually every time. The operator
maintains the default package list.

## Recording Newly Installed Tools

Whenever you install a tool that was not already available, record it for the
operator. The primary log lives at:

```text
/home/agent/Projects/AGENT_TOOL_NOTES.md
```

If the Projects directory is unavailable, use the fallback:

```text
/home/agent/.config/opencode/AGENT_TOOL_NOTES.md
```

Append entries in this format:

```markdown
## YYYY-MM-DD — `<package>`

- Nix package: `nixpkgs.<attribute>`
- Command: `<command>`
- Installation method: `nix-shell`, `nix profile`, or `nix-env`
- Scope: temporary or persistent
- Reason: <why the tool was needed>
- Recommendation: add to image defaults / keep temporary
```

Example (temporary):

```markdown
## 2026-09-17 — `imagemagick`

- Nix package: `nixpkgs.imagemagick`
- Command: `magick`
- Installation method: `nix-shell`
- Scope: temporary
- Reason: Convert one batch of images.
- Recommendation: keep temporary
```

Example (persistent, proposed as default):

```markdown
## 2026-09-17 — `shfmt`

- Nix package: `nixpkgs.shfmt`
- Command: `shfmt`
- Installation method: `nix profile`
- Scope: persistent
- Reason: Format shell scripts across multiple tasks.
- Recommendation: add to image defaults
```

Do not record tools that were already present in the image.

## Recommended Workflow

1. Check whether the required command is already available (`command -v`).
2. Consult "Available CLI Tools" — most needs are covered by preinstalled tools.
3. Search for the correct Nix package attribute if necessary.
4. Use `nix-shell` for one-off or task-specific tools; use `nix profile`
   sparingly for repeated needs.
5. Record every newly installed tool that was not already present.
6. Tell the operator when a tool appears to be a good default-image candidate.
7. Do not use `sudo`, `apt`, or modify the base operating system.

## Examples

Run a formatter without permanently installing it:

```bash
nix-shell -p shfmt --run 'shfmt -l -w .'
```

Use Python with a temporary dependency:

```bash
nix-shell -p python3Packages.requests --run 'python3 script.py'
```

Use an LSP server temporarily:

```bash
nix-shell -p nil --run 'nil --version'
```
