# Handy model switch

`Win+Shift+D` remains Handy's normal transcription shortcut.

`Win+Shift+F` switches between these installed profiles:

- Voxtral Mini 4B Realtime Q5_K_M with automatic language detection.
- Granite Speech 4.1 2B Q5_K_M with Japanese selected.

The hotkey updates Handy's settings while Handy is stopped, then starts Handy
again with `--start-hidden`. Restarting is required because Handy keeps its
settings in memory while it is running.

## Install

Run `install.ps1` from PowerShell. The installer copies the listener to
`%LOCALAPPDATA%\Egormity\HandyModelSwitch`, adds it to the current user's Startup
folder, and starts it immediately.

Run `handy-model-switch.ps1 -PrintStatus` to inspect the current and next
profile without changing anything.
