# egormity-tools

Local command-line tools for managing Egormity development workflows.

This repository is also the canonical store for personal computer configuration and restoration assets.

## Global Codex rules on Ubuntu

`GLOBAL_AGENTS.md` is the canonical global Codex instruction file. Keep Codex pointed at it with a symlink so the active rules and the tracked configuration cannot drift apart:

```sh
mkdir -p /home/egormity/.codex
ln -sfn /home/egormity/Desktop/egormity-tools/GLOBAL_AGENTS.md /home/egormity/.codex/AGENTS.md
```

## Current Tool

`egormity_git_tools` automates git workspace tasks for GitHub and GitLab accounts.

## Setup on Windows

Run this from the repository root:

```powershell
npm run setpath
```

After setup, new terminals can run:

```powershell
egormity_git_tools --help
egormity_cursors --help
egormity_startup --help
python -m egormity_git_tools --help
```

## Setup on macOS

Run this from the repository root:

```sh
npm run setpath
```

Then open a new terminal, or reload your shell profile:

```sh
source "<profile printed by egormity_packages/set_mac_paths.sh>"
```

After setup, new terminals can run:

```sh
egormity_git_tools --help
python3 -m egormity_git_tools --help
```

## Commands

```powershell
egormity_git_tools --version
egormity_git_tools --v
egormity_git_tools init_clis
egormity_git_tools get_account_info <urls> [filename] [path]
egormity_git_tools generate_agents <urls> [folder] [path]
egormity_git_tools clone_all <urls> [folder] [path]
egormity_git_tools init <urls> [folder] [path]
egormity_git_tools pull_all_current_bnach <path>
egormity_git_tools push_all_current_branch <path>
```

Cursor commands on Windows:

```powershell
egormity_cursors
egormity_cursors list
egormity_cursors apply <pack-id>
egormity_cursors register <pack-id>
egormity_cursors install <pack-id>
egormity_cursors extract <pack-id>
egormity_cursors source <pack-id>
egormity_cursors download
```

Startup commands on Windows:

```powershell
egormity_startup list
egormity_startup list --enabled
egormity_startup list --disabled
egormity_startup list --enabled --trim
egormity_startup enable <name-or-id> [location]
egormity_startup disable <name-or-id> [location]
egormity_startup add <name> <command> [--location <HKCU|HKLM|HKCU32|HKLM32>]
```

`HKLM`, `AllUsers` startup folders, Windows system tasks, and services require
an administrator terminal for enable, disable, or add operations.

`init_clis` verifies the GitHub CLI (`gh`) and GitLab CLI (`glab`). If either
CLI is missing, it prompts before installing it with `winget` on Windows or
Homebrew on macOS. Account lookup commands also prompt for missing provider
CLIs before fetching repository metadata. If Homebrew reports non-writable
Homebrew directories on macOS, the installer offers to repair those permissions
and retry. If a provider CLI is installed but not authenticated, the command
prompts to run the provider login flow before continuing.

For `clone_all`, the optional folder defaults to the account user or group name.

Multi-account commands accept comma or semicolon separated URLs. Quote the URL list in PowerShell:

```powershell
egormity_git_tools clone_all "https://github.com/org-a,https://gitlab.com/group-b" workspace C:\Users\kotla\Desktop\egormity-dev-env
egormity_git_tools get_account_info "https://github.com/org-a;https://gitlab.com/group-b" info.json .
egormity_git_tools generate_agents "https://github.com/org-a,https://gitlab.com/group-b" workspace .
```

## Development

Run basic verification after Python changes:

```powershell
python -m egormity_git_tools --help
python -m egormity_git_tools --version
python -m compileall egormity_packages\egormity_git_tools
```

Remove generated `__pycache__` directories before committing.
