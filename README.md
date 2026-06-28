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
egormity_git_tools get_account_info <urls> [filename] [path]
egormity_git_tools generate_agents <urls> [folder] [path]
egormity_git_tools clone_all <urls> [folder] [path]
egormity_git_tools init <urls> [folder] [path]
egormity_git_tools pull_all_current_bnach <path>
egormity_git_tools push_all_current_branch <path>
```

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
python -m compileall egormity_git_tools
```

Remove generated `__pycache__` directories before committing.
