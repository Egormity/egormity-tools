import json
import shutil
import subprocess
from urllib.parse import urlparse


class CommandError(RuntimeError):
    def __init__(self, cmd, output):
        self.cmd = cmd
        self.output = output.strip()
        super().__init__(f"{' '.join(cmd)} failed: {self.output}")


def run(cmd):
    if shutil.which(cmd[0]) is None:
        raise RuntimeError(f"required CLI not found on PATH: {cmd[0]}")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise CommandError(cmd, result.stderr or result.stdout)
    return result.stdout

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

def gitlab_user(user):
    return json.loads(run([
        "glab","repo","list","--user",user,"-F","json"
    ]))


def gitlab_group(group):
    return json.loads(run([
        "glab","repo","list","--group",group,"--include-subgroups","-F","json"
    ]))


def gitlab(namespace):
    try:
        return gitlab_user(namespace)
    except CommandError as user_error:
        try:
            return gitlab_group(namespace)
        except CommandError as group_error:
            raise RuntimeError(
                f"GitLab namespace not found or not accessible as user or group: {namespace}. "
                f"user lookup: {user_error.output}; group lookup: {group_error.output}"
            ) from group_error


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
