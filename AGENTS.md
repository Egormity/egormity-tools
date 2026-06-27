# egormity-tools Agent Instructions

## Scope
- These instructions apply to the entire `egormity-tools` repository.
- Keep tool code under focused package folders. The current tool package is `egormity_git_tools`.
- Root-level scripts should be setup or orchestration scripts only.

## Development
- Keep command-line behavior stable and explicit.
- Add new tool commands through `egormity_git_tools/cli.py` unless a new package is clearly warranted.
- Put reusable command logic in separate modules instead of growing `cli.py` with implementation details.
- Keep generated files such as `__pycache__` out of commits.

## Verification
- Run `python -m egormity_git_tools --help` after CLI changes.
- Run `python -m egormity_git_tools --version` after version changes.
- Run `python -m compileall egormity_git_tools` after Python code changes, then remove generated cache files.

## Versioning
- Update `egormity_git_tools/version.py` when user-visible CLI behavior changes.
- Use simple semantic versions while this project is local: `MAJOR.MINOR.PATCH`.
