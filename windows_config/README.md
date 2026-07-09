# Windows reinstall assets

This folder stores reinstall-ready Windows configuration exports and Jarvis UI assets.

## Layout

- `configs/`: user-level tool configs copied from the current Windows install.
- `registry/`: exported Windows registry keys for cursors, sounds, themes, environment variables, Explorer and startup entries.
- `reports/`: selected restore reports such as PATH, winget packages, VS Code extensions and global packages.
- `utilities/`: AppGroup, Windhawk and Winaero Tweaker config/data exports.
- `scripts/`: restore notes and helper scripts.
- `jarvis_sounds/wav/`: active Windows sound scheme files.
- `jarvis_sounds/mp3/`: original Jarvis source audio from the Desktop Jarvis folder.
- `cursors/`: active cursor files.

## Restore Jarvis sounds

Run from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-jarvis-sounds.ps1
```

The script points current Windows sound events at `jarvis_sounds/wav` inside this repository.
