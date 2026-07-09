$ErrorActionPreference = "Stop"

$fontName = "Segoe Print"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$terminalSettingsSource = Join-Path $repoRoot "configs\windows-terminal\settings.json"
$terminalSettingsTarget = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$fontRegistry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
if (-not $fontRegistry."Segoe Print (TrueType)") {
    throw "Segoe Print is not installed on this Windows system."
}

if (Test-Path $terminalSettingsTarget) {
    $settings = Get-Content -LiteralPath $terminalSettingsTarget -Raw | ConvertFrom-Json
} elseif (Test-Path $terminalSettingsSource) {
    $settings = Get-Content -LiteralPath $terminalSettingsSource -Raw | ConvertFrom-Json
} else {
    $settings = [pscustomobject]@{
        '$schema' = "https://aka.ms/terminal-profiles-schema"
        profiles = [pscustomobject]@{
            defaults = [pscustomobject]@{}
            list = @()
        }
    }
}

if (-not $settings.profiles) {
    $settings | Add-Member -MemberType NoteProperty -Name "profiles" -Value ([pscustomobject]@{})
}
if (-not $settings.profiles.defaults) {
    $settings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value ([pscustomobject]@{})
}
if (-not $settings.profiles.defaults.font) {
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value ([pscustomobject]@{})
}

$settings.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name "face" -Value $fontName -Force

New-Item -ItemType Directory -Force -Path (Split-Path $terminalSettingsTarget) | Out-Null
$settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $terminalSettingsTarget -Encoding UTF8

$consoleKeys = @(
    "HKCU:\Console",
    "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe",
    "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe",
    "HKCU:\Console\%SystemRoot%_System32_cmd.exe"
)

foreach ($key in $consoleKeys) {
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name "FaceName" -Value $fontName -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $key -Name "FontFamily" -Value 54 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $key -Name "FontSize" -Value 0x00140000 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $key -Name "FontWeight" -Value 400 -PropertyType DWord -Force | Out-Null
}

Write-Host "Applied Segoe Print to Windows Terminal and classic console defaults."
Write-Host "Open a new terminal tab/window for the font to refresh."
