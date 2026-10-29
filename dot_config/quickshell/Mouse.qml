import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root

    property bool present: false
    property bool connected: false
    property string path: ""
    property string model: ""
    property string mode: ""
    property string firmware: ""
    property string serial: ""
    property int dpi: 0
    property int pollRate: 0
    property int charge: 0
    property bool charging: false
    property int lowThreshold: 0
    property int idleTime: 0
    property int activeStage: 0
    property var stages: []
    property string accelProfile: ""
    property real accel: 0

    readonly property bool low: battery <= 15 && !charging
    readonly property int battery: Math.round(charge / 255 * 100)
    readonly property int feelsLike: accelProfile === "flat" ? Math.round(dpi * (1 + accel)) : dpi
    readonly property color batteryColor: !connected ? Theme.muted : charging ? Theme.green : low ? Theme.red : battery <= 30 ? Theme.yellow : Theme.fg

    function parse(text) {
        const values = {}
        for (const line of text.split("\n")) {
            const split = line.indexOf("=")
            if (split > 0) values[line.slice(0, split)] = line.slice(split + 1).trim()
        }
        present = values.present === "1"
        connected = "dpi" in values
        accelProfile = values.accel_profile || ""
        accel = parseFloat(values.accel) || 0
        if (!connected) return

        const name = values.name.match(/^Razer (.*?) \((\w+)\)$/)
        path = values.path
        model = name ? name[1] : values.name
        mode = name ? name[2] : ""
        firmware = values.firmware
        serial = values.serial
        dpi = parseInt(values.dpi) || 0
        pollRate = parseInt(values.poll) || 0
        charge = parseInt(values.charge) || 0
        charging = values.charging === "1"
        lowThreshold = Math.round((parseInt(values.low) || 0) / 255 * 100)
        idleTime = parseInt(values.idle) || 0

        const bytes = values.stages.split(" ").filter(b => b !== "").map(Number)
        activeStage = bytes[0] || 0
        const list = []
        for (let i = 1; i + 3 < bytes.length; i += 4) list.push({ index: list.length + 1, dpi: bytes[i] * 256 + bytes[i + 1] })
        stages = list
    }

    function setStage(index) {
        stageProc.command = ["python3", "-c", "import sys\npath, n = sys.argv[1], int(sys.argv[2])\ndata = bytearray(open(path + 'dpi_stages', 'rb').read())\ndata[0] = n\nopen(path + 'dpi_stages', 'wb').write(data)\nopen(path + 'dpi', 'wb').write(bytes(data[n * 4 - 3:n * 4 + 1]))", path, String(index)]
        stageProc.running = true
    }

    function formatIdle(seconds) {
        return seconds >= 60 ? Math.round(seconds / 60) + " min" : seconds + " s"
    }

    visible: present
    active: popup.visible

    Process {
        id: status
        running: true
        command: ["sh", "-c", `
            for d in /sys/bus/hid/drivers/razermouse/*/; do
                [ -r "$d/dpi" ] || continue
                echo present=1
                [ "$(cat "$d/dpi")" = "0:0" ] && continue
                echo "path=$d"
                echo "name=$(cat "$d/device_type")"
                echo "firmware=$(cat "$d/firmware_version")"
                echo "serial=$(cat "$d/device_serial")"
                echo "dpi=$(cat "$d/dpi")"
                echo "poll=$(cat "$d/poll_rate")"
                echo "charge=$(cat "$d/charge_level")"
                echo "charging=$(cat "$d/charge_status")"
                echo "low=$(cat "$d/charge_low_threshold")"
                echo "idle=$(cat "$d/device_idle_time")"
                echo "stages=$(od -An -tu1 -v "$d/dpi_stages" | tr -s ' \\n' ' ')"
                break
            done
            swaymsg -t get_inputs | jq -r '[.[] | select(.vendor == 5426 and .type == "pointer" and .libinput.accel_speed != null)][0] // empty | "accel_profile=\\(.libinput.accel_profile)\\naccel=\\(.libinput.accel_speed)"'
        `]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process {
        id: stageProc
        onExited: status.running = true
    }

    Timer {
        interval: popup.visible ? 5000 : 60000
        running: true
        repeat: true
        onTriggered: status.running = true
    }

    IpcHandler {
        target: "mouse"
        function popup(): void { popup.toggle() }
    }

    Row {
        spacing: 5
        BarText {
            text: root.connected ? "󰍽" : "󰍾"
            color: root.batteryColor
            font.pixelSize: Theme.barFontSize
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }
        BarText {
            text: root.connected ? root.battery + "%" + (root.charging ? "+" : "") : "off"
            color: root.batteryColor
            font.pixelSize: Theme.barFontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 360
        onVisibleChanged: if (visible) status.running = true

        PopupHeader {
            icon: root.connected ? "󰍽" : "󰍾"
            iconColor: root.batteryColor
            title: root.model || "Razer mouse"
            subtitle: root.connected ? root.mode + " · firmware " + root.firmware : "Asleep or switched off"
        }

        Item { width: 1; height: 4; visible: root.connected }
        SectionLabel { visible: root.connected; text: "BATTERY" }
        UsageBar { visible: root.connected; pct: root.battery; fillColor: root.batteryColor }
        Row {
            visible: root.connected
            spacing: 12
            Stat { label: "LEVEL"; value: root.battery + "%"; valueColor: root.batteryColor }
            Stat { label: "STATUS"; value: root.charging ? "Charging" : "On battery" }
            Stat { label: "LOW WARNING"; value: root.lowThreshold + "%" }
        }
        Row {
            visible: root.connected
            spacing: 12
            Stat { label: "SLEEP AFTER"; value: root.formatIdle(root.idleTime) }
            Stat { label: "SERIAL"; value: root.serial; width: 212 }
        }

        Divider { visible: root.connected }
        SectionLabel { visible: root.connected; text: "SENSOR" }
        Row {
            visible: root.connected
            spacing: 12
            Stat { label: "DPI"; value: String(root.dpi) }
            Stat { label: "POLLING"; value: root.pollRate + " Hz" }
            Stat { label: "FEELS LIKE"; value: root.feelsLike + " DPI" }
        }
        Row {
            visible: root.accelProfile !== ""
            spacing: 12
            Stat { label: "SWAY PROFILE"; value: root.accelProfile }
            Stat { label: "SWAY ACCEL"; value: root.accel.toFixed(2) }
        }

        SectionLabel { visible: root.stages.length > 0; text: "DPI STAGES" }
        Row {
            visible: root.stages.length > 0
            spacing: 6

            Repeater {
                model: root.stages

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool current: modelData.index === root.activeStage
                    width: chipText.implicitWidth + 16
                    height: 24
                    radius: 4
                    color: current ? Theme.accent : chipArea.containsMouse ? Theme.track : Theme.iconBg

                    BarText {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData.dpi
                        color: chip.current ? Theme.barBg : Theme.fg
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.setStage(chip.modelData.index)
                    }
                }
            }
        }

        Divider {}

        ActionRow { label: "Button mapping"; value: "󰌌"; onClicked: { Quickshell.execDetached(["input-remapper-gtk"]); popup.visible = false } }
        ActionRow { label: "Razer settings"; value: "󰒓"; onClicked: { Quickshell.execDetached(["razercommander"]); popup.visible = false } }
    }
}
