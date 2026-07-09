# Windows reinstall assets

This folder stores reinstall-ready Windows configuration exports and Jarvis UI assets.

## Layout

- `configs/`: user-level tool configs copied from the current Windows install.
- `registry/`: exported Windows registry keys for cursors, sounds, themes, environment variables, Explorer and startup entries.
- `reports/`: selected restore reports such as PATH, winget packages, VS Code extensions and global packages.
- `utilities/`: Windhawk and Winaero Tweaker config/data exports.
- `scripts/`: restore notes and helper scripts.
- `jarvis_sounds/wav/`: active Windows sound scheme files.
- `cursors/`: active cursor files.

## Restore Jarvis sounds

Run from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-jarvis-sounds.ps1
```

The script points current Windows sound events at `jarvis_sounds/wav` inside this repository.

## Restore terminal fonts

Run from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-terminal-fonts.ps1
```

The script sets Windows Terminal `profiles.defaults.font.face` to Segoe Print and applies matching classic console defaults for PowerShell and Command Prompt.

## Cursor pack manager

Cursor pack source links and local archives live in `cursor_packs/`.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\download-cursor-packs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -List
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -PackId pando -Register
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -PackId pando -Install
powershell -ExecutionPolicy Bypass -File .\scripts\switch-cursor-pack.ps1 -PackId pando -Apply
```

Or run `cursor_packs\open-cursor-menu.cmd` to pick a pack from a menu.

If a source site is unreachable, place the downloaded archive into `cursor_packs/archives/` with the pack id in the filename, then run the switcher with `-Extract`, `-Install`, or `-Apply`.

## Restore Windhawk taskbar auto-hide

Run after Windhawk is installed:

```powershell
reg import .\registry\taskbar-autohide.reg
reg import .\registry\taskbar-multimonitor.reg
reg import .\registry\windhawk.reg
powershell -ExecutionPolicy Bypass -File .\scripts\enable-windhawk-taskbar-per-monitor.ps1
```

The helper script registers Windhawk's `taskbar-auto-hide-per-monitor` mod for `explorer.exe`, enables Windows multi-monitor taskbar flags, and restarts Windhawk plus Explorer.
