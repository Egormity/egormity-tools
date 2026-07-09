$ErrorActionPreference = "Continue"

$configRoot = Split-Path -Parent $PSScriptRoot
$cursorRoot = Join-Path $configRoot "cursor_packs"
$manifestPath = Join-Path $cursorRoot "manifest.json"
$archivesDir = Join-Path $cursorRoot "archives"
$pagesDir = Join-Path $cursorRoot "pages"

New-Item -ItemType Directory -Path $archivesDir -Force | Out-Null
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

function Invoke-CurlDownload {
    param(
        [string] $Url,
        [string] $OutFile
    )

    & curl.exe -L --fail --retry 2 --connect-timeout 20 --max-time 120 `
        --ssl-no-revoke --http1.1 `
        -A $userAgent `
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" `
        -o $OutFile $Url

    return ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $OutFile) -and (Get-Item -LiteralPath $OutFile).Length -gt 0)
}

function Get-ArchiveExtensionFromHeaders {
    param([string] $Headers)

    if ($Headers -match "filename=.*?\.([A-Za-z0-9]+)") {
        return "." + $Matches[1].ToLowerInvariant()
    }
    if ($Headers -match "content-type:\s*application/zip") { return ".zip" }
    if ($Headers -match "content-type:\s*application/x-rar") { return ".rar" }
    if ($Headers -match "content-type:\s*application/x-7z") { return ".7z" }
    return ".zip"
}

foreach ($pack in $manifest.packs) {
    Write-Host "== $($pack.id) =="

    $pagePath = Join-Path $pagesDir "$($pack.id).html"
    if (-not (Invoke-CurlDownload -Url $pack.sourceUrl -OutFile $pagePath)) {
        Write-Warning "Could not download page: $($pack.sourceUrl)"
    }

    $downloadCandidates = @(
        "https://vsthemes.org/engine/download.php?id=$($pack.pageId)",
        "https://vsthemes.org/en/engine/download.php?id=$($pack.pageId)",
        "https://vsthemes.org/index.php?do=download&id=$($pack.pageId)"
    )

    if (Test-Path -LiteralPath $pagePath) {
        $page = Get-Content $pagePath -Raw
        $hrefs = [regex]::Matches($page, 'href=["'']([^"'']+)["'']') | ForEach-Object { $_.Groups[1].Value }
        foreach ($href in $hrefs) {
            if ($href -match "download|/engine/|\.zip|\.rar|\.7z") {
                if ($href -match "^https?://") {
                    $downloadCandidates += $href
                } elseif ($href.StartsWith("/")) {
                    $downloadCandidates += "https://vsthemes.org$href"
                }
            }
        }
    }

    $downloaded = $false
    foreach ($candidate in ($downloadCandidates | Select-Object -Unique)) {
        $head = & curl.exe -I -L --ssl-no-revoke --http1.1 --max-time 30 -A $userAgent $candidate 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            continue
        }

        $extension = Get-ArchiveExtensionFromHeaders -Headers $head
        $archivePath = Join-Path $archivesDir "$($pack.id)$extension"
        if (Invoke-CurlDownload -Url $candidate -OutFile $archivePath) {
            $size = (Get-Item -LiteralPath $archivePath).Length
            if ($size -gt 1024) {
                Write-Host "Downloaded $archivePath ($size bytes)"
                $downloaded = $true
                break
            }
        }
    }

    if (-not $downloaded) {
        Write-Warning "No archive downloaded for $($pack.id). The source site may be blocking or offline."
    }
}
