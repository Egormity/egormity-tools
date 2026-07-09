#!/bin/sh
set -eu

repo_root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
package_root="$repo_root/egormity_packages"
bin_path="$package_root/bin"
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
old_start_marker="# >>> egormity-tools packages >>>"
old_end_marker="# <<< egormity-tools packages <<<"

if grep -Fq "$start_marker" "$profile_path"; then
    tmp_profile=$(mktemp)
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$profile_path" > "$tmp_profile"
    mv "$tmp_profile" "$profile_path"
    echo "egormity_git shell profile updated:"
else
    echo "egormity_git shell profile configured:"
fi

if grep -Fq "$old_start_marker" "$profile_path"; then
    tmp_profile=$(mktemp)
    awk -v start="$old_start_marker" -v end="$old_end_marker" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$profile_path" > "$tmp_profile"
    mv "$tmp_profile" "$profile_path"
fi

{
    printf '\n%s\n' "$start_marker"
    printf 'export PATH="%s:$PATH"\n' "$bin_path"
    printf 'export PYTHONPATH="%s${PYTHONPATH:+:$PYTHONPATH}"\n' "$package_root"
    printf '%s\n' "$end_marker"
} >> "$profile_path"

export PATH="$bin_path:$PATH"
export PYTHONPATH="$package_root${PYTHONPATH:+:$PYTHONPATH}"

echo "  Profile: $profile_path"
echo "  PATH: $bin_path"
echo "  PYTHONPATH: $package_root"
echo ""
echo "New terminals can run:"
echo "  egormity_git"
echo "  python3 -m egormity_git"
echo ""
echo "To update this terminal, run:"
echo "  source \"$profile_path\""
