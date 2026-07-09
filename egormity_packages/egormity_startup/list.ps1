function Get-RegistryRunItems {
    $items = @()

    foreach ($scope in $script:RunKeyMap.Keys) {
        $path = $script:RunKeyMap[$scope]
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $approvedPath = $script:ApprovedRunKeyMap[$scope]
        $properties = Get-ItemProperty -LiteralPath $path
        foreach ($property in $properties.PSObject.Properties) {
            if ($property.Name -like "PS*") {
                continue
            }

            $items += New-StartupItem `
                -Id "Run:${scope}:$($property.Name)" `
                -Name $property.Name `
                -Source "Run" `
                -Location $scope `
                -Command ([string] $property.Value) `
                -Enabled (Get-StartupApprovedState -Path $approvedPath -Name $property.Name) `
                -Controllable $true
        }
    }

    foreach ($scope in $script:RunOnceKeyMap.Keys) {
        $path = $script:RunOnceKeyMap[$scope]
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $properties = Get-ItemProperty -LiteralPath $path
        foreach ($property in $properties.PSObject.Properties) {
            if ($property.Name -like "PS*") {
                continue
            }

            $items += New-StartupItem `
                -Id "RunOnce:${scope}:$($property.Name)" `
                -Name $property.Name `
                -Source "RunOnce" `
                -Location $scope `
                -Command ([string] $property.Value) `
                -Enabled $true `
                -Controllable $false
        }
    }

    return $items
}

function Get-StartupFolderItems {
    $folders = @(
        @{
            Scope = "CurrentUser"
            Path = [Environment]::GetFolderPath("Startup")
            Approved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        },
        @{
            Scope = "AllUsers"
            Path = [Environment]::GetFolderPath("CommonStartup")
            Approved = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        }
    )

    $items = @()
    foreach ($folder in $folders) {
        if (-not $folder.Path -or -not (Test-Path -LiteralPath $folder.Path)) {
            continue
        }

        Get-ChildItem -LiteralPath $folder.Path -File -Force | ForEach-Object {
            $items += New-StartupItem `
                -Id "StartupFolder:$($folder.Scope):$($_.Name)" `
                -Name $_.Name `
                -Source "StartupFolder" `
                -Location $folder.Scope `
                -Command $_.FullName `
                -Enabled (Get-StartupApprovedState -Path $folder.Approved -Name $_.Name) `
                -Controllable $true
        }
    }

    return $items
}

function Test-TaskHasStartupTrigger {
    param($Task)

    foreach ($trigger in @($Task.Triggers)) {
        $className = $trigger.CimClass.CimClassName
        if ($className -in @("MSFT_TaskLogonTrigger", "MSFT_TaskBootTrigger")) {
            return $true
        }
    }

    return $false
}

function Get-ScheduledTaskItems {
    $items = @()

    try {
        Get-ScheduledTask | Where-Object { Test-TaskHasStartupTrigger -Task $_ } | ForEach-Object {
            $taskName = $_.TaskName
            $taskPath = $_.TaskPath
            $fullName = "$taskPath$taskName"

            $items += New-StartupItem `
                -Id "ScheduledTask:$fullName" `
                -Name $taskName `
                -Source "ScheduledTask" `
                -Location $taskPath `
                -Command $fullName `
                -Enabled ([bool] $_.Settings.Enabled) `
                -Controllable $true
        }
    } catch {
        Write-Warning "Could not enumerate scheduled tasks: $($_.Exception.Message)"
    }

    return $items
}

