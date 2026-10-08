import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 760
    minimumWidth: 860
    minimumHeight: 560
    title: playerVisible ? "Tanaw — " + currentChannelName : "Tanaw"
    color: "#0d141b"
    flags: Qt.Window | (alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    Material.theme: Material.Dark
    Material.accent: Material.Cyan

    property bool playerVisible: false
    property bool alwaysOnTop: false
    property string currentChannelName: ""
    property string currentStreamUrl: ""
    property int currentChannelIndex: -1
    property bool playbackControlsVisible: true
    property var controller: tanawController
    property bool verifyQuit: false

    function showNotification(message) {
        toast.message = message
        toast.open()
    }

    function formatPlaybackTime(milliseconds) {
        const totalSeconds = Math.floor(milliseconds / 1000)
        const minutes = Math.floor(totalSeconds / 60)
        const seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    function showChannelInfoToast(index, name, url) {
        channelInfoToast.channelNumber = index
        channelInfoToast.channelName = name
        channelInfoToast.channelUrl = url
        channelInfoToast.open()
    }

    function openChannel(row) {
        const info = controller.channelInfo(row)
        if (!info.url) {
            showNotification("This channel has no stream URL")
            return
        }
        currentChannelIndex = row
        currentChannelName = info.name || "Unknown Channel"
        currentStreamUrl = info.url
        player.source = info.url
        player.play()
        playbackControlsVisible = true
        playerVisible = true
    }

    function openChannelInfo(row) {
        const info = controller.channelInfo(row)
        infoDialog.channelIndex = row
        infoDialog.channelName = info.name
        infoDialog.channelUrl = info.url
        infoDialog.open()
    }

    function closePlayer() {
        player.stop()
        player.source = ""
        playerVisible = false
        currentChannelIndex = -1
        if (root.visibility === Window.FullScreen)
            root.showNormal()
    }

    function closePlayerPrompt() {
        comfirmQuitDialog.open()
    }

    onClosing: function(closeEvent) {
        if (!verifyQuit) {
            closeEvent.accepted = false;
            comfirmQuitDialog_App.open();
        } else {
            closeEvent.accepted = true;
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.playerVisible && root.visibility === Window.FullScreen
        onActivated: root.showNormal()
    }

    Connections {
        target: controller
        function onNotification(message) {
            root.showNotification(message)
        }
        function onPlaylistError(message) {
            root.showNotification(message)
        }
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {
            volume: 1.0
        }
        videoOutput: videoOutput
        onErrorOccurred: {
            root.showNotification("Unable to play this channel: " + errorString)
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                    /* || mediaStatus === MediaPlayer.BufferedMedia */) {
                //root.showNotification(currentChannelName + " is ready")
                root.showChannelInfoToast(currentChannelIndex, currentChannelName, currentStreamUrl);
            }
        }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState) {
                playbackControlsTimer.restart()
            } else {
                playbackControlsTimer.stop()
                root.playbackControlsVisible = true
            }
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: root.playerVisible ? 1 : 0

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 18

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    radius: 18
                    color: "#172530"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 18
                        spacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "TANAW"
                                font.pixelSize: 30
                                font.weight: Font.Bold
                                color: "#e7f4fb"
                            }
                            Label {
                                text: controller.statusText
                                color: "#91a8b5"
                                font.pixelSize: 14
                            }
                        }

                        TextField {
                            id: searchField
                            Layout.preferredWidth: 250
                            placeholderText: "Search channels"
                            selectByMouse: true
                            onTextChanged: controller.channelModel.filterText = text
                        }

                        Button {
                            text: controller.channelModel.favoritesOnly ? "All channels" : "Favorites"
                            onClicked: controller.channelModel.favoritesOnly =
                                           !controller.channelModel.favoritesOnly
                        }

                        Button {
                            text: "Import / Export"
                            onClicked: playlistFilesMenu.popup()
                        }

                        Button {
                            text: "Refresh"
                            enabled: !controller.loading
                            onClicked: controller.refreshPlaylist()
                        }

                        Button {
                            text: "Add playlist"
                            highlighted: true
                            onClicked: addPlaylistDialog.open()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: "#111c24"

                    GridView {
                        id: channelGrid

                        anchors.fill: parent
                        anchors.margins: 16

                        clip: true

                        cellWidth: 274
                        cellHeight: 156

                        model: controller.channelModel

                        boundsBehavior: Flickable.StopAtBounds

                        cacheBuffer: 300

                        delegate: Rectangle {
                            required property int index
                            required property string name
                            required property string logo
                            required property string url
                            required property bool favorite

                            width: 260
                            height: 142

                            radius: 14

                            color: mouse.containsMouse
                                   ? "#263b48"
                                   : "#1a2a34"

                            border.width: favorite ? 2 : 1

                            border.color: favorite
                                          ? "#5ee7c6"
                                          : "#2d4654"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                Row {
                                    width: parent.width
                                    height: 50

                                    spacing: 12

                                    Rectangle {
                                        width: 50
                                        height: 50

                                        radius: 12

                                        color: "#294454"

                                        Image {
                                            anchors.fill: parent
                                            source: logo

                                            sourceSize.width: 50
                                            sourceSize.height: 50

                                            asynchronous: true
                                            cache: true

                                            fillMode: Image.PreserveAspectFit

                                            visible: status === Image.Ready
                                        }

                                        Label {
                                            anchors.centerIn: parent

                                            text: "TV"

                                            color: "#b9d4df"
                                            font.weight: Font.Bold

                                            visible: !logo || parent.children[0].status !== Image.Ready
                                        }
                                    }

                                    Label {
                                        width: parent.width - 62

                                        text: name

                                        color: "#e7f4fb"

                                        font.pixelSize: 16
                                        font.weight: Font.DemiBold

                                        elide: Text.ElideRight

                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                    }
                                }

                                Label {
                                    width: parent.width

                                    text: favorite
                                          ? "Favorite"
                                          : "Ready to play"

                                    color: favorite
                                           ? "#5ee7c6"
                                           : "#91a8b5"

                                    font.pixelSize: 12
                                }

                                Label {
                                    width: parent.width

                                    text: url

                                    color: "#708792"

                                    font.pixelSize: 11

                                    elide: Text.ElideMiddle
                                }
                            }

                            MouseArea {
                                id: mouse

                                anchors.fill: parent

                                hoverEnabled: true

                                acceptedButtons:
                                    Qt.LeftButton | Qt.RightButton

                                onClicked: function(mouseEvent) {
                                    if (mouseEvent.button === Qt.RightButton) {
                                        channelMenu.selectedIndex = index
                                        channelMenu.popup()
                                    } else {
                                        root.openChannelInfo(index)
                                    }
                                }

                                onPressAndHold: {
                                    channelMenu.selectedIndex = index
                                    channelMenu.popup()
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: channelGrid.count === 0

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.channelModel.favoritesOnly
                                  ? "No favorite channels"
                                  : (controller.channelModel.filterText.length > 0
                                     ? "No matching channels" : "No channels yet")
                            color: "#d7e8ef"
                            font.pixelSize: 21
                            font.weight: Font.DemiBold
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.channelModel.favoritesOnly
                                  ? "Add channels to Favorites from the channel menu"
                                  : (controller.channelModel.filterText.length > 0
                                     ? "Try a different search"
                                     : "Add an M3U playlist to start watching")
                            color: "#91a8b5"
                        }
                    }
                }
            }
        }

        Item {
            Rectangle {
                anchors.fill: parent
                color: "#05090c"
            }

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                anchors.bottomMargin: playerControls.visible ? playerControls.height : 0
                fillMode: VideoOutput.PreserveAspectFit
            }

            Label {
                anchors.centerIn: videoOutput
                visible: player.playbackState !== MediaPlayer.PlayingState
                         && player.mediaStatus !== MediaPlayer.LoadedMedia
                         && player.mediaStatus !== MediaPlayer.BufferedMedia
                text: player.errorString || "Preparing stream..."
                color: "#b8cbd4"
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: videoOutput
                z: 1
                onClicked: {
                    root.playbackControlsVisible = !root.playbackControlsVisible
                    if (root.playbackControlsVisible && player.playbackState === MediaPlayer.PlayingState)
                        playbackControlsTimer.restart()
                    else
                        playbackControlsTimer.stop()
                }
            }

            Rectangle {
                id: playbackControlPanel
                anchors.left: videoOutput.left
                anchors.right: videoOutput.right
                anchors.bottom: videoOutput.bottom
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                anchors.bottomMargin: 20
                height: playbackLayout.implicitHeight + 24
                radius: 12
                color: "#d910171d"
                border.color: "#405c6a"
                visible: root.playbackControlsVisible
                z: 2

                ColumnLayout {
                    id: playbackLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 24

                        Button {
                            text: "-10s"
                            visible: player.seekable
                            enabled: player.seekable
                            Accessible.name: "Seek back 10 seconds"
                            onClicked: player.position = Math.max(0, player.position - 10000)
                        }

                        Button {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 60
                            text: player.playbackState === MediaPlayer.PlayingState ? "\u23F8" : "\u25B6"
                            Accessible.name: player.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
                            onClicked: {
                                if (player.playbackState === MediaPlayer.PlayingState)
                                    player.pause()
                                else
                                    player.play()
                            }
                        }

                        Button {
                            text: "+10s"
                            visible: player.seekable
                            enabled: player.seekable
                            Accessible.name: "Seek forward 10 seconds"
                            onClicked: player.position = Math.min(player.duration, player.position + 10000)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            //visible: player.seekable && player.duration > 0

                            Label {
                                text: root.formatPlaybackTime(player.position)
                                color: "#e7f4fb"
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: Math.max(1, player.duration)
                                value: player.position
                                onMoved: player.position = value
                            }

                            Label {
                                text: root.formatPlaybackTime(player.duration)
                                color: "#e7f4fb"
                            }
                        }

                        Button {
                            text: "Audio"
                            Accessible.name: "Audio track selection"
                            onClicked: audioTrackMenu.popup()
                        }

                        Button {
                            text: "Captions"
                            Accessible.name: "Caption track selection"
                            onClicked: captionsMenu.popup()
                        }

                        Button {
                            id: fullscreenButton
                            text: "\u2922"
                            Accessible.name: "Fullscreen"
                            onClicked: {
                                if (root.visibility === Window.FullScreen) {
                                    root.showNormal()
                                } else {
                                    root.showFullScreen()
                                }
                            }
                        }
                    }
                }
            }

            Timer {
                id: playbackControlsTimer
                interval: 4000
                onTriggered: {
                    if (player.playbackState === MediaPlayer.PlayingState)
                        root.playbackControlsVisible = false
                }
            }

            Rectangle {
                id: playerControls
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 76
                color: "#e6111c25"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Button {
                        text: "Back"
                        onClicked: root.closePlayerPrompt()
                    }

                    // Label {
                    //     Layout.alignment: Qt.AlignHCenter
                    //     visible: player.mediaStatus === MediaPlayer.BufferedMedia
                    //     text: "LIVE"
                    //     color: "#ff6b63"
                    //     font.pixelSize: 11
                    //     font.weight: Font.Bold
                    // }
                }
            }
        }
    }

    Menu {
        id: audioTrackMenu

        MenuItem {
            text: "No audio tracks available"
            enabled: false
            visible: player.audioTracks.length === 0
        }

        Instantiator {
            model: player.audioTracks

            delegate: MenuItem {
                required property int index
                required property var modelData

                readonly property string trackLanguage:
                    modelData.stringValue(MediaMetaData.Language)
                readonly property string trackTitle:
                    modelData.stringValue(MediaMetaData.Title)

                text: "Audio track " + (index + 1) + ": "
                      + (trackLanguage || trackTitle || "Unknown language")
                checkable: true
                checked: player.activeAudioTrack === index
                onTriggered: player.activeAudioTrack = index
            }

            onObjectAdded: (index, object) => audioTrackMenu.insertItem(index + 1, object)
            onObjectRemoved: (index, object) => audioTrackMenu.removeItem(object)
        }
    }

    Menu {
        id: captionsMenu

        MenuItem {
            text: "No captions available"
            enabled: false
            visible: player.captions.length === 0
        }

        Instantiator {
            model: player.captions

            delegate: MenuItem {
                required property int index
                required property var modelData

                readonly property string trackLanguage:
                    modelData.stringValue(MediaMetaData.Language)
                readonly property string trackTitle:
                    modelData.stringValue(MediaMetaData.Title)

                text: "Caption track " + (index + 1) + ": "
                      + (trackLanguage || trackTitle || "Unknown language")
                checkable: true
                checked: player.activeCaptions === index
                onTriggered: player.activeCaptions = index
            }

            onObjectAdded: (index, object) => captionsMenu.insertItem(index + 1, object)
            onObjectRemoved: (index, object) => captionsMenu.removeItem(object)
        }
    }

    Menu {
        id: playlistFilesMenu
        MenuItem {
            text: "Import channel list..."
            onTriggered: importChannelsDialog.open()
        }
        MenuItem {
            text: "Export channel list..."
            onTriggered: exportChannelsDialog.open()
        }
    }

    FileDialog {
        id: importChannelsDialog
        title: "Import Tanaw channel list"
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON channel lists (*.json)", "All files (*)"]
        onAccepted: controller.importChannels(selectedFile)
    }

    FileDialog {
        id: exportChannelsDialog
        title: "Export Tanaw channel list"
        fileMode: FileDialog.SaveFile
        currentFile: "channels.json"
        nameFilters: ["JSON channel lists (*.json)"]
        onAccepted: controller.exportChannels(selectedFile)
    }

    Menu {
        id: channelMenu
        property int selectedIndex: -1

        MenuItem {
            text: "Play"
            onTriggered: root.openChannel(channelMenu.selectedIndex)
        }
        MenuItem {
            text: controller.channelInfo(channelMenu.selectedIndex).favorite
                  ? "Remove from Favorites" : "Add to Favorites"
            onTriggered: controller.toggleFavorite(channelMenu.selectedIndex)
        }
        MenuItem {
            text: "Channel Info"
            onTriggered: root.openChannelInfo(channelMenu.selectedIndex)
        }
        MenuItem {
            text: "Copy Stream URL"
            onTriggered: controller.copyStreamUrl(
                             controller.channelInfo(channelMenu.selectedIndex).url)
        }
        MenuItem {
            text: "Share"
            onTriggered: controller.shareStreamUrl(
                             controller.channelInfo(channelMenu.selectedIndex).url)
        }
        MenuSeparator {}
        MenuItem {
            text: "Remove Channel"
            onTriggered: {
                removeDialog.channelIndex = channelMenu.selectedIndex
                removeDialog.channelName = controller.channelInfo(
                            channelMenu.selectedIndex).name
                removeDialog.open()
            }
        }
    }

    Dialog {
        id: addPlaylistDialog
        title: "Add Playlist"
        modal: true
        width: 500
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel

        function submitPlaylist() {
            if (controller.addPlaylist(playlistUrlField.text)) {
                playlistUrlField.text = ""
                addPlaylistDialog.close()
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                text: "Paste an M3U playlist URL"
                color: "#91a8b5"
            }
            TextField {
                id: playlistUrlField
                Layout.fillWidth: true
                placeholderText: "https://example.com/playlist.m3u"
                selectByMouse: true
                onAccepted: addPlaylistDialog.submitPlaylist()
            }
            Button {
                id: addPlaylistButton
                text: "Add playlist"
                highlighted: true
                Layout.alignment: Qt.AlignRight
                onClicked: addPlaylistDialog.submitPlaylist()
            }
        }
        onClosed: playlistUrlField.text = ""
    }

    Dialog {
        id: infoDialog
        property int channelIndex: -1
        property string channelName: ""
        property string channelUrl: ""
        title: channelName
        modal: true
        width: 560
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 8
            Label {
                text: "Channel number: " + (infoDialog.channelIndex + 1)
                color: "#c4d9e2"
            }
            Label {
                text: "Name: " + infoDialog.channelName
                color: "#c4d9e2"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Label {
                text: "URL: " + infoDialog.channelUrl
                color: "#91a8b5"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Button {
                text: "Play"
                highlighted: true
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    infoDialog.close()
                    root.openChannel(infoDialog.channelIndex)
                }
            }
        }
    }

    Dialog {
        id: removeDialog
        property int channelIndex: -1
        property string channelName: ""
        title: "Remove channel?"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton

        ColumnLayout {
            width: 360
            spacing: 14
            Label {
                text: "Remove \"" + removeDialog.channelName + "\" from your playlist?"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button {
                    text: "Cancel"
                    onClicked: removeDialog.close()
                }
                Button {
                    text: "Remove"
                    highlighted: true
                    onClicked: {
                        controller.removeChannel(removeDialog.channelIndex)
                        removeDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: comfirmQuitDialog
        title: "Are you sure to stop?"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton

        ColumnLayout {
            width: 100
            spacing: 2
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button {
                    text: "No"
                    onClicked: comfirmQuitDialog.close()
                }
                Button {
                    text: "Yes"
                    highlighted: true
                    onClicked: {
                        root.closePlayer()
                        comfirmQuitDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: comfirmQuitDialog_App
        title: "Are you sure to quit?"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton

        ColumnLayout {
            width: 100
            spacing: 2
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button {
                    text: "No"
                    onClicked: comfirmQuitDialog_App.close()
                }
                Button {
                    text: "Yes"
                    highlighted: true
                    onClicked: {
                        verifyQuit = true
                        Qt.quit()
                    }
                }
            }
        }
    }

    Popup {
        id: toast
        property string message: ""
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: parent.height - height - 28
        padding: 14
        background: Rectangle {
            radius: 10
            color: "#263f4d"
            border.color: "#4d6d7c"
        }
        contentItem: Label {
            text: toast.message
            color: "#e7f4fb"
        }
        onOpened: toastTimer.restart()
        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: toast.close()
        }
    }

    
    Popup {
        id: channelInfoToast

        property string channelNumber: "0"
        property string channelName: "Name"
        property string channelUrl: "Url"

        parent: Overlay.overlay

        x: (parent.width - width) / 2
        y: parent.height - height - 28

        width: Math.min(parent.width - 32, 400)
        padding: 18

        closePolicy: Popup.NoAutoClose
        modal: false
        dim: false

        background: Rectangle {
            radius: 12
            color: "#263f4d"
            border.color: "#4d6d7c"
        }

        contentItem: Row {
            spacing: 8

            Text {
                id: channelNumberLabel

                text: channelInfoToast.channelNumber
                color: "#e7f4fb"
                font.pixelSize: 16
                font.bold: true

                padding: 12

                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 4

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: channelInfoToast.channelName
                    color: "#e7f4fb"
                    font.pixelSize: 12

                    width: channelInfoToast.width - 110
                    elide: Text.ElideRight
                }

                Text {
                    text: channelInfoToast.channelUrl
                    color: "#b8cbd5"
                    font.pixelSize: 8

                    width: channelInfoToast.width - 110
                    elide: Text.ElideRight
                }
            }
        }

        onOpened: channelInfoToastTimer.restart()

        Timer {
            id: channelInfoToastTimer
            interval: 3000
            onTriggered: channelInfoToast.close()
        }
    }

    onVisibilityChanged: {
        if (root.visibility == Window.FullScreen) {
            if (playerVisible == true) {
                playerControls.visible = false
                fullscreenButton.text = "\u27C0"
                root.showNotification("Press ESC to exit fullscreen...")
            }
        }
        else if (root.visibility == Window.Windowed) {
            if (playerVisible == true) {
                playerControls.visible = true
                fullscreenButton.text = "\u2922"
            }
        }
    }
}