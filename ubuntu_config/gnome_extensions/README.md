# Ubuntu GNOME extension preferences

Captured on 2026-08-06 from Ubuntu 26.04 with GNOME Shell 50.1.

## Contents

- `installed-extensions.tsv`: installed user and system extension inventory.
- `enabled-extensions.gvariant`: the exact `org.gnome.shell enabled-extensions` value.
- `preferences.dconf`: the exact `/org/gnome/shell/extensions/` preference subtree.
- `local_extensions/`: source for custom extensions that cannot be installed from an extension catalog.

The snapshot stores preferences, inventory, and the custom Handy status extension. It does not copy third-party extension source code or automatically install missing third-party extensions.

## Restore

Install the required extensions first, then run:

```sh
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a ubuntu_config/gnome_extensions/local_extensions/. ~/.local/share/gnome-shell/extensions/
dconf load /org/gnome/shell/extensions/ < ubuntu_config/gnome_extensions/preferences.dconf
gsettings set org.gnome.shell enabled-extensions "$(cat ubuntu_config/gnome_extensions/enabled-extensions.gvariant)"
```

Log out and back in after restoring so GNOME Shell reloads the extension set.

Some Ubuntu-provided extensions are enabled by the Ubuntu session rather than by the saved `enabled-extensions` list. Top Bar Organizer also records panel-item identifiers, including identifiers created dynamically by running applications; this file preserves the current value exactly.
