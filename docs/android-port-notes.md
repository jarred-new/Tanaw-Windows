# Android source coverage

This document records the Android sources reviewed for the Windows port and the
Qt Quick equivalent that owns each behavior.

| Android source | Windows implementation |
| --- | --- |
| `MainActivity.java` | `src/tanawcontroller.*`, `src/channelmodel.*`, `qml/main.qml` |
| `TVPlayer.java` | `qml/main.qml` using `MediaPlayer` and `VideoOutput` |
| `PrefHelper.java` | `QSettings` keys in `TanawController::loadSavedPlaylist()` |
| `TVInfoToast.java` | QML toast and channel information dialog |
| `activity_main.xml` | QML header, search, refresh, add-playlist dialog, and channel grid |
| `activity_tvplayer.xml` | QML playback screen and playback toolbar |
| `tvinfo.xml` | QML channel information dialog |
| drawable vector XML | Desktop-native text controls and Qt Quick styling |
| values/themes XML | Material Dark Qt Quick Controls theme and palette |
| `AndroidManifest.xml` | CMake/Qt desktop executable; HTTP access is provided by Qt Network |

The playlist parser intentionally keeps the Android behavior of pairing each
`#EXTINF` record with the following non-comment URL. It adds a clear error when
the document contains no channels, which is more useful on a desktop.