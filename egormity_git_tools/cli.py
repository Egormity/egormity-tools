import json
import os
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
    ("get_account_info <url> [filename] [path]", "Write account repository metadata to JSON."),
    ("generate_agents <url> [folder] [path]", "Generate an AGENTS.md navigation file for an account workspace."),
    ("clone_all <url> [folder] [path]", "Clone all repositories from a GitHub or GitLab account."),
    ("init <url> [folder] [path]", "Clone all repositories and generate an AGENTS.md navigation file."),
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
    if cmd in ("--version", "version"):
        print(f"egormity_git_tools {__version__}")
        return

    url = sys.argv[2] if len(sys.argv) > 2 else None

    arg2 = sys.argv[3] if len(sys.argv) > 3 else None
    arg3 = sys.argv[4] if len(sys.argv) > 4 else None

    if cmd == "init_clis":
        ensure_all()

    elif cmd == "get_account_info":
        require_url(cmd, url)
        info = get_info(url)

        filename = arg2 or "info.json"
        path = arg3 or "."

        os.makedirs(path, exist_ok=True)
        full = os.path.join(path, filename)

        with open(full,"w",encoding="utf-8") as f:
            json.dump(info, f, indent=2)

        print(full)

    elif cmd == "generate_agents":
        require_url(cmd, url)
        info = get_info(url)

        folder = arg2 or "workspace"
        path = arg3 or "."

        full_folder = os.path.join(path, folder)
        write_agents(info, full_folder)

        print(full_folder)

    elif cmd == "clone_all":
        require_url(cmd, url)
        folder = arg2
        path = arg3 or "."
        clone_all(url, folder, path)

    elif cmd == "init":
        require_url(cmd, url)
        info = get_info(url)
        folder = arg2 or info["name"]
        path = arg3 or "."

        full_folder = clone_all(url, folder, path, info=info)
        write_agents(info, full_folder)

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
    print("")
    print("Commands:")
    for command, description in COMMANDS:
        print(f"  {command:<40} {description}")
    print("")
    print("Options:")
    print("  -h, --help                              Show this help message.")
    print("  --version                               Show the installed tool version.")

def require_url(cmd, url):
    if not url:
        raise SystemExit(f"Usage: python -m egormity_git_tools {cmd} <url> [arg2] [arg3]")

def require_path(cmd, path):
    if not path:
        raise SystemExit(f"Usage: python -m egormity_git_tools {cmd} <path>")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        raise SystemExit(f"error: {exc}")
