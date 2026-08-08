param(
    [switch]$PrintStatus
)

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path $env:APPDATA 'com.pais.handy\settings_store.json'
$voxtralModel = 'handy-computer/Voxtral-Mini-4B-Realtime-2602-gguf/Voxtral-Mini-4B-Realtime-2602-Q5_K_M.gguf'
$graniteModel = 'handy-computer/granite-speech-4.1-2b-gguf/granite-speech-4.1-2b-Q5_K_M.gguf'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('Egormity.HandyIndicators.NativeMethods' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Egormity.HandyIndicators
{
    public static class NativeMethods
    {
        [DllImport("user32.dll")]
        public static extern short GetKeyState(int virtualKey);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool DestroyIcon(IntPtr icon);
    }
}
'@
}

function Test-CapsLock {
    return (([Egormity.HandyIndicators.NativeMethods]::GetKeyState(0x14) -band 1) -ne 0)
}

function Get-HandyIndicatorState {
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        return [pscustomobject]@{
            Key = 'missing'
            Label = '?'
            Tooltip = 'Handy: settings unavailable'
            Color = [Drawing.Color]::FromArgb(120, 120, 120)
        }
    }

    try {
        $settings = (Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json).settings
        $model = [string]$settings.selected_model
        $language = [string]$settings.selected_language

        if ($model -eq $voxtralModel -and $language -eq 'auto') {
            return [pscustomobject]@{
                Key = 'voxtral-auto'
                Label = '4B'
                Tooltip = 'Handy: AUTO - Voxtral Mini 4B'
                Color = [Drawing.Color]::FromArgb(41, 151, 255)
            }
        }
        if ($model -eq $graniteModel -and $language -eq 'ja') {
            return [pscustomobject]@{
                Key = 'granite-ja'
                Label = '2B'
                Tooltip = 'Handy: JA - Granite Speech 2B'
                Color = [Drawing.Color]::FromArgb(224, 105, 165)
            }
        }

        return [pscustomobject]@{
            Key = "custom:$model`:$language"
            Label = '?'
            Tooltip = 'Handy: custom profile'
            Color = [Drawing.Color]::FromArgb(120, 120, 120)
        }
    }
    catch {
        return [pscustomobject]@{
            Key = 'error'
            Label = '!'
            Tooltip = 'Handy: unable to read settings'
            Color = [Drawing.Color]::FromArgb(190, 65, 65)
        }
    }
}

