function Show-Help {
    Write-Host "egormity_startup"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  egormity_startup list [--enabled|--disabled] [--trim]"
    Write-Host "  egormity_startup enable <name-or-id> [location]"
    Write-Host "  egormity_startup disable <name-or-id> [location]"
    Write-Host "  egormity_startup add <name> <command> [--location <HKCU|HKLM|HKCU32|HKLM32>]"
    Write-Host "  egormity_startup --version"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  egormity_startup list --enabled --trim"
    Write-Host "  egormity_startup disable Discord HKCU"
    Write-Host "  egormity_startup disable Run:HKCU:Discord"
    Write-Host "  egormity_startup add MyTool `"C:\Tools\tool.exe --minimized`" --location HKCU"
    Write-Host ""
    Write-Host "Note: HKLM, AllUsers startup folders, Windows system tasks, and services require an administrator terminal."
}

function Get-OptionValue {
    param(
        [string[]] $Values,
        [string] $Name,
        [string] $Default
    )

    $index = [array]::IndexOf($Values, $Name)
    if ($index -lt 0) {
        return $Default
    }
    if ($index -ge ($Values.Count - 1)) {
        throw "Missing value for $Name"
    }

    return $Values[$index + 1]
}

function Remove-OptionPair {
    param(
        [string[]] $Values,
        [string] $Name
    )

    $result = @()
    for ($i = 0; $i -lt $Values.Count; $i++) {
        if ($Values[$i] -eq $Name) {
            $i++
            continue
        }
        $result += $Values[$i]
    }

    return $result
}

function Invoke-EgormityStartupCli {
    param([string[]] $Arguments)

    $command = "list"
    $rest = @()

    if ($Arguments -and $Arguments.Count -gt 0) {
        $command = $Arguments[0].ToLowerInvariant()
        if ($Arguments.Count -gt 1) {
            $rest = @($Arguments[1..($Arguments.Count - 1)])
        }
    }

    switch ($command) {
        { $_ -in @("help", "--help", "-h", "/?") } {
            Show-Help
            return
        }
        { $_ -in @("version", "--version", "--v") } {
            Write-Host "egormity_startup $script:EgormityStartupVersion"
            return
        }
        "list" {
            $filter = "all"
            if ($rest -contains "--enabled") {
                $filter = "enabled"
            } elseif ($rest -contains "--disabled") {
                $filter = "disabled"
            }
            Show-StartupItems -Filter $filter -Trim ($rest -contains "--trim")
            return
        }
        "enable" {
            if (-not $rest) { throw "Usage: egormity_startup enable <name-or-id> [location]" }
            $location = if ($rest.Count -gt 1) { $rest[1] } else { $null }
            Set-StartupItemStateByName -NameOrId $rest[0] -Location $location -Enabled $true
            return
        }
        "disable" {
            if (-not $rest) { throw "Usage: egormity_startup disable <name-or-id> [location]" }
            $location = if ($rest.Count -gt 1) { $rest[1] } else { $null }
            Set-StartupItemStateByName -NameOrId $rest[0] -Location $location -Enabled $false
            return
        }
        "add" {
            if ($rest.Count -lt 2) {
                throw "Usage: egormity_startup add <name> <command> [--location <HKCU|HKLM|HKCU32|HKLM32>]"
            }
            $location = Get-OptionValue -Values $rest -Name "--location" -Default "HKCU"
            $commandParts = @(Remove-OptionPair -Values $rest -Name "--location")
            if ($commandParts.Count -lt 2) {
                throw "Usage: egormity_startup add <name> <command> [--location <HKCU|HKLM|HKCU32|HKLM32>]"
            }
            Add-StartupRunEntry `
                -Name $commandParts[0] `
                -Command ($commandParts[1..($commandParts.Count - 1)] -join " ") `
                -Location $location
            return
        }
        default {
            throw "Unknown command: $command. Run `egormity_startup --help` for usage."
        }
    }
}
