param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
)

$ErrorActionPreference = "Stop"

$startupRoot = Join-Path (Split-Path -Parent $PSScriptRoot) "egormity_startup"
. (Join-Path $startupRoot "common.ps1")
. (Join-Path $startupRoot "list.ps1")
. (Join-Path $startupRoot "actions.ps1")
. (Join-Path $startupRoot "cli.ps1")

try {
    Invoke-EgormityStartupCli -Arguments $Arguments
} catch {
    [Console]::Error.WriteLine("error: $($_.Exception.Message)")
    exit 1
}
