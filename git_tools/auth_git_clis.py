import shutil
import subprocess
import sys

def is_installed(cmd):
    return shutil.which(cmd) is not None

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def ensure_all():
    if not is_installed("gh"):
        sys.exit("gh missing")
    if not is_installed("glab"):
        sys.exit("glab missing")

    if run(["gh","auth","status"]).returncode != 0:
        print("gh auth login required")
        input()

    if run(["glab","auth","status"]).returncode != 0:
        print("glab auth login required")
        input()

    print("CLI ready")