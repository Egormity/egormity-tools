import json
import shutil
import subprocess
from urllib.parse import urlparse

def run(cmd):
    if shutil.which(cmd[0]) is None:
        raise RuntimeError(f"required CLI not found on PATH: {cmd[0]}")

    return subprocess.check_output(cmd, text=True)

def parse(url):
    if "://" not in url:
        url = f"https://{url}"

    p = urlparse(url)
    parts = [x for x in p.path.split('/') if x]
    if not parts:
        raise ValueError(f"account url has no user or organization path: {url}")

    user = parts[0]
    host = p.netloc.lower()
    if "github.com" in host:
        return "github", user
    if "gitlab.com" in host:
        return "gitlab", user
    raise ValueError("unsupported")

def github(user):
    return json.loads(run([
        "gh","repo","list",user,
        "--limit","200",
        "--json","nameWithOwner,url"
    ]))

def gitlab(user):
    return json.loads(run([
        "glab","repo","list","--user",user,"-F","json"
    ]))

def get_info(url):
    provider, user = parse(url)

    if provider == "github":
        repos = [{"name": r["nameWithOwner"], "link": r["url"], "provider":"github"} for r in github(user)]
    else:
        raw = gitlab(user)
        repos = []
        for r in raw:
            repos.append({
                "name": r.get("path_with_namespace") or r.get("name"),
                "link": r.get("web_url") or r.get("http_url_to_repo"),
                "provider":"gitlab"
            })

    return {
        "name": user,
        "link": url,
        "repos": repos
    }
