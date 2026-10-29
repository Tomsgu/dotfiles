import QtQuick

Item {
    required property int pct
    property int marker: -1
    property color fillColor: "transparent"

    width: parent.width
    height: 6

    Rectangle { anchors.fill: parent; radius: 3; color: Theme.track }

    Item {
        width: parent.width * Math.min(pct, 100) / 100
        height: parent.height
        clip: true

        Rectangle {
            width: parent.parent.width
            height: parent.height
            radius: 3
            color: fillColor
            gradient: fillColor.a > 0 ? null : barGradient
        }
    }

    Gradient {
        id: barGradient
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Theme.green }
        GradientStop { position: 0.5; color: Theme.yellow }
        GradientStop { position: 1.0; color: Theme.red }
    }

    Rectangle {
        visible: marker >= 0
        x: parent.width * marker / 100 - 1
        y: -2
        width: 2
        height: parent.height + 4
        color: Theme.fg
    }
}
