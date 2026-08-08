# Handy model switch

`Win+Shift+D` remains Handy's normal transcription shortcut.

`Win+Shift+F` switches between these installed profiles:

- Voxtral Mini 4B Realtime Q5_K_M with automatic language detection.
- Granite Speech 4.1 2B Q5_K_M with Japanese selected.

The hotkey updates Handy's settings while Handy is stopped, then starts Handy
again with `--start-hidden`. Restarting is required because Handy keeps its
settings in memory while it is running.

Two taskbar notification-area indicators are installed alongside the hotkey:

- `A` is gray while Caps Lock is off and green while Caps Lock is on.
- `4B` identifies Voxtral with automatic language detection; `2B` identifies
  Granite with Japanese selected. Hover over it for the full profile name.

The indicators update live. Their shared context menu includes an exit command.
Windows may initially place new notification icons in the overflow menu; they
can be dragged onto the visible taskbar tray once.

## Install

Run `install.ps1` from PowerShell. The installer copies the listener to
`%LOCALAPPDATA%\Egormity\HandyModelSwitch`, adds it to the current user's Startup
folder, and starts the hotkey listener and both indicators immediately.

Run `handy-model-switch.ps1 -PrintStatus` to inspect the current and next
profile without changing anything.

Run `handy-taskbar-indicators.ps1 -PrintStatus` to inspect the two indicator
states without opening the taskbar icons.
