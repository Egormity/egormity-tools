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
    result = run_interactive(installer)
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
