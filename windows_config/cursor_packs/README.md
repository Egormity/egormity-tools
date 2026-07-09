# Cursor Packs

This folder stores optional Windows cursor packs and the scripts that make them switchable.

## Layout

- `manifest.json`: saved source list.
- `archives/`: original downloaded archives.
- `packs/<pack-id>/`: extracted cursor pack folders.
- `pages/`: downloaded source pages, when the source site is reachable.

## Commands

Run from `windows_config`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\download-cursor-packs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -List
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -PackId pando -Register
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -PackId pando -Install
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -PackId pando -Apply
```

Or open the menu:

```powershell
.\cursor_packs\open-cursor-menu.cmd
```

If the source site is unreachable, manually place downloaded `.zip`, `.rar`, or `.7z` files in `cursor_packs/archives/` using the pack id in the filename, then run `switch-cursor-pack.ps1 -PackId <id> -Extract`.

Some cursor packs include `.inf` files. Installing them adds named schemes to Windows Mouse Properties. Packs without an installer can still be registered or applied directly when their files use recognizable cursor names.

Currently downloaded and registered:

- Anathema Pink
- Crystal Clear v4.1
- Kami V2 - Paper White
- Marathon
- Marathon Bold
- Material Design Cursors Dark
- Monolith

Manual sources saved, but not listed as switchable until an archive is downloaded:

- Windows 11 Cursors Concept
- PandO
