import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root

    property string period: ""
    property int temperature: 0
    property real brightness: 1
    property real elevation: 0
    property string location: ""
    property bool enabled: true
    readonly property bool running: period !== ""

    readonly property string icon: !running || !enabled ? "󰖨" : period === "Night" ? "󰖔" : period === "Transition" ? "󰖚" : "󰖨"

    function parse(text) {
        const grab = (key) => { const m = text.match(new RegExp("^Notice: " + key + ": (.*)$", "m")); return m ? m[1].trim() : "" }
        period = grab("Period")
        temperature = parseInt(grab("Color temperature")) || 0
        brightness = parseFloat(grab("Brightness")) || 1
        elevation = parseFloat(grab("Solar elevation")) || 0
        location = grab("Location")
    }

    function toggle() {
        enabled = !enabled
        toggleProc.running = true
    }

    active: popup.visible

    Process {
        id: status
        running: true
        command: ["sh", "-c", "pgrep -x gammastep >/dev/null && gammastep -p 2>&1 || true"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process {
        id: toggleProc
        command: ["pkill", "-USR1", "-x", "gammastep"]
    }

    Process {
        id: restartProc
        command: ["sh", "-c", "pkill -x gammastep; pkill -x gammastep-indicator; sleep 1; setsid gammastep-indicator >/dev/null 2>&1 &"]
        onExited: { root.enabled = true; statusRefresh.restart() }
    }

    Timer { id: statusRefresh; interval: 3000; onTriggered: status.running = true }

    Timer {
        interval: popup.visible ? 5000 : 60000
        running: true
        repeat: true
        onTriggered: status.running = true
    }

    IpcHandler {
        target: "gammastep"
        function toggle(): void { root.toggle() }
        function popup(): void { popup.toggle() }
    }

    Row {
        spacing: 5
        BarText {
            text: root.icon
            color: !root.running ? Theme.red : !root.enabled ? Theme.muted : root.period === "Night" ? Theme.peach : Theme.fg
            font.pixelSize: Theme.barFontSize
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }
        BarText {
            text: !root.running ? "off" : !root.enabled ? "6500K" : root.temperature + "K"
            font.pixelSize: Theme.barFontSize
            color: root.running && root.enabled ? Theme.fg : Theme.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.toggle() : popup.toggle()
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 360
        onVisibleChanged: if (visible) status.running = true

        PopupHeader {
            icon: root.icon
            iconColor: root.period === "Night" ? Theme.peach : Theme.yellow
            title: "Night light"
            subtitle: !root.running ? "gammastep is not running" : !root.enabled ? "Paused, screen at 6500K" : root.period + " · " + root.temperature + "K"
        }

        Item { width: 1; height: 4 }
        SectionLabel { visible: root.running; text: "STATUS" }
        Row {
            visible: root.running
            spacing: 12
            Stat { label: "PERIOD"; value: root.period }
            Stat { label: "TEMPERATURE"; value: root.temperature + "K" }
            Stat { label: "BRIGHTNESS"; value: Math.round(root.brightness * 100) + "%" }
        }
        Row {
            visible: root.running
            spacing: 12
            Stat { label: "SUN ELEVATION"; value: root.elevation.toFixed(1) + "°" }
            Stat { label: "LOCATION"; value: root.location; width: 212 }
        }

        Divider {}

        ActionRow { label: "Night light"; value: root.enabled ? "on" : "off"; onClicked: root.toggle() }
        ActionRow { label: "Restart gammastep"; value: "󰑐"; onClicked: restartProc.running = true }
        ActionRow { label: "Edit config"; value: "󰏌"; onClicked: { Quickshell.execDetached(["ghostty", "-e", "nvim", Quickshell.env("HOME") + "/.config/gammastep/config.ini"]); popup.visible = false } }
    }
}
