# Tanaw for Windows

Tanaw is a Qt Quick 6.8 desktop IPTV playlist browser and player, ported from the
[Tanaw Android app](https://github.com/jarred-new/Tanaw-Android).

## Features

- Load M3U/M3U8 playlists over HTTP or HTTPS.
- Parse channel names, stream URLs, and `tvg-logo` artwork.
- Persist the playlist and channel list with `QSettings`.
- Search channels by name.
- Filter the library to Favorites.
- Import and export channel lists as JSON.
- Play streams with Qt Multimedia.
- Fullscreen playback and a Windows-friendly “always on top” mode.
- Channel details, favorites, copy URL, share via the default mail app, and removal.
- Responsive desktop channel grid with mouse, right-click, and keyboard-friendly controls.

## Build on Windows

Install:

- Visual Studio 2022 Build Tools with the **Desktop development with C++** workload
  and the x64 tools.
- Qt 6.8.x for `msvc2022_64`.
- CMake 3.21 or newer.

From a **x64 Native Tools Command Prompt for VS 2022**:

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release --parallel
windeployqt --release --qmldir qml build\Release\Tanaw.exe
```

The GitHub Actions workflow performs the same build with the
`win64_msvc2022_64` Qt kit and publishes `Tanaw-Windows-x64.zip` as an artifact.

## Android parity notes

The port was based on all runtime Java and XML sources in Tanaw-Android:

- `MainActivity.java` → `TanawController`, `ChannelModel`, and `qml/main.qml`
- `TVPlayer.java` → Qt Multimedia `MediaPlayer` and `VideoOutput`
- `PrefHelper.java` → `QSettings`
- `activity_main.xml` → the responsive desktop library view
- `activity_tvplayer.xml` → the player view and desktop controls
- `tvinfo.xml` → the channel details dialog and playback notifications
- Android drawable icons → text/icon-labelled desktop controls that work with mouse and keyboard

The Android-only system behaviors (Android intents, system share sheet, and OS
picture-in-picture) are replaced with Windows equivalents: the default mail
handler for sharing and an always-on-top playback window mode.