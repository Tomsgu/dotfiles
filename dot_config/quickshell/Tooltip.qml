import Quickshell
import QtQuick

PopupWindow {
    id: tip
    required property string text

    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    implicitWidth: box.width
    implicitHeight: box.height + box.y
    color: "transparent"

    Rectangle {
        id: box
        y: 4
        width: label.implicitWidth + 20
        height: label.implicitHeight + 12
        radius: 4
        color: Theme.cardBg
        border.width: 1
        border.color: Theme.accent

        BarText {
            id: label
            anchors.centerIn: parent
            text: tip.text
        }
    }
}
