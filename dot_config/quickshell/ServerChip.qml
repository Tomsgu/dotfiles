import QtQuick

Rectangle {
    property string text
    property color textColor: Theme.fg

    width: chipText.implicitWidth + 12
    height: 18
    radius: 4
    color: Theme.iconBg

    BarText {
        id: chipText
        anchors.centerIn: parent
        text: parent.text
        color: parent.textColor
        font.pixelSize: 10
    }
}
