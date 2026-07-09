# Restore checklist

Run selected commands manually after reinstall. Review paths first.

## Winget packages
winget import --import-file ".\reports\winget-packages.json" --accept-package-agreements --accept-source-agreements

## VS Code extensions
Get-Content ".\reports\vscode-extensions.txt" | ForEach-Object { ($_ -split "@")[0] } | Where-Object { $_ } | ForEach-Object { code --install-extension $_ }

## Registry appearance/system settings
Review .reg files in .\registry before importing. Import only keys you recognize.

## Environment variables
Compare .\reports\path-user.txt and .\reports\path-machine.txt with the new system before restoring.
