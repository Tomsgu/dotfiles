import QtQuick

Item {
    property string label
    property string value
    signal clicked

    width: parent.width
    height: 26

    Rectangle { anchors.fill: parent; anchors.margins: -4; radius: 4; color: Theme.iconBg; visible: area.containsMouse }
    BarText { anchors.verticalCenter: parent.verticalCenter; text: parent.label }
    BarText { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; text: parent.value; color: Theme.accent }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
}
