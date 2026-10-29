import Quickshell
import QtQuick

Column {
    id: root
    required property var menu
    property int depth: 0
    signal activated()

    width: parent.width
    spacing: 2

    QsMenuOpener {
        id: opener
        menu: root.menu
    }

    Repeater {
        model: opener.children

        Item {
            id: entry
            required property QsMenuEntry modelData
            property bool expanded: false

            readonly property bool checkable: modelData.buttonType !== QsMenuButtonType.None
            readonly property bool checked: modelData.checkState === Qt.Checked
            readonly property string mark: !checkable ? "" : modelData.buttonType === QsMenuButtonType.RadioButton ? (checked ? "󰐾" : "󰄰") : (checked ? "󰄲" : "󰄱")

            width: parent.width
            height: modelData.isSeparator ? 9 : rowRect.height + (expanded ? sub.height + 2 : 0)

            Divider {
                visible: entry.modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: rowRect
                visible: !entry.modelData.isSeparator
                width: parent.width
                height: 30
                radius: 5
                color: hover.hovered && entry.modelData.enabled ? Theme.iconBg : "transparent"
                opacity: entry.modelData.enabled ? 1 : 0.4

                Row {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8 + root.depth * 14; rightMargin: 8 }
                    spacing: 8

                    BarText {
                        visible: entry.checkable
                        text: entry.mark
                        width: 16
                        color: entry.checked ? Theme.accent : Theme.muted
                    }

                    Image {
                        visible: entry.modelData.icon !== ""
                        source: entry.modelData.icon
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    BarText {
                        text: entry.modelData.text
                        elide: Text.ElideRight
                        width: parent.width - (entry.checkable ? 24 : 0) - (entry.modelData.icon !== "" ? 24 : 0) - (entry.modelData.hasChildren ? 24 : 0)
                    }

                    BarText {
                        visible: entry.modelData.hasChildren
                        text: entry.expanded ? "󰅀" : "󰅂"
                        width: 16
                        color: Theme.muted
                    }
                }

                HoverHandler { id: hover }

                MouseArea {
                    anchors.fill: parent
                    enabled: entry.modelData.enabled
                    onClicked: {
                        if (entry.modelData.hasChildren) {
                            entry.expanded = !entry.expanded
                            return
                        }
                        entry.modelData.triggered()
                        root.activated()
                    }
                }
            }

            Loader {
                id: sub
                active: entry.expanded
                anchors { top: rowRect.bottom; topMargin: 2; left: parent.left; right: parent.right }
                height: item ? item.height : 0
                Component.onCompleted: setSource("TrayMenu.qml", { menu: entry.modelData, depth: root.depth + 1 })
                onLoaded: item.activated.connect(root.activated)
            }
        }
    }
}
