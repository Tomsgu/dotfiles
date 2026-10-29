import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    property SystemTrayItem current: null
    property Item currentSlot: null

    visible: SystemTray.items.values.length > 0
    implicitWidth: row.width
    implicitHeight: parent ? parent.height : Theme.barHeight

    function openMenu(item, slot) {
        if (popup.visible && current === item) {
            popup.visible = false
            return
        }
        current = item
        currentSlot = slot
        popup.visible = true
    }

    IpcHandler {
        target: "tray"
        function menu(id: string): void {
            const slots = row.children
            for (let i = 0; i < slots.length; i++) {
                const slot = slots[i]
                if (slot.modelData && slot.modelData.id.toLowerCase().includes(id.toLowerCase())) root.openMenu(slot.modelData, slot)
            }
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 0

        Repeater {
            model: SystemTray.items

            BarItem {
                id: slot
                required property SystemTrayItem modelData
                readonly property string tip: modelData.tooltipTitle !== "" ? modelData.tooltipTitle : modelData.title
                active: popup.visible && root.current === modelData

                IconImage {
                    source: slot.modelData.icon
                    implicitSize: 16
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            slot.modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton || slot.modelData.onlyMenu) {
                            if (slot.modelData.hasMenu) root.openMenu(slot.modelData, slot)
                        } else {
                            slot.modelData.activate()
                        }
                    }
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y !== 0) slot.modelData.scroll(wheel.angleDelta.y / 120, false)
                        if (wheel.angleDelta.x !== 0) slot.modelData.scroll(wheel.angleDelta.x / 120, true)
                    }
                }

                Tooltip {
                    anchor.item: slot
                    visible: hover.containsMouse && !popup.visible && slot.tip !== ""
                    text: slot.tip
                }
            }
        }
    }

    BarPopup {
        id: popup
        anchorItem: root.currentSlot ? root.currentSlot : root
        cardWidth: 280

        PopupHeader {
            icon: ""
            iconSource: root.current ? root.current.icon : ""
            title: root.current ? (root.current.tooltipTitle !== "" ? root.current.tooltipTitle : root.current.title !== "" ? root.current.title : root.current.id) : ""
            subtitle: root.current ? root.current.tooltipDescription : ""
        }

        Divider {}

        TrayMenu {
            menu: root.current ? root.current.menu : null
            onActivated: popup.visible = false
        }
    }
}
