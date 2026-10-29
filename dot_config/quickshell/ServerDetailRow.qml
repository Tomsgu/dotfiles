import QtQuick

Row {
    property string label
    property int labelWidth: 68
    default property alias content: valueFlow.data

    spacing: 8

    BarText {
        width: labelWidth
        text: label
        color: Theme.muted
        font.pixelSize: 11
        anchors.top: parent.top
        topPadding: 2
    }

    Flow {
        id: valueFlow
        width: parent.width - labelWidth - 8
        spacing: 4
    }
}
