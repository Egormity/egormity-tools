param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
)

$ErrorActionPreference = "Stop"

$binRoot = $PSScriptRoot
$packageRoot = Split-Path -Parent $binRoot
$repoRoot = Split-Path -Parent $packageRoot
$configScriptsRoot = Join-Path $repoRoot "windows_config\scripts"
$cursorRoot = Join-Path $repoRoot "windows_config\cursor_packs"
$manifestPath = Join-Path $cursorRoot "manifest.json"
$switcher = Join-Path $configScriptsRoot "switch-cursor-pack.ps1"
$menu = Join-Path $configScriptsRoot "cursor-pack-menu.ps1"
$downloader = Join-Path $configScriptsRoot "download-cursor-packs.ps1"

function Show-Help {
    Write-Host "egormity_cursors"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  egormity_cursors                         Open the cursor menu"
    Write-Host "  egormity_cursors menu                    Open the cursor menu"
    Write-Host "  egormity_cursors list                    List configured cursor packs"
    Write-Host "  egormity_cursors apply <pack-id>         Apply a cursor pack now"
    Write-Host "  egormity_cursors register <pack-id>      Save a Windows cursor scheme"
    Write-Host "  egormity_cursors install <pack-id>       Run .inf installers if present"
    Write-Host "  egormity_cursors extract <pack-id>       Extract a downloaded archive"
    Write-Host "  egormity_cursors source <pack-id>        Print the source URL"
    Write-Host "  egormity_cursors download                Try downloading packs from manifest"
    Write-Host "  egormity_cursors <pack-id>               Shortcut for apply <pack-id>"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  egormity_cursors apply monolith"
    Write-Host "  egormity_cursors crystal-clear-v41"
}

function Get-Manifest {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Cursor manifest not found: $manifestPath"
    }

    return Get-Content $manifestPath -Raw | ConvertFrom-Json
}

function Get-Pack {
    param([string] $PackId)

    $manifest = Get-Manifest
    $pack = $manifest.packs | Where-Object { $_.id -eq $PackId } | Select-Object -First 1
    if (-not $pack) {
        throw "Unknown cursor pack id: $PackId. Run `egormity_cursors list` to see available pack ids."
    }

    return $pack
}

function Invoke-Switcher {
    param([string[]] $SwitcherArguments)

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $switcher @SwitcherArguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$command = "menu"
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
    "menu" {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $menu
        return
    }
    "list" {
        Invoke-Switcher -SwitcherArguments @("-List")
        return
    }
    "download" {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $downloader
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        return
    }
    "apply" {
        if (-not $rest) { throw "Usage: egormity_cursors apply <pack-id>" }
        Invoke-Switcher -SwitcherArguments @("-PackId", $rest[0], "-Apply")
        return
    }
    "register" {
        if (-not $rest) { throw "Usage: egormity_cursors register <pack-id>" }
        Invoke-Switcher -SwitcherArguments @("-PackId", $rest[0], "-Register")
        return
    }
    "install" {
        if (-not $rest) { throw "Usage: egormity_cursors install <pack-id>" }
        Invoke-Switcher -SwitcherArguments @("-PackId", $rest[0], "-Install")
        return
    }
    "extract" {
        if (-not $rest) { throw "Usage: egormity_cursors extract <pack-id>" }
        Invoke-Switcher -SwitcherArguments @("-PackId", $rest[0], "-Extract")
        return
    }
    "source" {
        if (-not $rest) { throw "Usage: egormity_cursors source <pack-id>" }
        $pack = Get-Pack -PackId $rest[0]
        Write-Host $pack.sourceUrl
        return
    }
    default {
        Get-Pack -PackId $command | Out-Null
        Invoke-Switcher -SwitcherArguments @("-PackId", $command, "-Apply")
        return
    }
}
