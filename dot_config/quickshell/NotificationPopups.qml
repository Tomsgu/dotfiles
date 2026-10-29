import Quickshell
import Quickshell.I3
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    readonly property int maxVisible: 4

    screen: {
        const name = I3.focusedMonitor ? I3.focusedMonitor.name : ""
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name) return screens[i]
        return screens.length > 0 ? screens[0] : null
    }

    anchors { top: true; right: true }
    margins { top: 8; right: 10 }
    implicitWidth: 400
    implicitHeight: Math.max(1, stack.implicitHeight)
    visible: NotificationService.popups.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-notifications"

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: ScriptModel {
                values: NotificationService.popups.slice(0, root.maxVisible)
                objectProp: "key"
            }

            NotificationCard {
                id: toast
                required property var modelData
                entry: modelData
                toast: true
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Timer {
                    interval: toast.entry.timeout
                    running: toast.entry.timeout > 0 && !toast.hovered
                    onTriggered: NotificationService.hidePopup(toast.entry.key)
                }
            }
        }

        BarText {
            visible: NotificationService.popups.length > root.maxVisible
            anchors.right: parent.right
            text: "+" + (NotificationService.popups.length - root.maxVisible) + " more"
            color: Theme.muted
            font.pixelSize: 11
        }
    }
}
