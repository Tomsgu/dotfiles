import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: popup
    required property Item anchorItem
    property int cardWidth: 360
    property bool wantsKeyboard: false
    default property alias content: column.data

    WlrLayershell.keyboardFocus: wantsKeyboard && visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    screen: anchorItem.QsWindow.window ? anchorItem.QsWindow.window.screen : null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    function toggle() {
        visible = !visible
    }

    onVisibleChanged: if (visible) placeCard()

    function placeCard() {
        const bar = anchorItem.QsWindow.window
        const origin = anchorItem.mapToItem(null, 0, 0)
        const centered = origin.x + anchorItem.width / 2 - card.width / 2
        card.x = Math.max(10, Math.min(centered, bar.width - card.width - 10))
        card.y = bar.height + 6
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.visible = false
    }

    Rectangle {
        id: card
        width: popup.cardWidth
        height: column.implicitHeight + 36
        radius: 8
        color: Theme.cardBg
        border.width: 2
        border.color: Theme.accent

        MouseArea { anchors.fill: parent }

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 10
        }
    }
}
