# egormity_git_tools Agent Notes

## Purpose
- `egormity_git_tools` is a local command-line tool package for git workspace automation.
- It is intended to be runnable from anywhere after `set_windows_paths.ps1` has configured `PATH` and `PYTHONPATH`.

## Public Entry Points
- Direct command: `egormity_git_tools`
- Module command: `python -m egormity_git_tools`
- Windows shim: `bin/egormity_git_tools.cmd`

## CLI Conventions
- Keep `--help`, `help`, `-h`, and no-argument output useful and up to date.
- Keep `--version` and `--v` wired to `egormity_git_tools/version.py`.
- Multi-account commands accept comma or semicolon separated URL lists as the first argument.
- Prefer adding command implementations as separate modules and dispatching to them from `cli.py`.

## Current Commands
- `init_clis`
- `get_account_info`
- `generate_agents`
- `clone_all`
- `init`
- `push_all_current_branch`
