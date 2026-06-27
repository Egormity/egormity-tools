import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from .get_account_info_from_url import get_info

def clone(repo, base):
    name = repo["name"].split("/")[-1]
    path = base / name

    if path.exists():
        return path

    subprocess.run(["git", "clone", repo["link"], str(path)], check=True)
    return path

def clone_all(url, output_folder=None, base_path=".", info=None):
    info = info or get_info(url)

    base_dir = Path(base_path)
    folder = base_dir / (output_folder or info["name"])
    folder.mkdir(parents=True, exist_ok=True)

    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = [ex.submit(clone, r, folder) for r in info["repos"]]
        for future in futures:
            future.result()

    return folder
