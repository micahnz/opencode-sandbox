# AGENTS.md (global environment)

<!-- Baked into the Docker image: keep it operator-agnostic. No operator
names or fixed project paths; discover them at runtime (see below). -->

This file applies to every opencode session on this machine, regardless of
project. Project-specific rules live in each repository's own AGENTS.md
(in the repository root).

## Environment

You are running as the unprivileged user `agent` inside a Debian-based
Docker container.

- User: `agent`
- Home directory: `/home/__USER__`
- Project workspaces: mounted 1:1 from the host at their original absolute
  paths (location is operator-specific — see "Workspace and WORKDIR")
- OpenCode configuration: `/home/__USER__/.config/opencode`
- Nix store: `/nix/store`
- Default shell: Bash
- Package manager: Nix (no `apt`, ever)
- Root and `sudo`: unavailable and not permitted

The container is disposable, but the operator persists these host-backed
paths between runs:

- the operator's project tree — all project checkouts, mounted 1:1 and
  shared with the operator (mount point varies by operator)
- `/home/__USER__/.config/opencode` — global opencode config
- `/home/__USER__/.local/share/opencode` — opencode sessions, database, worktree
- the openchamber state directory (operator-specific host path) — project
  registrations, chats, scheduled tasks
- `/nix`, `/home/__USER__/.cache/nix`, `/home/__USER__/.nix-defexpr`, `/home/__USER__/.nix-channels`

On every container start the entrypoint runs `nix-channel --update` and
`home-manager switch -b backup`, so available tooling can change between
sessions. Check first; never assume a tool that existed in a previous
session is still there (observed: artifacts compiled by GCC 16 while the
store currently carries only GCC 15.3).

Do not modify files outside the mounted project tree(s) and your home
directory (`/home/__USER__`) unless explicitly instructed.

## Workspace and WORKDIR

Project checkouts are mounted from the host at their original absolute
paths (host string == container string). They are not under `$HOME`; a
container home of `/home/__USER__` with projects elsewhere is normal.

**WORKDIR rule:** a session's working directory is the project path that
openchamber registered — read it from openchamber or from opencode's own
state; never guess or construct one. Use the registered absolute path
exactly. Do not substitute a path under `$HOME` or a relative path unless
that is literally the registered directory (scratch sessions are the
exception, see below).

The `opencode serve` daemon runs with cwd `/home/__USER__` (see
`/usr/local/bin/entrypoint.sh`); that is the daemon's launch directory, not
any session's workdir. Each session carries its own `directory`.

How to identify a session's workdir:

- inside a session: `pwd` or `readlink /proc/self/cwd`
- opencode's database (source of truth; container-local):

  ```sh
  opencode db "select id, worktree from project"
  opencode db "select s.id, s.directory, p.worktree from session s \
               left join project p on s.project_id = p.id"
  ```

- openchamber registers each project as a path-keyed file in its state
  directory: `projects/path_<base64>.json` (the state directory is a host
  bind mount; locate it from the mount table if not obvious). Decode a name
  with `printf '%s==' '<base64>' | base64 -d`.
- `project.id` and `ses_*` ids are hashes/opaque — never compute or guess
  them; use the directory string as the stable identifier.

Edge cases:

- openchamber "global" chat sessions use scratch directories under the
  openchamber state directory (`<state>/chats/<date>/session-<uuid>`); they
  map to opencode's `global` project (worktree `/`).
- sessions created with a git worktree run under
  `/home/__USER__/.local/share/opencode/worktree/<project-id>/...`.

Never move or rename a project mount: openchamber registrations and session
mappings are keyed by the path string.

## Toolchain (C/C++ and general)

- `make` and `gcc` are not on `PATH`. Verified workaround:
  `nix-shell -p gnumake gcc --run 'make ...'` (drop `--run` for an
  interactive shell). That shell also provides `grep`.
- Project Makefiles that hardcode `CC := gcc` work inside that nix-shell,
  or override on the command line (`make CC=<path>`).
- `clang`/`cc` (21.x), `clang-tidy`, `clang-format`, `cppcheck`, `valgrind`
  are installed. `gdb`, `strace`, `ltrace`, `perf` are not — fetch them
  with `nix-shell -p` when needed.
- `grep`, `sed`, `perl`, `python3`, `ssh`, `rsync` are NOT installed in the
  base environment. Scripts that assume POSIX userland can misbehave: e.g.
  `make test` targets that count `SKIP` lines with `grep -c` silently lose
  their skip accounting (they still print PASS). Run such targets as
  `nix-shell -p gnumake gcc --run 'make test'`, or run the test binaries
  directly.
- `home-manager packages` (the documented way to list installed packages)
  currently fails because it calls `grep`; wrap it:
  `nix-shell -p gnugrep --run 'home-manager packages'`.

## Git and GitHub

- No git identity is configured in this container. Commits fail until
  `git config --global user.name` / `user.email` are set; ask the operator
  which identity to use (`git log` shows the author of earlier commits).
- `gh` is installed but NOT authenticated, and `ssh` is missing, so
  repositories with SSH remotes cannot be fetched or pushed. This does not
  work until the operator runs `gh auth login` or installs an SSH client
  with keys. Do not promise to push; ask the operator.

## OpenCode config drift (verify before trusting)

- `opencode.jsonc` sets the bash tool shell to `/usr/bin/zsh`, which is not
  installed (commands fall back to Bash), and declares `mcp.kagi-mcp`
  pointing at `/usr/bin/kagi`, which does not exist.
