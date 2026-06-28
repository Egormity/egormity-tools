import json
import os
import re
import sys

try:
    from .version import __version__
    from .auth_git_clis import ensure_all
    from .clone_all_repos_from_url import clone_all
    from .generate_agents_file import write as write_agents
    from .get_account_info_from_url import get_info
    from .push_all_current_branch import push_all_current_branch
except ImportError:
    from version import __version__
    from auth_git_clis import ensure_all
    from clone_all_repos_from_url import clone_all
    from generate_agents_file import write as write_agents
    from get_account_info_from_url import get_info
    from push_all_current_branch import push_all_current_branch


COMMANDS = (
    ("init_clis", "Verify required GitHub and GitLab CLIs are installed and authenticated."),
    ("get_account_info <urls> [filename] [path]", "Write account repository metadata to JSON."),
    ("generate_agents <urls> [folder] [path]", "Generate an AGENTS.md navigation file for account workspaces."),
    ("clone_all <urls> [folder] [path]", "Clone all repositories from GitHub or GitLab accounts."),
    ("init <urls> [folder] [path]", "Clone all repositories and generate AGENTS.md navigation files."),
    ("push_all_current_branch <path>", "Push the current branch for every repository under a path."),
)


def main():
    if len(sys.argv) < 2:
        print_help()
        return

    cmd = sys.argv[1]
    if cmd in ("--help", "-h", "help"):
        print_help()
        return
    if cmd in ("--version", "--v", "version"):
        print(f"egormity_git_tools {__version__}")
        return

    url = sys.argv[2] if len(sys.argv) > 2 else None

    arg2 = sys.argv[3] if len(sys.argv) > 3 else None
    arg3 = sys.argv[4] if len(sys.argv) > 4 else None

    if cmd == "init_clis":
        ensure_all()

    elif cmd == "get_account_info":
        require_url(cmd, url)
        infos = get_infos(url)

        filename = arg2 or "info.json"
        path = arg3 or "."

        os.makedirs(path, exist_ok=True)
        full = os.path.join(path, filename)

        with open(full,"w",encoding="utf-8") as f:
            json.dump(single_or_many(infos), f, indent=2)

        print(full)

    elif cmd == "generate_agents":
        require_url(cmd, url)
        infos = get_infos(url)

        folder = arg2 or "workspace"
        path = arg3 or "."

        full_folder = os.path.join(path, folder)
        write_agents(combine_infos(infos, folder), full_folder)

        print(full_folder)

    elif cmd == "clone_all":
        require_url(cmd, url)
        folder = arg2
        path = arg3 or "."
        clone_all_urls(url, folder, path)

    elif cmd == "init":
        require_url(cmd, url)
        path = arg3 or "."
        infos = get_infos(url)

        if len(infos) == 1:
            folder = arg2 or infos[0]["name"]
            full_folder = clone_all(url, folder, path, info=infos[0])
            write_agents(infos[0], full_folder)
        else:
            folder = arg2 or "workspace"
            full_folder = os.path.join(path, folder)
            os.makedirs(full_folder, exist_ok=True)
            for info in infos:
                account_folder = clone_all(info["link"], info["name"], full_folder, info=info)
                write_agents(info, account_folder)
            write_agents(combine_infos(infos, folder), full_folder)

        print(full_folder)

    elif cmd == "push_all_current_branch":
        require_path(cmd, url)
        repos = push_all_current_branch(url)
        print(f"Pushed {len(repos)} repositories")

    else:
        print(f"Unknown command: {cmd}")
        print("Run `python -m egormity_git_tools --help` for usage.")


def print_help():
    print(f"egormity_git_tools {__version__}")
    print("")
    print("Usage:")
    print("  egormity_git_tools <command> [args]")
    print("  python -m egormity_git_tools <command> [args]")
    print("  Use comma or semicolon separated URLs for multi-account commands.")
    print("")
    print("Commands:")
    for command, description in COMMANDS:
        print(f"  {command:<40} {description}")
    print("")
    print("Options:")
    print("  -h, --help                              Show this help message.")
    print("  --version, --v                          Show the installed tool version.")


def parse_urls(urls):
    parsed = [url.strip() for url in re.split(r"[;,]", urls) if url.strip()]
    if not parsed:
        raise ValueError("at least one URL is required")
    return parsed


def get_infos(urls):
    return [get_info(url) for url in parse_urls(urls)]


def single_or_many(items):
    if len(items) == 1:
        return items[0]
    return items


def combine_infos(infos, name):
    repos = []
    for info in infos:
        repos.extend(info["repos"])
    return {
        "name": name,
        "link": ", ".join(info["link"] for info in infos),
        "repos": repos,
    }


def clone_all_urls(urls, folder, path):
    infos = get_infos(urls)
    if len(infos) == 1:
        return clone_all(infos[0]["link"], folder, path, info=infos[0])

    workspace = os.path.join(path, folder or "workspace")
    os.makedirs(workspace, exist_ok=True)
    cloned = []
    for info in infos:
        cloned.append(clone_all(info["link"], info["name"], workspace, info=info))
    return cloned

def require_url(cmd, url):
    if not url:
        raise SystemExit(f"Usage: python -m egormity_git_tools {cmd} <urls> [arg2] [arg3]")

def require_path(cmd, path):
    if not path:
        raise SystemExit(f"Usage: python -m egormity_git_tools {cmd} <path>")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        raise SystemExit(f"error: {exc}")
