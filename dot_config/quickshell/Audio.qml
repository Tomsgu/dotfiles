import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick

BarItem {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio !== null)
    readonly property var outputs: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var playback: nodes.filter(n => n.isStream && !n.isSink)
    readonly property var recording: nodes.filter(n => n.isStream && n.isSink)

    function kind(node) {
        if (!node) return "mic"
        const props = node.properties
        const ff = props["device.form-factor"] || ""
        if (props["device.api"] === "bluez5" || ff === "headset" || ff === "headphone") return "headphones"
        if (ff === "webcam" || ff === "microphone") return "mic"
        if ((node.description || "").includes("HDMI")) return "monitor"
        return node.isSink ? "speaker" : "mic"
    }

    function icon(node) {
        const k = kind(node)
        return k === "headphones" ? "󰋋" : k === "monitor" ? "󰍹" : k === "mic" ? "󰍬" : "󰕾"
    }

    function pct(node) { return node && node.audio ? Math.round(node.audio.volume * 100) : 0 }

    readonly property bool airpodsMicOffered: AirPodsService.cardId >= 0 && AirPodsService.headsetIndex >= 0 && !AirPodsService.micOn
    property bool wantAirPodsMic: false

    function useAirPodsMic() {
        wantAirPodsMic = true
        AirPodsService.toggleMic()
    }

    onInputsChanged: {
        if (!wantAirPodsMic) return
        const mic = inputs.find(n => n.properties["device.api"] === "bluez5")
        if (mic) { Pipewire.preferredDefaultAudioSource = mic; wantAirPodsMic = false }
    }

    function label(node) {
        if (node.isStream) return (node.properties["application.name"] || node.name) + (node.properties["media.name"] ? " · " + node.properties["media.name"] : "")
        return node.nickname || node.description || node.name
    }

    active: popup.visible

    PwObjectTracker { objects: Pipewire.nodes.values }

    IpcHandler {
        target: "audio"
        function toggle(): void { popup.toggle() }
        function mute(): void { if (root.sink) root.sink.audio.muted = !root.sink.audio.muted }
    }

    Row {
        spacing: 5
        BarText {
            text: !root.sink ? "󰖁" : root.sink.audio.muted ? "󰖁" : root.icon(root.sink)
            color: root.sink && !root.sink.audio.muted ? Theme.fg : Theme.muted
            font.pixelSize: Theme.barFontSize
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }
        BarText {
            text: root.sink ? root.pct(root.sink) + "%" : "--"
            font.pixelSize: Theme.barFontSize
            color: root.sink && root.sink.audio.muted ? Theme.muted : Theme.fg
        }
        BarText {
            visible: AirPodsService.linked && AirPodsService.lowestLevel >= 0
            text: "󰂯 " + AirPodsService.lowestLevel + "%"
            font.pixelSize: Theme.barFontSize
            color: AirPodsService.lowestLevel <= 20 ? Theme.red : Theme.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { if (root.sink) root.sink.audio.muted = !root.sink.audio.muted }
            else popup.toggle()
        }
        onWheel: wheel => {
            if (!root.sink) return
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
        }
    }

    component VolumeRow: Item {
        id: vrow
        required property PwNode node
        property bool selectable: false
        property bool isDefault: false
        signal choose

        width: parent.width
        height: 44

        Rectangle { anchors.fill: parent; anchors.margins: -4; radius: 6; color: Theme.iconBg; visible: hover.containsMouse }

        BarText {
            id: dot
            visible: vrow.selectable
            x: 2
            anchors.verticalCenter: parent.verticalCenter
            text: vrow.isDefault ? "󰄴" : "󰄰"
            color: vrow.isDefault ? Theme.accent : Theme.muted
            width: 18
            horizontalAlignment: Text.AlignHCenter
        }

        BarText {
            id: nodeIcon
            x: vrow.selectable ? 24 : 2
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon(vrow.node)
            width: 20
            horizontalAlignment: Text.AlignHCenter
            color: Theme.muted
        }

        Column {
            x: nodeIcon.x + 28
            width: parent.width - x - 70
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            BarText {
                width: parent.width
                text: root.label(vrow.node)
                font.pixelSize: 12
                color: vrow.isDefault || !vrow.selectable ? Theme.fg : Theme.muted
                elide: Text.ElideRight
            }

            Item {
                width: parent.width
                height: 8

                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.track }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, vrow.node.audio.volume)
                    height: 4
                    radius: 2
                    color: vrow.node.audio.muted ? Theme.muted : Theme.accent
                }
                Rectangle {
                    x: parent.width * Math.min(1, vrow.node.audio.volume) - 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10; height: 10; radius: 5
                    color: Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    onPressed: mouse => vrow.node.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                    onPositionChanged: mouse => { if (pressed) vrow.node.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                    onWheel: wheel => vrow.node.audio.volume = Math.max(0, Math.min(1, vrow.node.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
                }
            }
        }

        BarText {
            anchors.right: muteBtn.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.pct(vrow.node) + "%"
            font.pixelSize: 12
            color: vrow.node.audio.muted ? Theme.muted : Theme.fg
        }

        BarText {
            id: muteBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            horizontalAlignment: Text.AlignHCenter
            text: vrow.node.audio.muted ? "󰖁" : "󰕾"
            color: vrow.node.audio.muted ? Theme.red : Theme.muted
            MouseArea { anchors.fill: parent; onClicked: vrow.node.audio.muted = !vrow.node.audio.muted }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onClicked: mouse => { if (vrow.selectable && mouse.x < nodeIcon.x + 28) vrow.choose(); else mouse.accepted = false }
            onPressed: mouse => mouse.accepted = vrow.selectable && mouse.x < nodeIcon.x + 28
        }
    }

    component ClickRow: Item {
        property string label
        property string value
        property bool selected: false
        signal clicked
        width: parent.width
        height: 26
        Rectangle { anchors.fill: parent; anchors.margins: -4; radius: 4; color: Theme.iconBg; visible: rowArea.containsMouse }
        BarText { anchors.verticalCenter: parent.verticalCenter; text: parent.label; color: parent.selected ? Theme.fg : Theme.muted }
        BarText { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; text: parent.value; color: parent.selected ? Theme.accent : Theme.muted }
        MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 460
        onVisibleChanged: if (visible) AirPodsService.refreshProfile()

        PopupHeader {
            icon: root.sink ? root.icon(root.sink) : "󰕾"
            iconColor: Theme.accent
            title: root.sink ? root.label(root.sink) : "No output"
            subtitle: root.sink ? root.pct(root.sink) + "%" + (root.sink.audio.muted ? " · muted" : "") + (root.source ? "  ·  mic: " + root.label(root.source) : "") : ""
        }

        Item { width: 1; height: 4 }
        SectionLabel { text: "OUTPUT" }
        Repeater {
            model: root.outputs
            VolumeRow { required property PwNode modelData; node: modelData; selectable: true; isDefault: root.sink === modelData; onChoose: Pipewire.preferredDefaultAudioSink = modelData }
        }

        SectionLabel { visible: root.inputs.length > 0 || root.airpodsMicOffered; text: "INPUT" }
        Repeater {
            model: root.inputs
            VolumeRow { required property PwNode modelData; node: modelData; selectable: true; isDefault: root.source === modelData; onChoose: Pipewire.preferredDefaultAudioSource = modelData }
        }

        Item {
            visible: root.airpodsMicOffered
            width: parent.width
            height: 32
            Rectangle { anchors.fill: parent; anchors.margins: -4; radius: 6; color: Theme.iconBg; visible: stubArea.containsMouse }
            BarText { x: 2; anchors.verticalCenter: parent.verticalCenter; text: "󰄰"; color: Theme.muted; width: 18; horizontalAlignment: Text.AlignHCenter }
            BarText { x: 24; anchors.verticalCenter: parent.verticalCenter; text: "󰋋"; color: Theme.muted; width: 20; horizontalAlignment: Text.AlignHCenter }
            Column {
                x: 52
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                BarText { text: AirPodsService.title + " microphone"; font.pixelSize: 12; color: Theme.muted }
                BarText { text: "Switches the AirPods to headset mode (mono)"; font.pixelSize: 10; color: Theme.muted }
            }
            MouseArea { id: stubArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.useAirPodsMic() }
        }

        SectionLabel { visible: root.playback.length > 0; text: "PLAYBACK" }
        Repeater {
            model: root.playback
            VolumeRow { required property PwNode modelData; node: modelData }
        }

        SectionLabel { visible: root.recording.length > 0; text: "RECORDING" }
        Repeater {
            model: root.recording
            VolumeRow { required property PwNode modelData; node: modelData }
        }

        Divider { visible: AirPodsService.paired || AirPodsService.daemonRunning }

        Item {
            visible: AirPodsService.paired || AirPodsService.daemonRunning
            width: parent.width
            height: 18
            SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "AIRPODS" }
            BarText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11
                text: !AirPodsService.daemonRunning ? "daemon not running"
                    : AirPodsService.busy ? (AirPodsService.linked ? "Disconnecting…" : "Connecting…")
                    : AirPodsService.paired ? (AirPodsService.linked ? "Disconnect" : "Connect") : "not paired"
                color: AirPodsService.paired && !AirPodsService.busy ? (linkArea.containsMouse ? Theme.fg : Theme.accent) : Theme.muted
                MouseArea { id: linkArea; anchors.fill: parent; hoverEnabled: true; onClicked: AirPodsService.toggleConnection() }
            }
        }

        SectionLabel { visible: AirPodsService.pods.length > 0; text: "BATTERY" }

        Repeater {
            model: AirPodsService.pods

            Column {
                required property var modelData
                width: parent.width
                spacing: 6

                Item {
                    width: parent.width
                    height: 16
                    BarText { text: parent.parent.modelData.name; color: Theme.accent }
                    BarText {
                        anchors.right: parent.right
                        text: parent.parent.modelData.part.level >= 0 ? parent.parent.modelData.part.level + "%" : "--"
                        color: AirPodsService.batteryColor(parent.parent.modelData.part)
                        font.bold: true
                    }
                }

                UsageBar { pct: Math.max(0, parent.modelData.part.level); fillColor: AirPodsService.batteryColor(parent.modelData.part) }

                BarText { text: AirPodsService.podMeta(parent.modelData); color: Theme.muted; font.pixelSize: 11; visible: text !== "" }
                Item { width: 1; height: 4 }
            }
        }

        Divider { visible: AirPodsService.modes.length > 0 }
        SectionLabel { visible: AirPodsService.modes.length > 0; text: "LISTENING MODE" }

        Repeater {
            model: AirPodsService.modes
            ClickRow {
                required property var modelData
                label: modelData.name
                selected: AirPodsService.status.noise_mode === modelData.id
                value: selected ? "󰄬" : ""
                onClicked: AirPodsService.send(modelData.verb)
            }
        }

        Divider { visible: AirPodsService.connected }

        ClickRow {
            visible: AirPodsService.cardId >= 0 && AirPodsService.headsetIndex >= 0
            label: "AirPods microphone"
            selected: AirPodsService.micOn
            value: AirPodsService.micOn ? "on" : "off"
            onClicked: AirPodsService.toggleMic()
        }

        ClickRow {
            visible: AirPodsService.connected && AirPodsService.status.supports_conversational_awareness
            label: "Conversation awareness"
            selected: AirPodsService.connected && AirPodsService.status.conversational_awareness
            value: selected ? "on" : "off"
            onClicked: AirPodsService.send(selected ? "ca:off" : "ca:on")
        }

        ClickRow {
            visible: AirPodsService.connected
            label: "Ear detection"
            selected: true
            value: !AirPodsService.connected ? "" : AirPodsService.status.ear_detection_behavior === 0 ? "Pause when one is out" : AirPodsService.status.ear_detection_behavior === 1 ? "Pause when both are out" : "Never pause"
            onClicked: AirPodsService.send(AirPodsService.status.ear_detection_behavior === 0 ? "ear:both" : AirPodsService.status.ear_detection_behavior === 1 ? "ear:off" : "ear:one")
        }
    }
}
