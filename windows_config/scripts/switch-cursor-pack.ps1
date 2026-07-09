param(
    [string] $PackId,
    [switch] $List,
    [switch] $Extract,
    [switch] $Install,
    [switch] $Register,
    [switch] $Apply
)

$ErrorActionPreference = "Stop"

$configRoot = Split-Path -Parent $PSScriptRoot
$cursorRoot = Join-Path $configRoot "cursor_packs"
$manifestPath = Join-Path $cursorRoot "manifest.json"
$archivesDir = Join-Path $cursorRoot "archives"
$packsDir = Join-Path $cursorRoot "packs"

New-Item -ItemType Directory -Path $archivesDir -Force | Out-Null
New-Item -ItemType Directory -Path $packsDir -Force | Out-Null

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

function Get-Pack {
    param([string] $Id)
    $pack = $manifest.packs | Where-Object { $_.id -eq $Id } | Select-Object -First 1
    if (-not $pack) {
        throw "Unknown cursor pack id: $Id. Run with -List to see available pack ids."
    }
    return $pack
}

function Expand-PackArchive {
    param([string] $Id)

    $archive = Get-ChildItem -LiteralPath $archivesDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -like "*$Id*" -and $_.Extension -in ".zip", ".rar", ".7z" } |
        Sort-Object Length -Descending |
        Select-Object -First 1

    if (-not $archive) {
        throw "No archive found for $Id in $archivesDir."
    }

    $destination = Join-Path $packsDir $Id
    New-Item -ItemType Directory -Path $destination -Force | Out-Null

    if ($archive.Extension -eq ".zip") {
        Expand-Archive -LiteralPath $archive.FullName -DestinationPath $destination -Force
    } else {
        $winRar = @(
            "$env:ProgramFiles\WinRAR\WinRAR.exe",
            "${env:ProgramFiles(x86)}\WinRAR\WinRAR.exe"
        ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

        if ($winRar) {
            & $winRar x -ibck -o+ $archive.FullName "$destination\"
        } else {
            & tar.exe -xf $archive.FullName -C $destination
        }
    }

    Write-Host "Extracted $($archive.Name) to $destination"
}

function Install-PackInf {
    param([string] $Id)

    $packDir = Join-Path $packsDir $Id
    if (-not (Test-Path -LiteralPath $packDir)) {
        Expand-PackArchive -Id $Id
    }

    $infFiles = Get-ChildItem -LiteralPath $packDir -Recurse -File -Filter "*.inf"
    if (-not $infFiles) {
        Write-Warning "No .inf installer found for $Id."
        return
    }

    foreach ($inf in $infFiles) {
        Write-Host "Installing $($inf.FullName)"
        Start-Process rundll32.exe -ArgumentList "setupapi,InstallHinfSection DefaultInstall 132 `"$($inf.FullName)`"" -Wait
    }
}

function Find-CursorFile {
    param(
        [System.IO.FileInfo[]] $Files,
        [string[]] $Patterns
    )

    foreach ($pattern in $Patterns) {
        $match = $Files | Where-Object { $_.BaseName -match $pattern } | Select-Object -First 1
        if ($match) { return $match.FullName }
    }
    return $null
}

function Apply-PackDirectly {
    param(
        [string] $Id,
        [string] $DisplayName,
        [switch] $MakeCurrent
    )

    $packDir = Join-Path $packsDir $Id
    if (-not (Test-Path -LiteralPath $packDir)) {
        Expand-PackArchive -Id $Id
    }

    $files = @(Get-ChildItem -LiteralPath $packDir -Recurse -File | Where-Object { $_.Extension -in ".cur", ".ani" } | Sort-Object Name)
    if (-not $files) {
        throw "No .cur or .ani files found in $packDir."
    }

    $map = [ordered]@{
        Arrow = @("^normal( select)?$|^arrow$|^pointer$|^regular$")
        Help = @("^help|question")
        AppStarting = @("working|background|appstarting|^work$")
        Wait = @("^busy$|^wait$|loading")
        Crosshair = @("precision|cross")
        IBeam = @("ibeam|text")
        NWPen = @("handwriting|handwrite|pen")
        No = @("unavailable|unvalible|^no$|forbidden|denied")
        SizeNS = @("ns|vert|vertical|size.*n.*s")
        SizeWE = @("we|horz|horizontal|size.*w.*e")
        SizeNWSE = @("nwse|diagonal.*1|size.*nw.*se")
        SizeNESW = @("nesw|diagonal.*2|size.*ne.*sw")
        SizeAll = @("move|all|sizeall")
        UpArrow = @("alternate|alternative|up")
        Hand = @("^link|^hand$")
        Pin = @("pin")
        Person = @("person")
    }

    $cursorKey = "HKCU:\Control Panel\Cursors"
    $schemeValues = New-Object System.Collections.Generic.List[string]

    foreach ($role in $map.Keys) {
        $path = Find-CursorFile -Files $files -Patterns $map[$role]
        if (-not $path -and $role -eq "Arrow") {
            $path = $files[0].FullName
        }
        if ($path) {
            Set-ItemProperty -Path $cursorKey -Name $role -Value $path
            $schemeValues.Add($path) | Out-Null
        } else {
            $schemeValues.Add("") | Out-Null
        }
    }

    New-Item -Path "$cursorKey\Schemes" -Force | Out-Null
    Set-ItemProperty -Path "$cursorKey\Schemes" -Name $DisplayName -Value ($schemeValues -join ",")

    if ($MakeCurrent) {
        & reg.exe add "HKCU\Control Panel\Cursors" /ve /d $DisplayName /f | Out-Null
        Set-ItemProperty -Path $cursorKey -Name "Scheme Source" -Type DWord -Value 1

        Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class CursorNativeMethods {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@
        [CursorNativeMethods]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x01 -bor 0x02) | Out-Null

        Write-Host "Applied cursor pack: $DisplayName"
    } else {
        Write-Host "Registered cursor scheme: $DisplayName"
    }
}

if ($List -or -not $PackId) {
    $manifest.packs | ForEach-Object {
        $packIdForArchiveLookup = $_.id
        $packDir = Join-Path $packsDir $_.id
        $archive = Get-ChildItem -LiteralPath $archivesDir -File -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -like "*$packIdForArchiveLookup*" } | Select-Object -First 1
        [pscustomobject]@{
            Id = $_.id
            Name = $_.name
            Extracted = Test-Path -LiteralPath $packDir
            Archive = if ($archive) { $archive.Name } else { "" }
            SourceUrl = $_.sourceUrl
        }
    } | Format-Table -AutoSize
    if (-not $PackId) { return }
}

$selectedPack = Get-Pack -Id $PackId

if ($Extract) {
    Expand-PackArchive -Id $selectedPack.id
}

if ($Install) {
    Install-PackInf -Id $selectedPack.id
}

if ($Register) {
    Apply-PackDirectly -Id $selectedPack.id -DisplayName $selectedPack.name
}

if ($Apply) {
    Apply-PackDirectly -Id $selectedPack.id -DisplayName $selectedPack.name -MakeCurrent
}
