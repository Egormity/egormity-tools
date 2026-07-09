function Parse-StartupId {
    param([string] $Id)

    $parts = $Id -split ":", 3
    if ($parts.Count -lt 2) {
        throw "Invalid startup id: $Id"
    }

    return @{
        Kind = $parts[0]
        Scope = $parts[1]
        Name = if ($parts.Count -gt 2) { $parts[2] } else { "" }
    }
}

function Set-RunEntryState {
    param(
        [string] $Scope,
        [string] $Name,
        [bool] $Enabled
    )

    if (-not $script:RunKeyMap.ContainsKey($Scope)) {
        throw "Unknown Run scope: $Scope"
    }
    if ($Scope -in @("HKLM", "HKLM32")) {
        Assert-Administrator -Target "Run:${Scope}:$Name"
    }

    $runPath = $script:RunKeyMap[$Scope]
    if (-not (Get-ItemProperty -LiteralPath $runPath -Name $Name -ErrorAction SilentlyContinue)) {
        throw "Run entry not found: ${Scope}:$Name"
    }

    Set-StartupApprovedState -Path $script:ApprovedRunKeyMap[$Scope] -Name $Name -Enabled $Enabled
}

function Set-StartupFolderState {
    param(
        [string] $Scope,
        [string] $Name,
        [bool] $Enabled
    )

    $approvedPath = switch ($Scope) {
        "CurrentUser" { "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" }
        "AllUsers" {
            Assert-Administrator -Target "StartupFolder:${Scope}:$Name"
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        }
        default { throw "Unknown StartupFolder scope: $Scope" }
    }

    Set-StartupApprovedState -Path $approvedPath -Name $Name -Enabled $Enabled
}

function Set-ScheduledTaskState {
    param(
        [string] $FullName,
        [bool] $Enabled
    )

    $lastSlash = $FullName.LastIndexOf("\")
    if ($lastSlash -lt 0) {
        throw "Invalid scheduled task id: ScheduledTask:$FullName"
    }

    $taskPath = $FullName.Substring(0, $lastSlash + 1)
    $taskName = $FullName.Substring($lastSlash + 1)

    if ($taskPath -like "\Microsoft\Windows\*") {
        Assert-Administrator -Target "ScheduledTask:$FullName"
    }

    if ($Enabled) {
        Enable-ScheduledTask -TaskPath $taskPath -TaskName $taskName | Out-Null
    } else {
        Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName | Out-Null
    }
}

function Set-ServiceState {
    param(
        [string] $Name,
        [bool] $Enabled
    )

    Assert-Administrator -Target "Service:$Name"
    $startupType = if ($Enabled) { "Automatic" } else { "Disabled" }
    Set-Service -Name $Name -StartupType $startupType
}

function Set-StartupItemState {
    param(
        [string] $Id,
        [bool] $Enabled
    )

    $parsed = Parse-StartupId -Id $Id
    switch ($parsed.Kind) {
        "Run" {
            Set-RunEntryState -Scope $parsed.Scope -Name $parsed.Name -Enabled $Enabled
        }
        "RunOnce" {
            throw "RunOnce entries are one-shot startup entries and are not supported by enable/disable."
        }
        "StartupFolder" {
            Set-StartupFolderState -Scope $parsed.Scope -Name $parsed.Name -Enabled $Enabled
        }
        "ScheduledTask" {
            Set-ScheduledTaskState -FullName $parsed.Scope -Enabled $Enabled
        }
        "Service" {
            Set-ServiceState -Name $parsed.Scope -Enabled $Enabled
        }
        default {
            throw "Unsupported startup item kind: $($parsed.Kind)"
        }
    }

    $state = if ($Enabled) { "enabled" } else { "disabled" }
    Write-Host "$state $Id"
}

function Resolve-StartupItem {
    param(
        [string] $NameOrId,
        [string] $Location
    )

    if ($NameOrId -match "^[^:]+:.+") {
        $matches = @(Get-StartupItems | Where-Object { $_.Id -eq $NameOrId })
    } else {
        $matches = @(Get-StartupItems | Where-Object { $_.Name -eq $NameOrId })
        if ($Location) {
            $matches = @($matches | Where-Object { $_.Location -eq $Location })
        }
    }

    if ($matches.Count -eq 0) {
        if ($Location) {
            throw "Startup item not found: name '$NameOrId' at location '$Location'."
        }
        throw "Startup item not found: $NameOrId."
    }

    if ($matches.Count -gt 1) {
        Write-Host "Multiple startup items match '$NameOrId'. Use Name plus Location, or use Id:"
        $matches | Format-Table Source, Location, Name, Id -AutoSize -Wrap
        throw "Ambiguous startup item: $NameOrId"
    }

    return $matches[0]
}

function Set-StartupItemStateByName {
    param(
        [string] $NameOrId,
        [string] $Location,
        [bool] $Enabled
    )

    $item = Resolve-StartupItem -NameOrId $NameOrId -Location $Location
    $before = if ($item.Enabled) { "enabled" } else { "disabled" }
    Set-StartupItemState -Id $item.Id -Enabled $Enabled

    $updated = Resolve-StartupItem -NameOrId $item.Id -Location $null
    $after = if ($updated.Enabled) { "enabled" } else { "disabled" }
    if ($updated.Enabled -ne $Enabled) {
        throw "Requested $($item.Id) to become $Enabled, but verified state is $after."
    }

    Write-Host "verified $($item.Id): $before -> $after"
}

function Add-StartupRunEntry {
    param(
        [string] $Name,
        [string] $Command,
        [string] $Location = "HKCU"
    )

    if (-not $Name) {
        throw "Usage: egormity_startup add <name> <command> [--location <HKCU|HKLM|HKCU32|HKLM32>]"
    }
    if (-not $Command) {
        throw "Usage: egormity_startup add <name> <command> [--location <HKCU|HKLM|HKCU32|HKLM32>]"
    }
    if (-not $script:RunKeyMap.ContainsKey($Location)) {
        throw "Unsupported add location: $Location. Use one of: $($script:RunKeyMap.Keys -join ', ')."
    }
    if ($Location -in @("HKLM", "HKLM32")) {
        Assert-Administrator -Target "Run:${Location}:$Name"
    }

    $path = $script:RunKeyMap[$Location]
    New-Item -Path $path -Force | Out-Null
    New-ItemProperty -Path $path -Name $Name -PropertyType String -Value $Command -Force | Out-Null
    Set-StartupApprovedState -Path $script:ApprovedRunKeyMap[$Location] -Name $Name -Enabled $true
    Write-Host "added Run:${Location}:$Name"
}
