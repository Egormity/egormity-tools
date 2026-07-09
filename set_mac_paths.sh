#!/bin/sh
set -eu

repo_root=$(CDPATH= cd "$(dirname "$0")" && pwd)
bin_path="$repo_root/bin"
profile_path=${SHELL_PROFILE:-}

if [ -z "$profile_path" ]; then
    shell_name=$(basename "${SHELL:-}")
    case "$shell_name" in
        zsh)
            profile_path="$HOME/.zshrc"
            ;;
        bash)
            profile_path="$HOME/.bashrc"
            ;;
        *)
            profile_path="$HOME/.profile"
            ;;
    esac
fi

mkdir -p "$(dirname "$profile_path")"
touch "$profile_path"

start_marker="# >>> egormity-tools >>>"
end_marker="# <<< egormity-tools <<<"

if grep -Fq "$start_marker" "$profile_path"; then
    tmp_profile=$(mktemp)
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$profile_path" > "$tmp_profile"
    mv "$tmp_profile" "$profile_path"
    echo "egormity_git_tools shell profile updated:"
else
    echo "egormity_git_tools shell profile configured:"
fi

{
    printf '\n%s\n' "$start_marker"
    printf 'export PATH="%s:$PATH"\n' "$bin_path"
    printf 'export PYTHONPATH="%s${PYTHONPATH:+:$PYTHONPATH}"\n' "$repo_root"
    printf '%s\n' "$end_marker"
} >> "$profile_path"

export PATH="$bin_path:$PATH"
export PYTHONPATH="$repo_root${PYTHONPATH:+:$PYTHONPATH}"

echo "  Profile: $profile_path"
echo "  PATH: $bin_path"
echo "  PYTHONPATH: $repo_root"
echo ""
echo "New terminals can run:"
echo "  egormity_git_tools"
echo "  python3 -m egormity_git_tools"
echo ""
echo "To update this terminal, run:"
echo "  source \"$profile_path\""
