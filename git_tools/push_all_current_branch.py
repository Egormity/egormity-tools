import subprocess
from pathlib import Path


def is_git_repo(path):
    return path.is_dir() and (path / ".git").exists()


def discover_repositories(base):
    if is_git_repo(base):
        return [base]

    repos = []
    stack = [base]
    while stack:
        current = stack.pop()
        for child in current.iterdir():
            if not child.is_dir():
                continue
            if child.name == ".git":
                continue
            if is_git_repo(child):
                repos.append(child)
            else:
                stack.append(child)

    return sorted(repos)


def push(repo_path):
    print(f"Pushing {repo_path}")
    result = subprocess.run(["git", "push"], cwd=repo_path)
    if result.returncode != 0:
        raise RuntimeError(f"git push failed in {repo_path}")


def push_all_current_branch(path):
    base = Path(path).expanduser().resolve()
    if not base.exists():
        raise FileNotFoundError(f"folder does not exist: {base}")
    if not base.is_dir():
        raise NotADirectoryError(f"path is not a folder: {base}")

    repos = discover_repositories(base)
    if not repos:
        print(f"No git repositories found in {base}")
        return []

    for repo in repos:
        push(repo)

    return repos
