$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetRoot = Resolve-Path (Join-Path $scriptRoot "..\jarvis_sounds\wav")
$schemeRoot = "HKCU:\AppEvents\Schemes\Apps"
$updated = 0
$missing = New-Object System.Collections.Generic.List[string]

Get-ChildItem -Path $schemeRoot -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $current = (Get-ItemProperty -LiteralPath $_.PSPath -Name "(default)" -ErrorAction SilentlyContinue)."(default)"
    if (-not $current) {
        return
    }

    $fileName = [System.IO.Path]::GetFileName($current)
    if ($fileName -notmatch "^jarvis_.*\.wav$") {
        return
    }

    $newPath = Join-Path $assetRoot $fileName
    if (Test-Path -LiteralPath $newPath) {
        & reg.exe add ($_.Name -replace "^HKEY_CURRENT_USER", "HKCU") /ve /d $newPath /f | Out-Null
        $updated++
    } else {
        $missing.Add($fileName) | Out-Null
    }
}

Write-Host "Updated Jarvis sound events: $updated"

if ($missing.Count -gt 0) {
    Write-Host "Missing sound files:"
    $missing | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
}
