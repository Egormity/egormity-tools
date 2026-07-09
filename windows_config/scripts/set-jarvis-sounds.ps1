$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetRoot = Resolve-Path (Join-Path $scriptRoot "..\jarvis_sounds\wav")
$sharedSoundRoot = "C:\ProgramData\JarvisSounds"
$schemeRoot = "HKCU:\AppEvents\Schemes\Apps"
$updated = 0
$missing = New-Object System.Collections.Generic.List[string]

$notificationSoundMap = @{
    "Notification.Default" = "jarvis_he_is_insisting.wav"
    "Notification.IM" = "jarvis_he_is_insisting.wav"
    "Notification.SMS" = "jarvis_he_is_insisting.wav"
    "SystemNotification" = "jarvis_he_is_insisting.wav"
    "MessageNudge" = "jarvis_he_is_insisting.wav"
    "Notification.Mail" = "jarvis_i_pushed_the_call_to_voicemail.wav"
    "MailBeep" = "jarvis_i_pushed_the_call_to_voicemail.wav"
    "Notification.Reminder" = "jarvis_20_second_reminder.wav"
    "Notification.Looping.Alarm" = "jarvis_30_second_alarm.wav"
    "Notification.Looping.Call" = "jarvis_incoming_call.wav"
}

New-Item -ItemType Directory -Force -Path $sharedSoundRoot | Out-Null
foreach ($fileName in ($notificationSoundMap.Values | Sort-Object -Unique)) {
    $sourcePath = Join-Path $assetRoot $fileName
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sharedSoundRoot $fileName) -Force
    } else {
        $missing.Add($fileName) | Out-Null
    }
}

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

foreach ($eventName in $notificationSoundMap.Keys) {
    $newPath = Join-Path $sharedSoundRoot $notificationSoundMap[$eventName]
    if (-not (Test-Path -LiteralPath $newPath)) {
        continue
    }

    foreach ($schemeName in @(".Current", "Jarvi0")) {
        $eventKey = Join-Path $schemeRoot ".Default\$eventName\$schemeName"
        New-Item -Path $eventKey -Force | Out-Null
        & reg.exe add ($eventKey -replace "^HKCU:", "HKCU") /ve /d $newPath /f | Out-Null
        $updated++
    }
}

$notificationSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
if (Test-Path -LiteralPath $notificationSettings) {
    Remove-ItemProperty -LiteralPath $notificationSettings -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath $notificationSettings -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-ItemProperty -LiteralPath $_.PSPath -Name "SoundFile" -ErrorAction SilentlyContinue
    }

    $codexNotificationKey = Join-Path $notificationSettings "OpenAI.Codex_2p2nqsd0c76g0!App"
    New-Item -Path $codexNotificationKey -Force | Out-Null
    New-ItemProperty -Path $codexNotificationKey -Name "Enabled" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $codexNotificationKey -Name "ShowBanner" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $codexNotificationKey -Name "ShowInActionCenter" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $codexNotificationKey -Name "AllowNotificationSound" -PropertyType DWord -Value 1 -Force | Out-Null
}

Write-Host "Updated Jarvis sound events: $updated"
Write-Host "Notification sounds copied to: $sharedSoundRoot"

if ($missing.Count -gt 0) {
    Write-Host "Missing sound files:"
    $missing | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
}
