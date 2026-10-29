import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-sysinfo"
    property var info: null

    function gib(bytes) { return (bytes / 1073741824).toFixed(1) + " GiB" }
    function rate(bytesPerSecond) {
        if (bytesPerSecond >= 1048576) return (bytesPerSecond / 1048576).toFixed(1) + " MB/s"
        if (bytesPerSecond >= 1024) return Math.round(bytesPerSecond / 1024) + " kB/s"
        return bytesPerSecond + " B/s"
    }
    function uptime(seconds) {
        const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60)
        return (d > 0 ? d + "d " : "") + h + "h " + m + "m"
    }
    function tempColor(value, high) {
        const limit = high || 90
        return value >= limit * 0.9 ? Theme.red : value >= limit * 0.75 ? Theme.yellow : Theme.fg
    }

    active: popup.visible

    Process {
        id: fetch
        running: true
        command: [root.helper]
        stdout: StdioCollector { onStreamFinished: { try { root.info = JSON.parse(text) } catch (e) {} } }
    }

    Timer {
        interval: popup.visible ? 2000 : 5000
        running: true
        repeat: true
        onTriggered: fetch.running = true
    }

    IpcHandler {
        target: "system"
        function toggle(): void { popup.toggle() }
    }

    Row {
        spacing: 10
        Row {
            spacing: 5
            BarText { text: "󰻠"; color: Theme.muted; font.pixelSize: Theme.barFontSize; width: 16; horizontalAlignment: Text.AlignHCenter }
            BarText { text: root.info ? root.info.cpu.usage + "%" : "--"; font.pixelSize: Theme.barFontSize; color: root.info && root.info.cpu.usage >= 90 ? Theme.red : Theme.fg }
        }
        Row {
            spacing: 5
            BarText { text: "󰍛"; color: Theme.muted; font.pixelSize: Theme.barFontSize; width: 16; horizontalAlignment: Text.AlignHCenter }
            BarText { text: root.info ? root.info.memory.percent + "%" : "--"; font.pixelSize: Theme.barFontSize; color: root.info && root.info.memory.percent >= 90 ? Theme.red : Theme.fg }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.toggle()
    }

    component Meter: Column {
        property string label
        property string value
        property int pct
        width: parent.width
        spacing: 5
        Item {
            width: parent.width
            height: 15
            BarText { text: parent.parent.label; color: Theme.muted; font.pixelSize: 12 }
            BarText { anchors.right: parent.right; text: parent.parent.value; font.pixelSize: 12 }
        }
        UsageBar { pct: parent.pct }
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 460
        onVisibleChanged: if (visible) fetch.running = true

        PopupHeader {
            icon: "󰻠"
            iconColor: Theme.accent
            title: root.info ? root.info.cpu.model : "System"
            subtitle: root.info ? "Up " + root.uptime(root.info.uptime) + "  ·  load " + root.info.cpu.load.map(l => l.toFixed(2)).join(" ") : ""
        }

        BarText { visible: root.info === null; text: "Collecting…"; color: Theme.muted }

        Item { width: 1; height: 4 }
        SectionLabel { visible: root.info !== null; text: "CPU" }

        Meter { visible: root.info !== null; label: "Usage"; value: root.info ? root.info.cpu.usage + "%  ·  " + root.info.cpu.freq + " MHz" : ""; pct: root.info ? root.info.cpu.usage : 0 }

        Row {
            visible: root.info !== null
            width: parent.width
            height: 22
            spacing: 3
            Repeater {
                model: root.info ? root.info.cpu.cores : []
                Item {
                    required property int modelData
                    width: (parent.width - 3 * 15) / 16
                    height: 22
                    Rectangle { anchors.fill: parent; radius: 2; color: Theme.track }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Math.max(2, parent.height * parent.modelData / 100)
                        radius: 2
                        color: parent.modelData >= 90 ? Theme.red : parent.modelData >= 60 ? Theme.yellow : Theme.green
                    }
                }
            }
        }

        SectionLabel { visible: root.info !== null; text: "MEMORY" }
        Meter { visible: root.info !== null; label: "RAM"; value: root.info ? root.gib(root.info.memory.used) + " / " + root.gib(root.info.memory.total) : ""; pct: root.info ? root.info.memory.percent : 0 }
        Meter {
            visible: root.info !== null && root.info.memory.swap_total > 0
            label: "Swap"
            value: root.info ? root.gib(root.info.memory.swap_used) + " / " + root.gib(root.info.memory.swap_total) : ""
            pct: root.info && root.info.memory.swap_total > 0 ? Math.round(100 * root.info.memory.swap_used / root.info.memory.swap_total) : 0
        }

        SectionLabel { visible: root.info !== null && root.info.gpu.busy !== undefined; text: "GPU" }
        Meter { visible: root.info !== null && root.info.gpu.busy !== undefined; label: "Usage"; value: root.info ? root.info.gpu.busy + "%  ·  " + (root.info.gpu.sclk || 0) + " MHz" : ""; pct: root.info ? root.info.gpu.busy || 0 : 0 }
        Meter {
            visible: root.info !== null && root.info.gpu.vram_total !== undefined
            label: "VRAM"
            value: root.info ? root.gib(root.info.gpu.vram_used) + " / " + root.gib(root.info.gpu.vram_total) : ""
            pct: root.info && root.info.gpu.vram_total ? Math.round(100 * root.info.gpu.vram_used / root.info.gpu.vram_total) : 0
        }
        Row {
            visible: root.info !== null && root.info.gpu.busy !== undefined
            spacing: 12
            Stat { label: "POWER"; value: root.info ? (root.info.gpu.power || 0) + " W" : "" }
            Stat { label: "FAN"; value: root.info ? (root.info.gpu.fan || 0) + " rpm" : "" }
            Stat { label: "MEMORY CLOCK"; value: root.info ? (root.info.gpu.mclk || 0) + " MHz" : "" }
        }

        SectionLabel { visible: root.info !== null; text: "TEMPERATURES" }
        Grid {
            visible: root.info !== null
            width: parent.width
            columns: 4
            columnSpacing: 12
            rowSpacing: 8
            Repeater {
                model: root.info ? root.info.temps : []
                Stat {
                    required property var modelData
                    label: modelData.label.toUpperCase()
                    value: modelData.value + "°C"
                    valueColor: root.tempColor(modelData.value, modelData.high)
                }
            }
        }

        SectionLabel { visible: root.info !== null && root.info.fans.length > 0; text: "FANS" }
        Row {
            visible: root.info !== null && root.info.fans.length > 0
            spacing: 12
            Repeater {
                model: root.info ? root.info.fans : []
                Stat {
                    required property var modelData
                    label: modelData.label.toUpperCase()
                    value: modelData.rpm + " rpm"
                }
            }
        }

        SectionLabel { visible: root.info !== null; text: "STORAGE" }
        Repeater {
            model: root.info ? root.info.disks : []
            Meter {
                required property var modelData
                label: modelData.mount
                value: root.gib(modelData.used) + " / " + root.gib(modelData.total)
                pct: modelData.percent
            }
        }

        SectionLabel { visible: root.info !== null; text: "NETWORK" }
        Column {
            visible: root.info !== null
            width: parent.width
            spacing: 8
            Repeater {
                model: root.info ? root.info.network : []
                Row {
                    required property var modelData
                    spacing: 12
                    Stat { label: parent.modelData.iface.toUpperCase(); value: parent.modelData.up ? "up" : "down"; valueColor: parent.modelData.up ? Theme.green : Theme.muted; width: 110 }
                    Stat { label: "󰇚 DOWN"; value: root.rate(parent.modelData.rx); width: 110 }
                    Stat { label: "󰕒 UP"; value: root.rate(parent.modelData.tx); width: 110 }
                }
            }
        }

        Divider {}

        Item {
            width: parent.width
            height: 16
            BarText {
                readonly property int failed: root.info ? root.info.failed.system.length + root.info.failed.user.length : 0
                text: failed === 0 ? "✓ All systemd units healthy" : "✗ " + failed + " failed: " + (root.info ? root.info.failed.system.concat(root.info.failed.user).join(", ") : "")
                color: failed === 0 ? Theme.green : Theme.red
                font.pixelSize: 11
                width: parent.width
                elide: Text.ElideRight
            }
        }
    }
}
