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

## Checking for Tools

Before installing a tool, check whether it is already available:

```bash
command -v <commands>
```

Examples:

```bash
# check one at a time
command -v git
command -v jq
command -v python3
command -v go

# chuck multiple at once
command -v git gq python3 go
```

## Installing Tools with Nix

Use Nix rather than `apt`, `sudo`, or manual system-wide installation.

### Common tools are installed by default

Commonly used tools are installed by default via home manager, you can check
for already installed packages:

```bash
home-manager packages
```

### Temporary Tool for One Command

Prefer this when a tool is only needed once:

```bash
nix-shell -p <package> --run '<command>'
```

Examples:

```bash
nix-shell -p go --run 'go version'
nix-shell -p imagemagick --run 'magick --version'
nix-shell -p python3Packages.requests --run 'python3 script.py'
```

The package becomes available inside that command only. It is not added to the default profile.

### Temporary Interactive Shell

Use this when several commands need the same extra tool:

```bash
nix-shell -p <package>
```

Example:

```bash
nix-shell -p cargo rustc
```

When the shell exits, the package is no longer on `PATH`, although its store paths may remain cached in `/nix`.

## Finding Nix Package Names

The command name and Nix package attribute are not always the same.

Search the configured channel:

```bash
nix search nixpkgs <keyword>
```

Examples:

```bash
nix search nixpkgs image magick
nix search nixpkgs language server
nix search nixpkgs yaml
```

Commonly used tools are installed by default via home manager, you can also inspect available package attributes:

```bash
home-manager packages
```

## Tools That Should Usually Be Temporary

Use `nix-shell` for tools needed only for a particular task, such as:

- Image conversion tools
- Database clients
- Cloud provider CLIs
- One-off data-processing utilities
- Specialized language runtimes
- Benchmarking and profiling tools
- Temporary code generators

Example:

```bash
nix-shell -p postgresql --run 'psql --version'
```

## Tools That May Be Good Default Candidates

Consider persistent installation only for tools used repeatedly across many tasks, such as:

- `git`
- `ripgrep`
- `fd`
- `jq`
- `curl`
- `wget`
- `shellcheck`
- `shfmt`
- `python3`
- `nodejs`
- Common language compilers or LSP servers

The operator maintains the image's default package list. Repeatedly needed tools should be proposed for inclusion in the image rather than installed manually every time.

## Recording Newly Installed Tools

Whenever you install a tool that was not already available, record it for the operator.

First check whether the command already exists:

```bash
command -v <command>
```

If it is missing and you install it, append a note to:

```text
/home/agent/Projects/AGENT_TOOL_NOTES.md
```

This file is in the mounted workspace and can be reviewed by the operator.

Use this format:

```markdown
## YYYY-MM-DD — `<package>`

- Nix package: `nixpkgs.<attribute>`
- Command: `<command>`
- Installation method: `nix-shell` or `nix-env`
- Scope: temporary or persistent
- Reason: <why the tool was needed>
- Recommendation: add to image defaults / keep temporary
```

Example:

```markdown
## 2026-09-17 — `shellcheck`

- Nix package: `nixpkgs.shellcheck`
- Command: `shellcheck`
- Installation method: `nix-env`
- Scope: persistent
- Reason: Validate shell scripts in the project.
- Recommendation: add to image defaults
```

For a temporary tool:

```markdown
## 2026-09-17 — `imagemagick`

- Nix package: `nixpkgs.imagemagick`
- Command: `magick`
- Installation method: `nix-shell`
- Scope: temporary
- Reason: Convert one batch of images.
- Recommendation: keep temporary
```

If `/home/agent/Projects` is unavailable, record the note in:

```text
/home/agent/AGENT_TOOL_NOTES.md
```

Do not record tools that were already present in the image.

## Recommended Workflow

1. Check whether the required command is already available.
2. Search for the correct Nix package attribute if necessary.
3. Use `nix-shell` for one-off or task-specific tools.
4. Record every newly installed tool that was not already present.
5. Tell the operator when a tool appears to be a good default-image candidate.
6. Do not try to use `sudo`, `apt`, or modify the base operating system.

## Examples

Run Go without permanently installing it:

```bash
nix-shell -p go_latest --run 'go test ./...'
```

Use Python with a temporary dependency:

```bash
nix-shell -p python3Packages.requests --run 'python3 script.py'
```

Use an LSP server temporarily:

```bash
nix-shell -p nil --run 'nil --version'
```
