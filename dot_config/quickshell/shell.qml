import Quickshell
import Quickshell.I3
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    NotificationPopups {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: Theme.barHeight
            color: Theme.barBg

            Row {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 14 }
                spacing: 12

                Repeater {
                    model: I3.workspaces

                    BarItem {
                        id: ws
                        required property I3Workspace modelData
                        active: modelData.focused

                        BarText {
                            text: ws.modelData.name
                            font.pixelSize: Theme.barFontSize
                            color: ws.modelData.focused ? Theme.fg : ws.modelData.urgent ? Theme.red : Theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: ws.modelData.activate()
                        }
                    }
                }

                Item { width: 8; height: 1 }
                Mode {}
                Weather {}
            }

            BarItem {
                id: titleItem
                anchors.centerIn: parent
                height: parent.height

                BarText {
                    id: titleText
                    readonly property Toplevel window: ToplevelManager.activeToplevel
                    readonly property string title: window ? window.title : ""
                    readonly property bool truncated: title.length > 40
                    text: truncated ? title.slice(0, 19) + "…" + title.slice(-20) : title
                    font.pixelSize: Theme.barFontSize
                }

                HoverHandler { id: titleHover }

                Tooltip {
                    anchor.item: titleItem
                    visible: titleHover.hovered && titleText.truncated
                    text: titleText.title
                }
            }

            Row {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 10 }
                spacing: 8

                ClaudeUsage { now: clock.date }

                Mail {}

                Servers { now: clock.date }

                System {}

                Audio {}

                Mouse {}

                Gammastep {}

                BarItem {
                    id: batteryItem
                    readonly property UPowerDevice battery: UPower.displayDevice
                    visible: battery.isLaptopBattery

                    BarText {
                        font.pixelSize: Theme.barFontSize
                        readonly property UPowerDevice battery: batteryItem.battery
                        readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged
                        color: battery.percentage < 0.15 && UPower.onBattery ? Theme.red : Theme.fg
                        text: (charging ? "bat+ " : "bat ") + Math.round(battery.percentage * 100) + "%"
                    }
                }

                Screenshot {}

                Notifications {}

                Calendar { now: clock.date }

                Tray {}
            }
        }
    }
}
