import QtQuick

Row {
    property string icon
    property string iconSource: ""
    property color iconColor: Theme.peach
    property string title
    property string subtitle

    spacing: 12

    Rectangle {
        width: 40
        height: 40
        radius: 20
        color: Theme.iconBg
        Text { anchors.centerIn: parent; visible: iconSource === ""; text: icon; color: iconColor; font.family: Theme.mono; font.pixelSize: 22 }
        Image { anchors.centerIn: parent; visible: iconSource !== ""; source: iconSource; width: 22; height: 22; sourceSize: Qt.size(22, 22) }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        BarText { text: title; font.pixelSize: 15; font.bold: true }
        BarText { text: subtitle; font.pixelSize: 10; color: Theme.muted }
    }
}