function Get-ServiceItems {
    $items = @()

    try {
        Get-CimInstance Win32_Service -Filter "StartMode = 'Auto' OR StartMode = 'Disabled'" | ForEach-Object {
            $items += New-StartupItem `
                -Id "Service:$($_.Name)" `
                -Name $_.Name `
                -Source "Service" `
                -Location $_.StartName `
                -Command $_.PathName `
                -Enabled ($_.StartMode -ne "Disabled") `
                -Controllable $true
        }
    } catch {
        Write-Warning "Could not enumerate services: $($_.Exception.Message)"
    }

    return $items
}

function Get-StartupItems {
    $items = @()
    $items += Get-RegistryRunItems
    $items += Get-StartupFolderItems
    $items += Get-ScheduledTaskItems
    $items += Get-ServiceItems
    return $items | Sort-Object Source, Location, Name
}

function Get-TerminalWidth {
    $width = $Host.UI.RawUI.WindowSize.Width
    if (-not $width -or $width -lt 80) {
        return 120
    }

    return $width
}

function Limit-Text {
    param(
        [string] $Value,
        [int] $Width
    )

    if ($null -eq $Value) {
        $Value = ""
    }

    if ($Width -le 0) {
        return ""
    }
    if ($Value.Length -le $Width) {
        return $Value
    }
    if ($Width -le 3) {
        return $Value.Substring(0, $Width)
    }

    return $Value.Substring(0, $Width - 3) + "..."
}

function Format-TableCell {
    param(
        [string] $Value,
        [int] $Width
    )

    return (Limit-Text -Value $Value -Width $Width).PadRight($Width)
}

function Show-TrimmedStartupItems {
    param([object[]] $Items)

    $terminalWidth = Get-TerminalWidth
    $separatorWidth = 10
    $enabledWidth = 7
    $sourceWidth = 13
    $remainingWidth = $terminalWidth - $separatorWidth - $enabledWidth - $sourceWidth

    $locationWidth = 8
    $nameWidth = 12
    $idWidth = 12
    $commandWidth = 10
    $extraWidth = [Math]::Max(0, $remainingWidth - $locationWidth - $nameWidth - $idWidth - $commandWidth)

    $locationExtra = [Math]::Min(14, $extraWidth)
    $locationWidth += $locationExtra
    $extraWidth -= $locationExtra

    $nameExtra = [Math]::Min(18, $extraWidth)
    $nameWidth += $nameExtra
    $extraWidth -= $nameExtra

    $idExtra = [Math]::Min(22, $extraWidth)
    $idWidth += $idExtra
    $extraWidth -= $idExtra

    $commandWidth += $extraWidth

    $columns = @(
        @{ Name = "Enabled"; Width = $enabledWidth },
        @{ Name = "Source"; Width = $sourceWidth },
        @{ Name = "Location"; Width = $locationWidth },
        @{ Name = "Name"; Width = $nameWidth },
        @{ Name = "Id"; Width = $idWidth },
        @{ Name = "Command"; Width = $commandWidth }
    )

    $header = ($columns | ForEach-Object { Format-TableCell -Value $_.Name -Width $_.Width }) -join "  "
    $underline = ($columns | ForEach-Object { "".PadRight($_.Width, "-") }) -join "  "
    Write-Host $header
    Write-Host $underline

    foreach ($item in $Items) {
        $enabled = if ($item.Enabled) { "yes" } else { "no" }
        $line = @(
            Format-TableCell -Value $enabled -Width $enabledWidth
            Format-TableCell -Value $item.Source -Width $sourceWidth
            Format-TableCell -Value $item.Location -Width $locationWidth
            Format-TableCell -Value $item.Name -Width $nameWidth
            Format-TableCell -Value $item.Id -Width $idWidth
            Format-TableCell -Value $item.Command -Width $commandWidth
        ) -join "  "
        Write-Host $line
    }
}

function Show-StartupItems {
    param(
        [string] $Filter,
        [bool] $Trim
    )

    $items = Get-StartupItems
    if ($Filter -eq "enabled") {
        $items = @($items | Where-Object { $_.Enabled })
    } elseif ($Filter -eq "disabled") {
        $items = @($items | Where-Object { -not $_.Enabled })
    }

    if ($Trim) {
        Show-TrimmedStartupItems -Items $items
        return
    }

    $items | Format-Table `
        @{ Label = "Enabled"; Expression = { if ($_.Enabled) { "yes" } else { "no" } } },
        Source,
        Location,
        Name,
        Id,
        Command `
        -AutoSize `
        -Wrap
}