function New-TextIcon {
    param(
        [Parameter(Mandatory)] [string]$Label,
        [Parameter(Mandatory)] [Drawing.Color]$Background
    )

    $size = 64
    $bitmap = New-Object Drawing.Bitmap($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $backgroundBrush = New-Object Drawing.SolidBrush($Background)
    $foregroundBrush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
    $fontSize = if ($Label.Length -gt 1) { 30 } else { 40 }
    $font = New-Object Drawing.Font('Segoe UI', $fontSize, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
    $format = New-Object Drawing.StringFormat
    $format.Alignment = [Drawing.StringAlignment]::Center
    $format.LineAlignment = [Drawing.StringAlignment]::Center

    try {
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.FillEllipse($backgroundBrush, 2, 2, 60, 60)
        $graphics.DrawString($Label, $font, $foregroundBrush, (New-Object Drawing.RectangleF(0, 0, 64, 62)), $format)

        $handle = $bitmap.GetHicon()
        try {
            $borrowedIcon = [Drawing.Icon]::FromHandle($handle)
            return [Drawing.Icon]$borrowedIcon.Clone()
        }
        finally {
            $null = [Egormity.HandyIndicators.NativeMethods]::DestroyIcon($handle)
        }
    }
    finally {
        $format.Dispose()
        $font.Dispose()
        $foregroundBrush.Dispose()
        $backgroundBrush.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Set-IndicatorsPromoted {
    $notifySettingsPath = 'HKCU:\Control Panel\NotifyIconSettings'
    if (-not (Test-Path -LiteralPath $notifySettingsPath)) {
        return $false
    }

    $matched = 0
    foreach ($entry in Get-ChildItem -LiteralPath $notifySettingsPath) {
        $properties = Get-ItemProperty -LiteralPath $entry.PSPath
        if ($properties.InitialTooltip -match '^(Caps Lock:|Handy:)') {
            Set-ItemProperty -LiteralPath $entry.PSPath -Name IsPromoted -Type DWord -Value 1
            $matched++
        }
    }
    return ($matched -ge 2)
}

if ($PrintStatus) {
    $capsEnabled = Test-CapsLock
    $handyState = Get-HandyIndicatorState
    [pscustomobject]@{
        CapsLock = if ($capsEnabled) { 'ON' } else { 'OFF' }
        HandyProfile = $handyState.Tooltip -replace '^Handy: ', ''
    }
    exit 0
}

$createdNew = $false
$mutex = New-Object Threading.Mutex($true, 'Local\Egormity.HandyTaskbarIndicators', [ref]$createdNew)
if (-not $createdNew) {
    $mutex.Dispose()
    exit 0
}

$capsIndicator = New-Object Windows.Forms.NotifyIcon
$handyIndicator = New-Object Windows.Forms.NotifyIcon
$capsIcon = $null
$handyIcon = $null
$lastCapsState = $null
$lastHandyKey = $null

$contextMenu = New-Object Windows.Forms.ContextMenuStrip
$exitItem = $contextMenu.Items.Add('Exit indicators')
$capsIndicator.ContextMenuStrip = $contextMenu
$handyIndicator.ContextMenuStrip = $contextMenu

$capsTimer = New-Object Windows.Forms.Timer
$capsTimer.Interval = 150
$handyTimer = New-Object Windows.Forms.Timer
$handyTimer.Interval = 500
$promotionTimer = New-Object Windows.Forms.Timer
$promotionTimer.Interval = 1500

$updateCaps = {
    $enabled = Test-CapsLock
    if ($null -eq $script:lastCapsState -or $enabled -ne $script:lastCapsState) {
        $newIcon = if ($enabled) {
            New-TextIcon -Label 'A' -Background ([Drawing.Color]::FromArgb(58, 166, 92))
        }
        else {
            New-TextIcon -Label 'A' -Background ([Drawing.Color]::FromArgb(100, 100, 100))
        }

        $script:capsIndicator.Icon = $newIcon
        $script:capsIndicator.Text = if ($enabled) { 'Caps Lock: ON' } else { 'Caps Lock: OFF' }
        if ($script:capsIcon) {
            $script:capsIcon.Dispose()
        }
        $script:capsIcon = $newIcon
        $script:lastCapsState = $enabled
    }
}

$updateHandy = {
    $state = Get-HandyIndicatorState
    if ($state.Key -ne $script:lastHandyKey) {
        $newIcon = New-TextIcon -Label $state.Label -Background $state.Color
        $script:handyIndicator.Icon = $newIcon
        $script:handyIndicator.Text = $state.Tooltip
        if ($script:handyIcon) {
            $script:handyIcon.Dispose()
        }
        $script:handyIcon = $newIcon
        $script:lastHandyKey = $state.Key
    }
}

$capsTimer.Add_Tick($updateCaps)
$handyTimer.Add_Tick($updateHandy)
$promotionTimer.Add_Tick({
    if (Set-IndicatorsPromoted) {
        $script:promotionTimer.Stop()
    }
})
$exitItem.Add_Click({ [Windows.Forms.Application]::ExitThread() })

try {
    [Windows.Forms.Application]::EnableVisualStyles()
    & $updateCaps
    & $updateHandy
    $capsIndicator.Visible = $true
    $handyIndicator.Visible = $true
    $capsTimer.Start()
    $handyTimer.Start()
    $promotionTimer.Start()
    [Windows.Forms.Application]::Run()
}
finally {
    $capsTimer.Stop()
    $handyTimer.Stop()
    $promotionTimer.Stop()
    $capsIndicator.Visible = $false
    $handyIndicator.Visible = $false
    $capsIndicator.Dispose()
    $handyIndicator.Dispose()
    if ($capsIcon) { $capsIcon.Dispose() }
    if ($handyIcon) { $handyIcon.Dispose() }
    $contextMenu.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
