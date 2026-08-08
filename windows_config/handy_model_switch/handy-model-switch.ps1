param(
    [switch]$ToggleOnce,
    [switch]$PrintStatus
)

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path $env:APPDATA 'com.pais.handy\settings_store.json'
$defaultHandyPath = Join-Path $env:LOCALAPPDATA 'Handy\handy.exe'
$logDirectory = Join-Path $env:LOCALAPPDATA 'Egormity\HandyModelSwitch'
$logPath = Join-Path $logDirectory 'handy-model-switch.log'

$voxtralModel = 'handy-computer/Voxtral-Mini-4B-Realtime-2602-gguf/Voxtral-Mini-4B-Realtime-2602-Q5_K_M.gguf'
$graniteModel = 'handy-computer/granite-speech-4.1-2b-gguf/granite-speech-4.1-2b-Q5_K_M.gguf'

function Write-SwitchLog {
    param([string]$Message)

    if (-not (Test-Path -LiteralPath $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    $line = '{0:o} {1}' -f (Get-Date), $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Get-HandySettingsDocument {
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        throw "Handy settings were not found at $settingsPath"
    }

    $document = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
    if ($null -eq $document.settings) {
        throw 'Handy settings_store.json does not contain a settings object.'
    }
    return $document
}

function Get-ProfileDescription {
    param($Document)

    $model = [string]$Document.settings.selected_model
    $language = [string]$Document.settings.selected_language

    if ($model -eq $voxtralModel -and $language -eq 'auto') {
        return 'Voxtral Mini 4B Realtime / Auto'
    }
    if ($model -eq $graniteModel -and $language -eq 'ja') {
        return 'Granite Speech 4.1 2B / Japanese'
    }
    return "Custom ($model / $language)"
}

function Set-HandySettingsDocument {
    param($Document)

    $temporaryPath = "$settingsPath.$PID.tmp"
    $backupPath = "$settingsPath.egormity-backup"
    $json = $Document | ConvertTo-Json -Depth 100
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

    try {
        [System.IO.File]::WriteAllText($temporaryPath, $json, $utf8WithoutBom)
        [System.IO.File]::Replace($temporaryPath, $settingsPath, $backupPath, $true)
        if (Test-Path -LiteralPath $backupPath) {
            Remove-Item -LiteralPath $backupPath -Force
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Invoke-HandyProfileToggle {
    $document = Get-HandySettingsDocument
    $currentProfile = Get-ProfileDescription -Document $document

    if ([string]$document.settings.selected_model -eq $voxtralModel) {
        $document.settings.selected_model = $graniteModel
        $document.settings.selected_language = 'ja'
        $nextProfile = 'Granite Speech 4.1 2B / Japanese'
    }
    else {
        $document.settings.selected_model = $voxtralModel
        $document.settings.selected_language = 'auto'
        $nextProfile = 'Voxtral Mini 4B Realtime / Auto'
    }

    $handyProcesses = @(Get-Process -Name handy -ErrorAction SilentlyContinue)
    $handyPath = $defaultHandyPath
    if ($handyProcesses.Count -gt 0 -and $handyProcesses[0].Path) {
        $handyPath = $handyProcesses[0].Path
    }
    if (-not (Test-Path -LiteralPath $handyPath)) {
        throw "Handy executable was not found at $handyPath"
    }

    try {
        if ($handyProcesses.Count -gt 0) {
            $handyProcesses | Stop-Process -Force
            foreach ($process in $handyProcesses) {
                $null = $process.WaitForExit(5000)
            }
        }

        Set-HandySettingsDocument -Document $document
        Start-Process -FilePath $handyPath -ArgumentList '--start-hidden' -WindowStyle Hidden
        Write-SwitchLog "Switched from '$currentProfile' to '$nextProfile'."
    }
    catch {
        if (-not (Get-Process -Name handy -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath $handyPath -ArgumentList '--start-hidden' -WindowStyle Hidden
        }
        throw
    }
}

if ($PrintStatus) {
    $document = Get-HandySettingsDocument
    $current = Get-ProfileDescription -Document $document
    $next = if ([string]$document.settings.selected_model -eq $voxtralModel) {
        'Granite Speech 4.1 2B / Japanese'
    }
    else {
        'Voxtral Mini 4B Realtime / Auto'
    }
    [pscustomobject]@{ CurrentProfile = $current; NextProfile = $next }
    exit 0
}

if ($ToggleOnce) {
    Invoke-HandyProfileToggle
    exit 0
}

if (-not ('Egormity.HandyModelSwitch.NativeHotKey' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Egormity.HandyModelSwitch
{
    public static class NativeHotKey
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct Point
        {
            public int X;
            public int Y;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct Message
        {
            public IntPtr Window;
            public uint Id;
            public UIntPtr WParam;
            public IntPtr LParam;
            public uint Time;
            public Point Cursor;
            public uint Private;
        }

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool UnregisterHotKey(IntPtr window, int id);

        [DllImport("user32.dll")]
        public static extern int GetMessage(out Message message, IntPtr window, uint min, uint max);
    }
}
'@
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\Egormity.HandyModelSwitch', [ref]$createdNew)
if (-not $createdNew) {
    $mutex.Dispose()
    exit 0
}

$hotKeyId = 1
$modifierShift = 0x0004
$modifierWindows = 0x0008
$virtualKeyF = 0x46
$windowMessageHotKey = 0x0312

try {
    $registered = [Egormity.HandyModelSwitch.NativeHotKey]::RegisterHotKey(
        [IntPtr]::Zero,
        $hotKeyId,
        ($modifierShift -bor $modifierWindows),
        $virtualKeyF
    )
    if (-not $registered) {
        $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "Could not register Win+Shift+F (Windows error $errorCode)."
    }

    Write-SwitchLog 'Registered Win+Shift+F.'
    $message = New-Object Egormity.HandyModelSwitch.NativeHotKey+Message
    while ([Egormity.HandyModelSwitch.NativeHotKey]::GetMessage(
        [ref]$message,
        [IntPtr]::Zero,
        0,
        0
    ) -gt 0) {
        if ($message.Id -eq $windowMessageHotKey -and $message.WParam.ToUInt64() -eq $hotKeyId) {
            try {
                Invoke-HandyProfileToggle
            }
            catch {
                Write-SwitchLog "Toggle failed: $($_.Exception.Message)"
            }
        }
    }
}
finally {
    $null = [Egormity.HandyModelSwitch.NativeHotKey]::UnregisterHotKey([IntPtr]::Zero, $hotKeyId)
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
