# Windhawk Mod Settings

## explorer-details-better-file-sizes

- Disabled: False
- Library: explorer-details-better-file-sizes_1.5.1_790807.dll
- Include: *
- Exclude: conhost.exe|Plex*.exe|backgroundTaskHost.exe|LockApp.exe|SearchHost.exe|ShellExperienceHost.exe|StartMenuExperienceHost.exe|msedgewebview2.exe|windhawk.exe|*\UI\VSCodium.exe
- Architecture:
- Version: 1.5.1

Settings:

```json
{
    "useIecTerms":  0,
    "calculateFolderSizes":  "disabled",
    "disableKbOnlySizes":  1,
    "sortSizesMixFolders":  1
}
```

## file-explorer-content-animation

- Disabled: False
- Library: file-explorer-content-animation_1.0.1_473086.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 1.0.1

Settings:

```json
{
    "reverseDirection":  0,
    "fade":  1,
    "navigationDelay":  140,
    "pageTransitions":  1,
    "distance":  32,
    "propertyPages.tabTransitions":  1,
    "firstOpenDelay":  500,
    "animateNavPane":  0,
    "duration":  420,
    "propertyPages.animate":  1
}
```

## taskbar-autohide-instant-show

- Disabled: False
- Library: taskbar-autohide-instant-show_2.2_673827.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 2.2

Settings:

```json
{
    "hideDelay":  1,
    "frameRate":  60,
    "edgeDetection":  0,
    "showDuration":  200,
    "showSpeedup":  400,
    "oldTaskbarOnWin11":  0,
    "hideDuration":  200,
    "hideSpeedup":  400,
    "unhideDelay":  1,
    "animationType":  "slideFade"
}
```

## taskbar-auto-hide-per-monitor

- Disabled: False
- Library: taskbar-auto-hide-per-monitor_1.0.3_704002.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 1.0.3

Settings:

```text
(none)
```

## taskbar-dock-animation

- Disabled: False
- Library: taskbar-dock-animation_1.9.2_432844.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 1.9.2

Settings:

```json
{
    "AnimationType":  0,
    "DisableBounce":  0,
    "LerpSpeed":  60,
    "DisableVerticalBounce":  0,
    "MirrorForTopTaskbar":  0,
    "ExcludeSystemButtonsMode":  0,
    "MaxScale":  130,
    "EffectRadius":  100,
    "TaskbarLabelsMode":  0,
    "FocusDuration":  150,
    "SpacingFactor":  50,
    "BounceDelay":  500
}
```

## taskbar-grouping

- Disabled: False
- Library: taskbar-grouping_1.3.10_155120.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 1.3.10

Settings:

```json
{
    "customGroups[0].items[0]":  "group1-program1.exe",
    "useWindowIcons":  0,
    "oldTaskbarOnWin11":  0,
    "pinnedItemsMode":  "replace",
    "customGroups[0].items[1]":  "group1-program2.exe",
    "groupingMode":  "regular",
    "customGroups[0].name":  "Group 1",
    "excludedPrograms[0]":  "excluded1.exe",
    "placeUngroupedItemsTogether":  "0"
}
```

## windows-11-file-explorer-styler

- Disabled: False
- Library: windows-11-file-explorer-styler_1.4_134021.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 1.4

Settings:

```json
{
    "xamlDiagnosticsHandling":  "alert",
    "explorerFrameContainerHeight":  0,
    "backgroundTranslucentEffect":  "",
    "styleConstants[0]":  "",
    "themeResourceVariables[0]":  "",
    "backgroundTranslucentEffectRegion":  "",
    "theme":  "TintedGlass",
    "controlStyles[0].target":  "",
    "controlStyles[0].styles[0]":  ""
}
```

## windows-11-notification-center-styler

- Disabled: False
- Library: windows-11-notification-center-styler_1.5_749022.dll
- Include: ShellExperienceHost.exe|ShellHost.exe
- Exclude:
- Architecture: x86-64
- Version: 1.5

Settings:

```json
{
    "themeResourceVariables[0]":  "",
    "controlStyles[0].target":  "",
    "styleConstants[0]":  "",
    "controlStyles[0].styles[0]":  "",
    "theme":  "TranslucentShell"
}
```

## windows-11-start-menu-styler

- Disabled: False
- Library: windows-11-start-menu-styler_1.6_395858.dll
- Include: StartMenuExperienceHost.exe|SearchHost.exe|SearchApp.exe
- Exclude:
- Architecture: x86-64
- Version: 1.6

Settings:

```json
{
    "webContentCustomJs":  "",
    "disableNewStartMenuLayout":  "",
    "styleConstants[0]":  "",
    "webContentStyles[0].target":  "",
    "themeResourceVariables[0]":  "",
    "controlStyles[0].styles[0]":  "",
    "theme":  "TranslucentStartMenu",
    "webContentStyles[0].styles[0]":  "",
    "controlStyles[0].target":  ""
}
```

## windows-11-taskbar-styler

- Disabled: False
- Library: windows-11-taskbar-styler_1.7_922291.dll
- Include: explorer.exe
- Exclude:
- Architecture: x86-64
- Version: 1.7

Settings:

```json
{
    "xamlDiagnosticsHandling":  "alert",
    "styleConstants[0]":  "",
    "themeResourceVariables[0]":  "",
    "controlStyles[0].styles[0]":  "",
    "theme":  "TranslucentTaskbar",
    "controlStyles[0].target":  ""
}
```

