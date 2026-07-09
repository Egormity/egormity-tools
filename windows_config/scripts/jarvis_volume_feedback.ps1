$ErrorActionPreference = 'Stop'

$soundPath = 'C:\\Users\\kotla\\Desktop\\egormity-tools\\windows_config\\jarvis_sounds\\wav\\jarvis_accessed.wav'
$pollMs = 120
$cooldownMs = 250

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class AudioEndpoint {
  private const int ERender = 0;
  private const int EMultimedia = 1;
  private static IAudioEndpointVolume endpoint;

  public static float GetVolume() {
    EnsureEndpoint();
    float level;
    endpoint.GetMasterVolumeLevelScalar(out level);
    return level;
  }

  public static bool GetMute() {
    EnsureEndpoint();
    bool muted;
    endpoint.GetMute(out muted);
    return muted;
  }

  private static void EnsureEndpoint() {
    if (endpoint != null) {
      return;
    }

    var enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumerator());
    IMMDevice device;
    enumerator.GetDefaultAudioEndpoint(ERender, EMultimedia, out device);
    object endpointObject;
    Guid endpointVolumeGuid = typeof(IAudioEndpointVolume).GUID;
    device.Activate(ref endpointVolumeGuid, 23, IntPtr.Zero, out endpointObject);
    endpoint = (IAudioEndpointVolume)endpointObject;
  }

  [ComImport]
  [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
  private class MMDeviceEnumerator {}

  [ComImport]
  [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  private interface IMMDeviceEnumerator {
    int NotImpl1();
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
  }

  [ComImport]
  [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  private interface IMMDevice {
    int Activate(ref Guid iid, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object interfacePointer);
  }

  [ComImport]
  [Guid("5CDF2C82-841E-4546-9722-0CF74078229A")]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  private interface IAudioEndpointVolume {
    int RegisterControlChangeNotify(IntPtr client);
    int UnregisterControlChangeNotify(IntPtr client);
    int GetChannelCount(out uint channelCount);
    int SetMasterVolumeLevel(float levelDb, Guid eventContext);
    int SetMasterVolumeLevelScalar(float level, Guid eventContext);
    int GetMasterVolumeLevel(out float levelDb);
    int GetMasterVolumeLevelScalar(out float level);
    int SetChannelVolumeLevel(uint channelNumber, float levelDb, Guid eventContext);
    int SetChannelVolumeLevelScalar(uint channelNumber, float level, Guid eventContext);
    int GetChannelVolumeLevel(uint channelNumber, out float levelDb);
    int GetChannelVolumeLevelScalar(uint channelNumber, out float level);
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool isMuted, Guid eventContext);
    int GetMute([MarshalAs(UnmanagedType.Bool)] out bool isMuted);
    int GetVolumeStepInfo(out uint step, out uint stepCount);
    int VolumeStepUp(Guid eventContext);
    int VolumeStepDown(Guid eventContext);
    int QueryHardwareSupport(out uint hardwareSupportMask);
    int GetVolumeRange(out float minDb, out float maxDb, out float incrementDb);
  }
}
'@

if (-not (Test-Path -LiteralPath $soundPath)) {
  throw "Missing sound file: $soundPath"
}

$player = New-Object System.Media.SoundPlayer $soundPath
$player.Load()

$lastVolume = [AudioEndpoint]::GetVolume()
$lastMute = [AudioEndpoint]::GetMute()
$lastPlayed = [DateTime]::MinValue

while ($true) {
  Start-Sleep -Milliseconds $pollMs

  $volume = [AudioEndpoint]::GetVolume()
  $mute = [AudioEndpoint]::GetMute()
  $volumeChanged = [Math]::Abs($volume - $lastVolume) -gt 0.0005
  $muteChanged = $mute -ne $lastMute

  if ($volumeChanged -or $muteChanged) {
    $now = Get-Date
    if (($now - $lastPlayed).TotalMilliseconds -ge $cooldownMs) {
      $player.Stop()
      $player.Play()
      $lastPlayed = $now
    }

    $lastVolume = $volume
    $lastMute = $mute
  }
}

