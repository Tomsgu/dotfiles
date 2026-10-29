import QtQuick

Column {
    property string label
    property int pct
    property string detail

    spacing: 3

    Item {
        width: parent.width
        height: 14
        BarText { text: label; font.pixelSize: 11; color: Theme.fg }
        BarText { anchors.right: parent.right; text: detail; font.pixelSize: 11; color: Theme.muted }
    }

    UsageBar { pct: parent.pct }
}
