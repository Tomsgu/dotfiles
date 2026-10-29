pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color barBg: "#0b0c14"
    readonly property color cardBg: "#1b1d2b"
    readonly property color iconBg: "#2a2c3f"
    readonly property color fg: "#c8ccd8"
    readonly property color muted: "#6e7389"
    readonly property color track: "#313244"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color red: "#f38ba8"
    readonly property color accent: "#5b7cfa"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int barFontSize: 14
    readonly property int barHeight: 30

    function levelColor(pct) {
        return pct >= 80 ? red : pct >= 60 ? peach : pct >= 30 ? yellow : green
    }
}
