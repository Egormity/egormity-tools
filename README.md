# egormity-tools

Local command-line tools for managing Egormity development workflows.

## Current Tool

`egormity_git_tools` automates git workspace tasks for GitHub and GitLab accounts.

## Setup on Windows

Run this from the repository root:

```powershell
.\set_windows_paths.ps1
```

After setup, new terminals can run:

```powershell
egormity_git_tools --help
python -m egormity_git_tools --help
```

## Commands

```powershell
egormity_git_tools --version
egormity_git_tools --v
egormity_git_tools init_clis
egormity_git_tools get_account_info <url> [filename] [path]
egormity_git_tools generate_agents <url> [folder] [path]
egormity_git_tools clone_all <url> [folder] [path]
egormity_git_tools init <url> [folder] [path]
egormity_git_tools push_all_current_branch <path>
```

## Development

Run basic verification after Python changes:

```powershell
python -m egormity_git_tools --help
python -m egormity_git_tools --version
python -m compileall egormity_git_tools
```

Remove generated `__pycache__` directories before committing.
