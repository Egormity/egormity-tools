import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

try:
    from .get_account_info_from_url import get_info
except ImportError:
    from get_account_info_from_url import get_info


def repo_path(repo, base, account_name):
    parts = [part for part in repo["name"].split("/") if part]
    if parts and parts[0].lower() == account_name.lower():
        parts = parts[1:]
    if not parts:
        parts = [repo["name"]]
    return base.joinpath(*parts)


def clone(repo, base, account_name):
    path = repo_path(repo, base, account_name)

    if path.exists():
        return path

    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "clone", repo["link"], str(path)], check=True)
    return path


def default_output_folder(info):
    return info["name"].split("/", 1)[0]


def clone_all(url, output_folder=None, base_path=".", info=None):
    info = info or get_info(url)

    base_dir = Path(base_path)
    folder = base_dir / (output_folder or default_output_folder(info))
    folder.mkdir(parents=True, exist_ok=True)

    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = [ex.submit(clone, r, folder, info["name"]) for r in info["repos"]]
        for future in futures:
            future.result()

    return folder
