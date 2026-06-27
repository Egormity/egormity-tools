$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$binPath = Join-Path $repoRoot "bin"
$pythonPaths = @($repoRoot)
$commandPaths = @($binPath)

function Add-UniquePathValue {
    param(
        [string] $CurrentValue,
        [string[]] $ValuesToAdd
    )

    $parts = @()
    if ($CurrentValue) {
        $parts = $CurrentValue -split ';' | Where-Object { $_ }
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

$currentUserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$newUserPath = Add-UniquePathValue -CurrentValue $currentUserPath -ValuesToAdd $commandPaths
[Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")

$currentUserPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
$newUserPythonPath = Add-UniquePathValue -CurrentValue $currentUserPythonPath -ValuesToAdd $pythonPaths
[Environment]::SetEnvironmentVariable("PYTHONPATH", $newUserPythonPath, "User")

$env:PATH = Add-UniquePathValue -CurrentValue $env:PATH -ValuesToAdd $commandPaths
$env:PYTHONPATH = Add-UniquePathValue -CurrentValue $env:PYTHONPATH -ValuesToAdd $pythonPaths

Write-Host "egormity_git_tools path configured:"
Write-Host "  PATH: $binPath"
Write-Host "  PYTHONPATH: $repoRoot"
Write-Host ""
Write-Host "Current terminal is ready. New terminals can run:"
Write-Host "  egormity_git_tools"
Write-Host "  python -m egormity_git_tools"
