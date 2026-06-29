import getpass
import re
import shutil
import subprocess
import sys

TOOLS = {
    "gh": {
        "name": "GitHub CLI",
        "winget_id": "GitHub.cli",
        "brew_package": "gh",
    },
    "glab": {
        "name": "GitLab CLI",
        "winget_id": "GitLab.GitLabCLI",
        "brew_package": "glab",
    },
}


def is_installed(cmd):
    return shutil.which(cmd) is not None


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def run_interactive(cmd):
    return subprocess.run(cmd)


def run_captured(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def ensure_all():
    ensure_installed("gh")
    ensure_installed("glab")

    if run(["gh", "auth", "status"]).returncode != 0:
        print("gh auth login required")
        input()

    if run(["glab", "auth", "status"]).returncode != 0:
        print("glab auth login required")
        input()

    print("CLI ready")


def ensure_installed(cmd):
    if is_installed(cmd):
        return

    tool = TOOLS[cmd]
    if not prompt_yes_no(f"{tool['name']} ({cmd}) is not installed. Download and install it now?"):
        sys.exit(f"{cmd} missing")

    installer = installer_command(tool)
    if not installer:
        sys.exit(
            f"{cmd} missing and automatic installation is not configured for {sys.platform}"
        )

    print(f"Installing {tool['name']}...")
    result = install_tool(installer)
    if result.returncode != 0:
        sys.exit(f"{cmd} installation failed with exit code {result.returncode}")

    if not is_installed(cmd):
        sys.exit(
            f"{cmd} installation finished, but the command is still not available. "
            "Open a new terminal or update PATH, then run init_clis again."
        )


def installer_command(tool):
    if sys.platform == "win32":
        if not is_installed("winget"):
            return None
        return [
            "winget",
            "install",
            "--id",
            tool["winget_id"],
            "--exact",
            "--source",
            "winget",
            "--accept-package-agreements",
            "--accept-source-agreements",
        ]

    if sys.platform == "darwin":
        if not is_installed("brew"):
            return None
        return ["brew", "install", tool["brew_package"]]

    return None


def install_tool(installer):
    if sys.platform == "darwin" and installer[:2] == ["brew", "install"]:
        return install_with_homebrew(installer)
    return run_interactive(installer)


def install_with_homebrew(installer):
    result = run_captured_printing(installer)
    if result.returncode == 0:
        return result

    paths = homebrew_unwritable_paths(process_output(result))
    if not paths:
        return result

    print("")
    print("Homebrew reported non-writable directories:")
    for path in paths:
        print(f"- {path}")

    user = getpass.getuser()
    repair = (
        "Run Homebrew permission repair and retry? "
        f"This will run `sudo chown -R {user} <path>` and `chmod u+w <path>`."
    )
    if not prompt_yes_no(repair):
        return result

    if not repair_homebrew_permissions(paths, user):
        return result

    print("Retrying Homebrew install...")
    return run_captured_printing(installer)


def run_captured_printing(cmd):
    result = run_captured(cmd)
    print_process_output(result)
    return result


def print_process_output(result):
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)


def process_output(result):
    return "\n".join(part for part in (result.stdout, result.stderr) if part)


def homebrew_unwritable_paths(output):
    if "directories are not writable by your user" not in output:
        return []

    paths = []
    for line in output.splitlines():
        candidate = line.strip()
        if is_homebrew_path(candidate):
            paths.append(candidate)
    return paths


def is_homebrew_path(path):
    return bool(re.match(r"^/(usr/local|opt/homebrew)(/[^`'\";&|<> ]+)+$", path))


def repair_homebrew_permissions(paths, user):
    for path in paths:
        chown = run_interactive(["sudo", "chown", "-R", user, path])
        if chown.returncode != 0:
            print(f"Failed to update ownership for {path}.", file=sys.stderr)
            return False

        chmod = run_interactive(["chmod", "u+w", path])
        if chmod.returncode != 0:
            print(f"Failed to add user write permission for {path}.", file=sys.stderr)
            return False

    return True


def prompt_yes_no(message):
    while True:
        try:
            answer = input(f"{message} [y/N]: ").strip().lower()
        except EOFError:
            return False

        if answer in ("y", "yes"):
            return True
        if answer in ("", "n", "no"):
            return False

        print("Please answer yes or no.")
