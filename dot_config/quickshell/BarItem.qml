import QtQuick

Item {
    id: root
    property bool active: false
    default property alias content: slot.data

    implicitWidth: slot.childrenRect.width + 12
    implicitHeight: parent ? parent.height : Theme.barHeight

    Component.onCompleted: {
        for (const child of slot.children.slice()) {
            if (child instanceof MouseArea) child.parent = root
        }
    }

    Item {
        id: slot
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        visible: parent.active
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 2
        color: Theme.accent
    }
}
