$script:RunKeyMap = @{
    "HKCU" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM" = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKCU32" = "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    "HKLM32" = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
}

$script:RunOnceKeyMap = @{
    "HKCU" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM" = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKCU32" = "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM32" = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
}

$script:ApprovedRunKeyMap = @{
    "HKCU" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    "HKLM" = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    "HKCU32" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
    "HKLM32" = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
}

function New-StartupApprovedValue {
    param([bool] $Enabled)

    $bytes = New-Object byte[] 12
    if ($Enabled) {
        $bytes[0] = 2
    } else {
        $bytes[0] = 3
    }
    return $bytes
}

function Get-StartupApprovedState {
    param(
        [string] $Path,
        [string] $Name
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $true
    }

    $value = (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if (-not $value -or $value.Count -eq 0) {
        return $true
    }

    return $value[0] -ne 3
}

function Set-StartupApprovedState {
    param(
        [string] $Path,
        [string] $Name,
        [bool] $Enabled
    )

    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty `
        -Path $Path `
        -Name $Name `
        -PropertyType Binary `
        -Value (New-StartupApprovedValue -Enabled $Enabled) `
        -Force | Out-Null
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
    param([string] $Target)

    if (-not (Test-IsAdministrator)) {
        throw "Administrator privileges are required to modify $Target. Re-run PowerShell or Windows Terminal as administrator."
    }
}

function New-StartupItem {
    param(
        [string] $Id,
        [string] $Name,
        [string] $Source,
        [string] $Location,
        [string] $Command,
        [bool] $Enabled,
        [bool] $Controllable
    )

    [pscustomobject]@{
        Id = $Id
        Enabled = $Enabled
        Source = $Source
        Name = $Name
        Location = $Location
        Command = $Command
        Controllable = $Controllable
    }
}
