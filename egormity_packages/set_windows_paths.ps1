$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$binPath = Join-Path $repoRoot "bin"
$pythonPaths = @($repoRoot)
$commandPaths = @($binPath)
$obsoletePaths = @(
    (Join-Path (Split-Path -Parent $repoRoot) "packages"),
    (Join-Path (Split-Path -Parent $repoRoot) "packages\bin")
)

function Add-UniquePathValue {
    param(
        [string] $CurrentValue,
        [string[]] $ValuesToAdd
    )

    $parts = @()
    if ($CurrentValue) {
        $parts = @($CurrentValue -split ';' | Where-Object { $_ })
    }

    foreach ($value in $ValuesToAdd) {
        $resolved = [System.IO.Path]::GetFullPath($value)
        $exists = $parts | Where-Object { $_.TrimEnd('\') -ieq $resolved.TrimEnd('\') }
        if (-not $exists) {
            $parts += $resolved
        }
    }

    return ($parts -join ';')
}

function Remove-PathValue {
    param(
        [string] $CurrentValue,
        [string[]] $ValuesToRemove
    )

    if (-not $CurrentValue) {
        return ""
    }

    $resolvedRemoveValues = @($ValuesToRemove | ForEach-Object { [System.IO.Path]::GetFullPath($_).TrimEnd('\') })
    $parts = @($CurrentValue -split ';' | Where-Object { $_ })
    $kept = @($parts | Where-Object {
        $resolvedPart = [System.IO.Path]::GetFullPath($_).TrimEnd('\')
        -not ($resolvedRemoveValues | Where-Object { $_ -ieq $resolvedPart })
    })

    return ($kept -join ';')
}

$currentUserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$currentUserPath = Remove-PathValue -CurrentValue $currentUserPath -ValuesToRemove $obsoletePaths
$newUserPath = Add-UniquePathValue -CurrentValue $currentUserPath -ValuesToAdd $commandPaths
[Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")

$currentUserPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
$currentUserPythonPath = Remove-PathValue -CurrentValue $currentUserPythonPath -ValuesToRemove $obsoletePaths
$newUserPythonPath = Add-UniquePathValue -CurrentValue $currentUserPythonPath -ValuesToAdd $pythonPaths
[Environment]::SetEnvironmentVariable("PYTHONPATH", $newUserPythonPath, "User")

$env:PATH = Remove-PathValue -CurrentValue $env:PATH -ValuesToRemove $obsoletePaths
$env:PATH = Add-UniquePathValue -CurrentValue $env:PATH -ValuesToAdd $commandPaths
$env:PYTHONPATH = Remove-PathValue -CurrentValue $env:PYTHONPATH -ValuesToRemove $obsoletePaths
$env:PYTHONPATH = Add-UniquePathValue -CurrentValue $env:PYTHONPATH -ValuesToAdd $pythonPaths

Write-Host "egormity tools path configured:"
Write-Host "  PATH: $binPath"
Write-Host "  PYTHONPATH: $repoRoot"
Write-Host ""
Write-Host "Current terminal is ready. New terminals can run:"
Write-Host "  egormity_git_tools"
Write-Host "  egormity_cursors"
Write-Host "  python -m egormity_git_tools"
