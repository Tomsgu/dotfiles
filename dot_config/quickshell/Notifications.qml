import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    readonly property var service: NotificationService

    readonly property var groups: {
        const out = []
        const today = new Date(service.now.getFullYear(), service.now.getMonth(), service.now.getDate()).getTime()
        for (const entry of service.history) {
            const label = entry.time >= today ? "TODAY" : entry.time >= today - 86400000 ? "YESTERDAY" : "EARLIER"
            let group = out.find(g => g.label === label)
            if (!group) { group = { label, items: [] }; out.push(group) }
            group.items.push(entry)
        }
        return out
    }

    active: popup.visible

    IpcHandler {
        target: "notificationcenter"
        function toggle(): void { popup.toggle() }
    }

    Row {
        spacing: 5
        BarText {
            text: root.service.dnd ? "󰂛" : root.service.unread > 0 ? "󰂞" : "󰂚"
            color: root.service.dnd ? Theme.muted : root.service.unread > 0 ? Theme.accent : Theme.fg
            font.pixelSize: Theme.barFontSize
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }
        BarText {
            visible: root.service.unread > 0
            text: root.service.unread
            color: root.service.dnd ? Theme.muted : Theme.accent
            font.pixelSize: Theme.barFontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.service.toggleDnd()
            else if (mouse.button === Qt.MiddleButton) root.service.clear()
            else popup.toggle()
        }
    }

    component HeaderButton: BarText {
        signal clicked
        property bool on: false
        width: 26; height: 26
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 15
        color: on ? Theme.accent : area.containsMouse ? Theme.fg : Theme.muted
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 440
        onVisibleChanged: visible ? root.service.hideAllPopups() : root.service.markRead()

        Item {
            width: parent.width
            height: 28

            Row {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                BarText { text: "󰂚"; font.pixelSize: 18; width: 20; horizontalAlignment: Text.AlignHCenter }
                BarText { text: "Notifications"; font.pixelSize: 17; font.bold: true }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.service.unread > 0
                    radius: 4
                    color: Theme.iconBg
                    width: unreadLabel.implicitWidth + 12
                    height: 20
                    BarText { id: unreadLabel; anchors.centerIn: parent; text: root.service.unread + " new"; color: Theme.accent; font.pixelSize: 11 }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                HeaderButton { text: root.service.dnd ? "󰂛" : "󰂚"; on: root.service.dnd; onClicked: root.service.toggleDnd() }
                HeaderButton { text: "󰎟"; onClicked: root.service.clear() }
            }
        }

        BarText {
            visible: root.service.dnd
            text: "Do not disturb is on. Only critical notifications pop up."
            color: Theme.yellow
            font.pixelSize: 11
        }

        Divider {}

        Column {
            visible: root.service.history.length === 0
            width: parent.width
            topPadding: 24
            bottomPadding: 24
            spacing: 6
            BarText { anchors.horizontalCenter: parent.horizontalCenter; text: "󰂚"; font.pixelSize: 28; color: Theme.track }
            BarText { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; color: Theme.muted; font.pixelSize: 12 }
        }

        Flickable {
            visible: root.service.history.length > 0
            width: parent.width
            height: Math.min(list.implicitHeight, 640)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.groups
                    Column {
                        required property var modelData
                        width: parent.width
                        spacing: 2
                        SectionLabel { text: parent.modelData.label; topPadding: 6; bottomPadding: 4 }
                        Repeater {
                            model: parent.modelData.items
                            NotificationCard {
                                required property var modelData
                                entry: modelData
                                Rectangle {
                                    visible: !parent.entry.read
                                    x: 2
                                    y: 26
                                    width: 5; height: 5; radius: 2.5
                                    color: Theme.accent
                                }
                            }
                        }
                    }
                }
            }
        }

        Divider {}

        BarText {
            text: "Click opens  ·  right click dismisses"
            color: Theme.muted
            font.pixelSize: 10
        }
    }
}
