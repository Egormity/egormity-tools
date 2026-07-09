$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`""
    )

    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait
    exit $LASTEXITCODE
}

$modId = "taskbar-auto-hide-per-monitor"
$mods64Path = "C:\ProgramData\Windhawk\Engine\Mods\64"
$modDll = Get-ChildItem -LiteralPath $mods64Path -Filter "$modId`_*.dll" -File -ErrorAction Stop |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $modDll) {
    throw "Windhawk helper DLL was not found. Install the '$modId' mod in Windhawk first."
}

$version = "1.0.0"
if ($modDll.BaseName -match "^$([regex]::Escape($modId))_([0-9.]+)_") {
    $version = $Matches[1]
}

$modKey = "HKLM:\Software\Windhawk\Engine\Mods\$modId"
New-Item -Path $modKey -Force | Out-Null
New-Item -Path "$modKey\Settings" -Force | Out-Null
New-ItemProperty -Path $modKey -Name "LibraryFileName" -PropertyType String -Value $modDll.Name -Force | Out-Null
New-ItemProperty -Path $modKey -Name "Disabled" -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $modKey -Name "Include" -PropertyType String -Value "explorer.exe" -Force | Out-Null
New-ItemProperty -Path $modKey -Name "Exclude" -PropertyType String -Value "" -Force | Out-Null
New-ItemProperty -Path $modKey -Name "Architecture" -PropertyType String -Value "x86-64" -Force | Out-Null
New-ItemProperty -Path $modKey -Name "Version" -PropertyType String -Value $version -Force | Out-Null
New-ItemProperty -Path $modKey -Name "SettingsChangeTime" -PropertyType DWord -Value 0 -Force | Out-Null

$profilePath = "C:\ProgramData\Windhawk\userprofile.json"
if (Test-Path -LiteralPath $profilePath) {
    $profile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json

    if (-not $profile.mods) {
        $profile | Add-Member -MemberType NoteProperty -Name "mods" -Value ([pscustomobject]@{})
    }

    if (-not ($profile.mods.PSObject.Properties.Name -contains $modId)) {
        $profile.mods | Add-Member -MemberType NoteProperty -Name $modId -Value ([pscustomobject]@{
            version = $version
            latestVersion = $version
        })
    }

    $profile | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $profilePath -Encoding UTF8
}

$advancedKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-ItemProperty -Path $advancedKey -Name "MMTaskbarEnabled" -PropertyType DWord -Value 1 -Force | Out-Null
New-ItemProperty -Path $advancedKey -Name "MMTaskbarMode" -PropertyType DWord -Value 0 -Force | Out-Null

$windhawkExe = "C:\Program Files\Windhawk\windhawk.exe"
if (Test-Path -LiteralPath $windhawkExe) {
    Start-Process -FilePath $windhawkExe -ArgumentList "-exit", "-wait" -Wait -WindowStyle Hidden
    Start-Process -FilePath $windhawkExe -ArgumentList "-tray-only" -WindowStyle Hidden
}

Start-Sleep -Seconds 2
Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Start-Process explorer.exe

Write-Host "Enabled Windhawk taskbar auto-hide support for secondary monitors."
Write-Host "Registered DLL: $($modDll.Name)"
