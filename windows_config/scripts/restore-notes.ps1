# Restore checklist

# Run selected commands manually after reinstall. Review paths first.

## Winget packages
winget import --import-file ".\reports\winget-packages.json" --accept-package-agreements --accept-source-agreements

## VS Code extensions
Get-Content ".\reports\vscode-extensions.txt" | ForEach-Object { ($_ -split "@")[0] } | Where-Object { $_ } | ForEach-Object { code --install-extension $_ }

## Registry appearance/system settings
# Review .reg files in .\registry before importing. Import only keys you recognize.
# For Windhawk Taskbar Auto-Hide Instant Show, import ".\registry\taskbar-autohide.reg" or enable Windows taskbar auto-hide manually.
# For secondary monitor taskbar auto-hide support, import ".\registry\taskbar-multimonitor.reg" and run ".\scripts\enable-windhawk-taskbar-per-monitor.ps1" after Windhawk is installed.
# For Windhawk mods and per-extension settings, import ".\registry\windhawk.reg" after Windhawk is installed.

## Cursor packs
powershell -ExecutionPolicy Bypass -File ".\scripts\download-cursor-packs.ps1"
powershell -ExecutionPolicy Bypass -File ".\scripts\switch-cursor-pack.ps1" -List
reg import ".\registry\cursor-pack-schemes.reg"

## Environment variables
# Compare .\reports\path-user.txt and .\reports\path-machine.txt with the new system before restoring.
