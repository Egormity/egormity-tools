$ErrorActionPreference = "Stop"

$fontName = "Segoe Print"
$boldFontName = "Segoe Print Bold"
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$fontRegistry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
if (-not $fontRegistry."Segoe Print (TrueType)") {
    throw "Segoe Print is not installed on this Windows system."
}

function Set-LogFontFaceName {
    param(
        [byte[]] $Bytes,
        [string] $FaceName
    )

    if ($Bytes.Length -lt 92) {
        throw "Unexpected LOGFONT byte length: $($Bytes.Length)"
    }

    $newBytes = [byte[]]::new($Bytes.Length)
    [Array]::Copy($Bytes, $newBytes, $Bytes.Length)

    $faceBytes = [Text.Encoding]::Unicode.GetBytes($FaceName + [char]0)
    for ($i = 28; $i -lt [Math]::Min($newBytes.Length, 92); $i++) {
        $newBytes[$i] = 0
    }
    [Array]::Copy($faceBytes, 0, $newBytes, 28, [Math]::Min($faceBytes.Length, 64))

    return $newBytes
}

$windowMetricsKey = "HKCU:\Control Panel\Desktop\WindowMetrics"
$windowMetricFontValues = @(
    "CaptionFont",
    "IconFont",
    "MenuFont",
    "MessageFont",
    "SmCaptionFont",
    "StatusFont"
)

foreach ($valueName in $windowMetricFontValues) {
    $current = (Get-ItemProperty -LiteralPath $windowMetricsKey -Name $valueName).$valueName
    $updated = Set-LogFontFaceName -Bytes ([byte[]] $current) -FaceName $fontName
    Set-ItemProperty -LiteralPath $windowMetricsKey -Name $valueName -Value $updated -Type Binary
}

$substitutions = @{
    "Arial" = $fontName
    "Arial Bold" = $boldFontName
    "Helvetica" = $fontName
    "MS Shell Dlg" = $fontName
    "MS Shell Dlg 2" = $fontName
    "Microsoft Sans Serif" = $fontName
    "Segoe UI" = $fontName
    "Segoe UI Black" = $boldFontName
    "Segoe UI Bold" = $boldFontName
    "Segoe UI Historic" = $fontName
    "Segoe UI Light" = $fontName
    "Segoe UI Semibold" = $boldFontName
    "Segoe UI Semilight" = $fontName
    "Segoe UI Symbol" = $fontName
    "Segoe UI Variable" = $fontName
    "Segoe UI Variable Display" = $fontName
    "Segoe UI Variable Small" = $fontName
    "Segoe UI Variable Text" = $fontName
    "System" = $fontName
    "Tahoma" = $fontName
    "Tahoma Armenian" = $fontName
}

$substituteKeys = @(
    "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes"
)

if ($isAdmin) {
    $substituteKeys += "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes"
}

foreach ($substituteKey in $substituteKeys) {
    New-Item -Path $substituteKey -Force | Out-Null
    foreach ($name in $substitutions.Keys) {
        New-ItemProperty -Path $substituteKey -Name $name -Value $substitutions[$name] -PropertyType String -Force | Out-Null
    }
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeMethods {
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@

$result = [UIntPtr]::Zero
[NativeMethods]::SendMessageTimeout([IntPtr] 0xffff, 0x001A, [UIntPtr]::Zero, "WindowMetrics", 0x0002, 5000, [ref] $result) | Out-Null

if (-not $isAdmin) {
    Write-Warning "Current-user font aliases were applied. Run this script as Administrator to also update machine-wide font aliases used by more apps."
}

Write-Host "Applied Segoe Print to Windows UI font slots and broad font substitutions."
Write-Host "Sign out or restart Windows for all shell surfaces and apps to refresh."
