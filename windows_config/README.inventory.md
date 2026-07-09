# Windows reinstall inventory

Collected: 2026-07-03 22:49:28
Computer: EGORMITY
User: kotla

## Contents

- reports: system reports, installed programs, package managers, PATH, dev tool versions, global packages, WSL status.
- configs: copied safe user configs for Git, SSH public/config files, PowerShell, Windows Terminal, VS Code if present, PowerToys if present, Windows themes if present.
- registry: exported registry keys for appearance, sounds, cursors, fonts, environment variables, Explorer and startup entries.
- scripts: restore notes and commands.

## Security note

Private SSH keys, browser profiles, passwords, cookies, and credential stores were intentionally not copied.
Environment variable report is redacted by variable name/value patterns. Raw .npmrc was not copied; only .npmrc.redacted is kept if it exists.
Review registry exports before sharing this folder, because Windows environment keys may still contain local machine-specific values.

## Fast restore pointers

- Winget import file: reports/winget-packages.json
- VS Code extensions: reports/vscode-extensions.txt
- User PATH: reports/path-user.txt
- Machine PATH: reports/path-machine.txt
- Windows Terminal settings: configs/windows-terminal/settings.json
- Restore notes: scripts/restore-notes.ps1
- Windhawk taskbar auto-hide prerequisite: registry/taskbar-autohide.reg
- Windhawk secondary monitor taskbar auto-hide helper: registry/taskbar-multimonitor.reg and scripts/enable-windhawk-taskbar-per-monitor.ps1
- Windhawk mod settings: registry/windhawk.reg and utilities/Windhawk_Config/mod-settings.md
- Segoe Print font restore: scripts/apply-segoe-print-fonts.ps1 plus registry/fonts-*.reg. Run elevated for machine-wide app font aliases.
- Terminal font restore: scripts/apply-terminal-fonts.ps1, configs/windows-terminal/settings.json, and registry/console-fonts.reg.
- Cursor pack switcher: cursor_packs/ plus scripts/switch-cursor-pack.ps1 and scripts/cursor-pack-menu.ps1