- Files under `~/.config/opencode` are host-mounted and some appear managed
  by the operator's openchamber tooling (note the `*.openchamber.backup`
  files). Confirm before assuming an edit here persists.

## Core Principle: Context Economy

Prefer tools that produce compact, structured output (`rg`, `fd`, `jq`,
`sd`) over verbose equivalents (`grep`, `find`, `cat`, `sed`). Large outputs
waste context and slow everything down. Extract exactly the fields you need
rather than printing whole files.

## Available CLI Tools

Everything in this section is preinstalled via Home Manager. Do not install
these again. If a tool you need repeatedly is missing, propose it to the
operator (see "Recording Newly Installed Tools") rather than installing it
persistently yourself.

You can verify what's installed with `command -v <tool>` (see "Checking for
Tools"). `home-manager packages` needs a `grep` wrapper, shown above.

### Search & Discovery

- `rg` (ripgrep) — fast, gitignore-aware code search. Prefer over `grep`.
- `fd` — fast, gitignore-aware file finding. Prefer over `find`.
- `tree` — directory overview. Use to orient in unfamiliar code.
- `ast-grep` (`sg`) — structural code search/rewrite by AST pattern
  (`sg run -p 'PATTERN'`).
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
- `oxlint` / `oxfmt` / `biome` — TS/JS lint+format. Follow the repo's
  existing config; if none exists, default to `biome check`.
- `clang-tools` — provides `clangd`, `clang-format`, `clang-tidy` for C/C++.

### Platforms

- `gh` — GitHub CLI: PRs, issues, CI status; `gh api` + `jq` for raw
  queries. Auth is NOT currently configured (see "Git and GitHub").
- `go` (`go_latest`), `delve` (`dlv`), `gopls` — Go toolchain, debugger, LSP.
- `node` (`nodejs_26`), `bun`, `tsc` (`typescript`), `vtsls` — TS/JS
  runtimes, compiler, LSP.
- `go-jsonnet` — Jsonnet toolchain (`jsonnetfmt`, evaluation).
- `nixd` — Nix LSP.
- `opencode` — this agent.

### Getting Help

- `<tool> --help` first; `man <tool>` for full docs.
- To browse Nix package attributes: <https://search.nixos.org/packages>.
- Upstream docs: <https://github.com/BurntSushi/ripgrep>,
  <https://github.com/sharkdp/fd>, <https://ast-grep.github.io/>,
  <https://difftastic.wilfred.me.uk/>,
  <https://github.com/chmln/sd>, <https://jqlang.github.io/jq/>,
  <https://github.com/mikefarah/yq>, <https://cli.github.com/>,
  <https://github.com/boyter/scc>, <https://github.com/sharkdp/hyperfine>,
  <https://github.com/watchexec/watchexec>, <https://biomejs.dev/>,
  <https://github.com/dandavison/delta>.

## Checking for Tools

Before installing anything, check whether it is already available:

```bash
command -v git jq go
```

Note: `command -v` prints only the commands it finds and exits non-zero if
any are missing — compare the printed output against your full list, don't
rely on the exit code alone.

## Installing Tools with Nix

Use Nix rather than `apt`, `sudo`, or manual system-wide installation.

### Temporary Tool for One Command

Prefer this when a tool is only needed once:

```bash
nix-shell -p <package> --run '<command>'
```

Examples:

```bash
nix-shell -p gnumake gcc --run 'make test'
nix-shell -p python3 --run 'python3 script.py'
nix-shell -p gdb --run 'gdb --args ./build/<program> --foreground'
```

The package is available inside that command only. It is not added to the
default profile.

### Temporary Interactive Shell

Use this when several commands need the same extra tool:

```bash
nix-shell -p gnumake gcc
```

When the shell exits, the packages are no longer on `PATH`, although their
store paths may remain cached in `/nix`.

### Persistent Installation (use sparingly)

Only for tools needed across many separate tasks in this session:

```bash
nix profile install nixpkgs#<attribute>
```

If a tool is needed repeatedly across sessions, propose it as an image
default (see below) instead of relying on this.

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
- Debuggers (`gdb`, `strace`) and missing userland tools (`gnugrep`, `gnused`)
- Temporary code generators

Tools used repeatedly across many tasks should be proposed for inclusion in
the image defaults rather than installed manually every time. The operator
maintains the default package list.

## Recording Newly Installed Tools

Whenever you install a tool that was not already available, record it for
the operator. The primary log lives next to the project checkouts, in the
operator-visible project tree that contains a session's project directory
(the parent of the registered project path):

```text
<project-tree>/AGENT_TOOL_NOTES.md
```

If the project tree is unavailable, use the fallback:

```text
/home/__USER__/.config/opencode/AGENT_TOOL_NOTES.md
```

Append entries in this format:

```markdown
## YYYY-MM-DD — `<package>`

- Nix package: `nixpkgs.<attribute>`
- Command: `<command>`
- Installation method: `nix-shell`
- Scope: temporary or persistent
- Reason: <why the tool was needed>
- Recommendation: add to image defaults / keep temporary
```

Do not record tools that were already present in the image.

## Recommended Workflow

1. Check whether the required command is already available (`command -v`).
2. Consult "Available CLI Tools" — most needs are covered by preinstalled
   tools.
3. Search for the correct Nix package attribute if necessary.
4. Use `nix-shell` for one-off or task-specific tools; use `nix profile`
   sparingly for repeated needs.
5. Record every newly installed tool that was not already present.
6. Tell the operator when a tool appears to be a good default-image
   candidate.
7. Do not use `sudo`, `apt`, or modify the base operating system.
