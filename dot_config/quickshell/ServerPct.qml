import QtQuick

Row {
    property string label
    property int pct

    spacing: 4

    BarText { text: label; color: Theme.muted; font.pixelSize: 11 }
    BarText { text: pct + "%"; color: Theme.levelColor(pct); font.pixelSize: 11; font.bold: true }
}
