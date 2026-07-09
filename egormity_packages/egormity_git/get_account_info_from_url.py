import json
import shutil
import subprocess
from urllib.parse import quote, urlparse

try:
    from .auth_git_clis import TOOLS, ensure_ready
except ImportError:
    from auth_git_clis import TOOLS, ensure_ready


class CommandError(RuntimeError):
    def __init__(self, cmd, output):
        self.cmd = cmd
        self.output = output.strip() or "no output"
        super().__init__(f"{' '.join(cmd)} failed: {self.output}")


def run(cmd):
    if cmd[0] in TOOLS:
        ensure_ready(cmd[0])
    elif shutil.which(cmd[0]) is None:
        raise RuntimeError(f"required CLI not found on PATH: {cmd[0]}")

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

    host = p.netloc.lower()
    if "github.com" in host:
        return "github", parts[0]
    if "gitlab.com" in host:
        return "gitlab", "/".join(parts)
    raise ValueError(f"unsupported account provider in URL: {url}")


def parse_json_output(cmd, output):
    try:
        return json.loads(output)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"{cmd[0]} returned invalid JSON while fetching account info: {exc}"
        ) from exc

def github(user):
    cmd = [
        "gh","repo","list",user,
        "--limit","200",
        "--json","nameWithOwner,url"
    ]
    return parse_json_output(cmd, run(cmd))

def glab_api(endpoint, paginate=False):
    cmd = ["glab", "api", endpoint]
    if paginate:
        cmd.extend(["--paginate", "--output", "json"])
    return parse_json_output(cmd, run(cmd))


def gitlab_user(user):
    users = glab_api(f"users?username={quote(user, safe='')}")
    if not users:
        raise RuntimeError(f"GitLab user not found or not accessible: {user}")

    user_id = users[0]["id"]
    return glab_api(f"users/{user_id}/projects?per_page=100", paginate=True)


def gitlab_group(group):
    group_path = quote(group, safe="")
    return glab_api(f"groups/{group_path}/projects?include_subgroups=true&per_page=100", paginate=True)


def gitlab_accessible_namespace(namespace):
    projects = glab_api("projects?membership=true&per_page=100", paginate=True)
    return [
        project
        for project in projects
        if is_project_in_namespace(project, namespace)
    ]


def is_project_in_namespace(project, namespace):
    project_namespace = project.get("namespace") or {}
    full_path = project_namespace.get("full_path") or project_namespace.get("path")
    if not full_path:
        return False

    normalized_namespace = namespace.strip("/").lower()
    normalized_full_path = full_path.strip("/").lower()
    return (
        normalized_full_path == normalized_namespace
        or normalized_full_path.startswith(f"{normalized_namespace}/")
    )


def gitlab(namespace):
    try:
        return gitlab_user(namespace)
    except (CommandError, RuntimeError) as user_error:
        try:
            return gitlab_group(namespace)
        except CommandError as group_error:
            try:
                accessible_projects = gitlab_accessible_namespace(namespace)
                if accessible_projects:
                    return accessible_projects
            except (CommandError, RuntimeError) as accessible_error:
                accessible_lookup = command_error_output(accessible_error)
            else:
                accessible_lookup = "no matching membership projects"

            raise RuntimeError(
                f"GitLab namespace not found or not accessible as user, group, or accessible namespace: {namespace}. "
                f"user lookup: {command_error_output(user_error)}; "
                f"group lookup: {command_error_output(group_error)}; "
                f"accessible namespace lookup: {accessible_lookup}"
            ) from group_error


def command_error_output(error):
    return getattr(error, "output", str(error))


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
                "link": r.get("http_url_to_repo") or r.get("web_url"),
                "provider":"gitlab"
            })

    return {
        "name": user,
        "link": url,
        "repos": repos
    }
