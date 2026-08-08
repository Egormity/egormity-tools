$ErrorActionPreference = 'Stop'

$sourceScript = Join-Path $PSScriptRoot 'handy-model-switch.ps1'
$sourceIndicators = Join-Path $PSScriptRoot 'handy-taskbar-indicators.ps1'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Egormity\HandyModelSwitch'
$installedScript = Join-Path $installDirectory 'handy-model-switch.ps1'
$installedIndicators = Join-Path $installDirectory 'handy-taskbar-indicators.ps1'
$startupDirectory = [Environment]::GetFolderPath('Startup')
$switchShortcutPath = Join-Path $startupDirectory 'Handy Model Switch.lnk'
$indicatorsShortcutPath = Join-Path $startupDirectory 'Handy Taskbar Indicators.lnk'
$powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

foreach ($source in $sourceScript, $sourceIndicators) {
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Source script was not found at $source"
    }
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null

$escapedInstallDirectory = [Regex]::Escape($installDirectory)
Get-CimInstance Win32_Process |
    Where-Object {
        $_.Name -eq 'powershell.exe' -and
        $_.CommandLine -match $escapedInstallDirectory -and
        $_.CommandLine -match 'handy-(model-switch|taskbar-indicators)\.ps1'
    } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Copy-Item -LiteralPath $sourceScript -Destination $installedScript -Force
Copy-Item -LiteralPath $sourceIndicators -Destination $installedIndicators -Force

$shell = New-Object -ComObject WScript.Shell

function Install-StartupShortcut {
    param(
        [string]$Path,
        [string]$ScriptPath,
        [string]$Description
    )

    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $powershellPath
    $shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $shortcut.WorkingDirectory = $installDirectory
    $shortcut.Description = $Description
    $shortcut.Save()
}

Install-StartupShortcut -Path $switchShortcutPath -ScriptPath $installedScript `
    -Description 'Toggle Handy transcription model with Win+Shift+F'
Install-StartupShortcut -Path $indicatorsShortcutPath -ScriptPath $installedIndicators `
    -Description 'Show Caps Lock and Handy profile taskbar indicators'

Start-Process -FilePath $powershellPath -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$installedScript`""
) -WindowStyle Hidden

Start-Process -FilePath $powershellPath -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$installedIndicators`""
) -WindowStyle Hidden

Write-Host "Installed Handy model switch to $installDirectory"
Write-Host 'Registered Win+Shift+F and started both taskbar indicators.'
