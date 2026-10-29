import QtQuick

Column {
    property string label
    property string value
    property color valueColor: Theme.fg

    width: 100
    spacing: 2

    BarText { text: parent.label; color: Theme.muted; font.pixelSize: 10 }
    BarText { text: parent.value; color: parent.valueColor; font.pixelSize: 12 }
}
