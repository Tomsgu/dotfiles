import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    property string mode: "default"

    visible: mode !== "default"

    Process {
        running: true
        command: ["swaymsg", "-m", "-t", "subscribe", "[\"mode\"]"]
        stdout: SplitParser {
            onRead: line => {
                try { root.mode = JSON.parse(line).change } catch (e) {}
            }
        }
    }

    BarText {
        text: " " + root.mode
        font.pixelSize: Theme.barFontSize
        color: Theme.yellow
    }
}
