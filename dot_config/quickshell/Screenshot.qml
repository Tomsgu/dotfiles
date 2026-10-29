import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"
    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Screenshots"

    property int recordingSeconds: -1
    property var recent: []
    property string copied: ""
    readonly property bool recording: recordingSeconds >= 0

    function clock(seconds) {
        const m = Math.floor(seconds / 60), s = seconds % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function run(script, mode) {
        popup.visible = false
        Quickshell.execDetached(["sh", "-c", "sleep 0.25; exec \"$0\" \"$@\"", root.bin + script].concat(mode ? [mode] : []))
    }

    function copy(path) {
        Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < \"$0\"", path])
        copied = path
        copiedReset.restart()
    }

    function edit(path) {
        popup.visible = false
        Quickshell.execDetached(["sh", "-c", "command -v satty >/dev/null && exec satty --filename \"$0\" --output-filename \"$0\" || exec pinta \"$0\"", path])
    }

    function refresh() {
        status.running = true
        if (popup.visible) listing.running = true
    }

    active: popup.visible

    Process {
        id: status
        running: true
        command: ["sh", "-c", "ps -o etimes= -C wf-recorder | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = parseInt(text.trim())
                root.recordingSeconds = isNaN(seconds) ? -1 : seconds
            }
        }
    }

    Process {
        id: listing
        command: ["sh", "-c", "ls -t1 \"$0\"/*.png 2>/dev/null | head -9", root.folder]
        stdout: StdioCollector { onStreamFinished: root.recent = text.split("\n").filter(line => line !== "") }
    }

    Timer {
        interval: root.recording ? 1000 : 10000
        running: true
        repeat: true
        onTriggered: status.running = true
    }

    Timer { id: copiedReset; interval: 1500; onTriggered: root.copied = "" }

    IpcHandler {
        target: "screenshot"
        function refresh(): void { root.refresh() }
        function toggle(): void { popup.toggle() }
    }

    Row {
        spacing: 5
        BarText {
            text: root.recording ? "󰑋" : "󰹑"
            color: root.recording ? Theme.red : Theme.muted
            font.pixelSize: Theme.barFontSize
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }
        BarText {
            visible: root.recording
            text: root.clock(root.recordingSeconds)
            color: Theme.red
            font.pixelSize: Theme.barFontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (root.recording) root.run("screenrec")
            else if (mouse.button === Qt.RightButton) root.run("screenshot", "region")
            else popup.toggle()
        }
    }

    component ActionRow: Item {
        property string icon
        property string label
        property string hint
        property color tint: Theme.fg
        signal clicked
        width: parent.width
        height: 28
        Rectangle { anchors.fill: parent; anchors.margins: -4; radius: 5; color: Theme.iconBg; visible: area.containsMouse }
        BarText { anchors.verticalCenter: parent.verticalCenter; width: 20; horizontalAlignment: Text.AlignHCenter; text: parent.icon; color: parent.tint; font.pixelSize: 14 }
        BarText { x: 30; anchors.verticalCenter: parent.verticalCenter; text: parent.label; color: parent.tint }
        BarText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: parent.hint; color: Theme.muted; font.pixelSize: 10 }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 400
        onVisibleChanged: if (visible) { listing.running = true; status.running = true }

        PopupHeader {
            icon: root.recording ? "󰑋" : "󰹑"
            iconColor: root.recording ? Theme.red : Theme.accent
            title: root.recording ? "Recording " + root.clock(root.recordingSeconds) : "Capture"
            subtitle: "Saved to Pictures/Screenshots and copied"
        }

        Item { width: 1; height: 4 }
        SectionLabel { text: "SCREENSHOT" }
        ActionRow { icon: "󰩭"; label: "Region or window"; hint: "mod+p"; onClicked: root.run("screenshot", "region") }
        ActionRow { icon: "󰍹"; label: "Focused screen"; onClicked: root.run("screenshot", "output") }
        ActionRow { icon: "󰍺"; label: "All screens"; onClicked: root.run("screenshot", "all") }

        SectionLabel { text: "RECORDING" }
        ActionRow {
            icon: root.recording ? "󰓛" : "󰑋"
            label: root.recording ? "Stop recording" : "Record region or window"
            hint: "mod+shift+p"
            tint: root.recording ? Theme.red : Theme.fg
            onClicked: root.run("screenrec")
        }

        Divider { visible: root.recent.length > 0 }

        Item {
            visible: root.recent.length > 0
            width: parent.width
            height: 16
            SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "RECENT" }
            BarText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "click copies · right click edits"
                color: Theme.muted
                font.pixelSize: 10
            }
        }

        Grid {
            visible: root.recent.length > 0
            width: parent.width
            columns: 3
            spacing: 8

            Repeater {
                model: root.recent
                Rectangle {
                    id: thumb
                    required property string modelData
                    width: (parent.width - 16) / 3
                    height: width * 0.62
                    radius: 6
                    color: Theme.iconBg
                    border.width: thumbArea.containsMouse || root.copied === modelData ? 2 : 0
                    border.color: root.copied === modelData ? Theme.green : Theme.accent
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: "file://" + thumb.modelData
                        sourceSize.width: 240
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        visible: root.copied === thumb.modelData
                        anchors.centerIn: parent
                        width: copiedLabel.implicitWidth + 14
                        height: 22
                        radius: 4
                        color: Theme.cardBg
                        BarText { id: copiedLabel; anchors.centerIn: parent; text: "󰄬 Copied"; color: Theme.green; font.pixelSize: 11 }
                    }

                    MouseArea {
                        id: thumbArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => mouse.button === Qt.RightButton ? root.edit(thumb.modelData) : root.copy(thumb.modelData)
                    }
                }
            }
        }

        Divider {}

        ActionRow {
            icon: "󰉋"
            label: "Open screenshots folder"
            onClicked: { popup.visible = false; Quickshell.execDetached(["ghostty", "-e", "yazi", root.folder]) }
        }
    }
}
