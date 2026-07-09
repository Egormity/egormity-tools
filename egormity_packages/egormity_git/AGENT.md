# egormity_git Agent Notes

## Purpose
- `egormity_git` is a local command-line tool package for git workspace automation.
- It is intended to be runnable from anywhere after `scripts/set_windows_paths.ps1` has configured `PATH` and `PYTHONPATH`.

## Public Entry Points
- Direct command: `egormity_git`
- Module command: `python -m egormity_git`
- Windows shim: `egormity_packages/bin/egormity_git.cmd`

## CLI Conventions
- Keep `--help`, `help`, `-h`, and no-argument output useful and up to date.
- Keep `--version` and `--v` wired to `egormity_git/version.py`.
- Multi-account commands accept comma or semicolon separated URL lists as the first argument.
- GitLab account lookup should support both users and groups.
- Prefer adding command implementations as separate modules and dispatching to them from `cli.py`.

## Current Commands
- `init_clis`
- `get_account_info`
- `generate_agents`
- `clone_all`
- `init`
- `pull_all_current_bnach`
- `push_all_current_branch`
