$ErrorActionPreference = 'Stop'

$sourceScript = Join-Path $PSScriptRoot 'handy-model-switch.ps1'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Egormity\HandyModelSwitch'
$installedScript = Join-Path $installDirectory 'handy-model-switch.ps1'
$startupDirectory = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupDirectory 'Handy Model Switch.lnk'
$powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

if (-not (Test-Path -LiteralPath $sourceScript)) {
    throw "Source script was not found at $sourceScript"
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceScript -Destination $installedScript -Force

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershellPath
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedScript`""
$shortcut.WorkingDirectory = $installDirectory
$shortcut.Description = 'Toggle Handy transcription model with Win+Shift+F'
$shortcut.Save()

Start-Process -FilePath $powershellPath -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$installedScript`""
) -WindowStyle Hidden

Write-Host "Installed Handy model switch to $installDirectory"
Write-Host 'Registered Win+Shift+F for the current session and future logins.'
