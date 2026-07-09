$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
$switcher = Join-Path $scriptRoot "switch-cursor-pack.ps1"
$configRoot = Split-Path -Parent $scriptRoot
$manifestPath = Join-Path $configRoot "cursor_packs\manifest.json"
$packsDir = Join-Path $configRoot "cursor_packs\packs"

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

function Show-PackList {
    Write-Host ""
    Write-Host "Cursor packs"
    Write-Host "------------"
    for ($i = 0; $i -lt $manifest.packs.Count; $i++) {
        $pack = $manifest.packs[$i]
        $packDir = Join-Path $packsDir $pack.id
        $status = if (Test-Path -LiteralPath $packDir) { "ready" } else { "not downloaded" }
        Write-Host ("{0,2}. {1} ({2})" -f ($i + 1), $pack.name, $status)
    }
    Write-Host ""
}

Show-PackList

$selection = Read-Host "Choose a cursor pack number, or press Enter to exit"
if (-not $selection) {
    return
}

$index = 0
if (-not [int]::TryParse($selection, [ref] $index) -or $index -lt 1 -or $index -gt $manifest.packs.Count) {
    throw "Invalid selection: $selection"
}

$pack = $manifest.packs[$index - 1]

Write-Host ""
Write-Host "Selected: $($pack.name)"
Write-Host "1. Apply now"
Write-Host "2. Register as Windows scheme"
Write-Host "3. Extract archive"
Write-Host "4. Install .inf files"
Write-Host "5. Show source URL"
Write-Host ""

$action = Read-Host "Choose action"
switch ($action) {
    "1" { & powershell -ExecutionPolicy Bypass -File $switcher -PackId $pack.id -Apply }
    "2" { & powershell -ExecutionPolicy Bypass -File $switcher -PackId $pack.id -Register }
    "3" { & powershell -ExecutionPolicy Bypass -File $switcher -PackId $pack.id -Extract }
    "4" { & powershell -ExecutionPolicy Bypass -File $switcher -PackId $pack.id -Install }
    "5" { Write-Host $pack.sourceUrl }
    default { throw "Invalid action: $action" }
}
