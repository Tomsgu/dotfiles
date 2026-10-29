import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Rectangle {
    id: card
    required property var entry
    property bool toast: false
    readonly property bool hovered: hover.hovered
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property var actions: { NotificationService.live; return NotificationService.actionsFor(entry.key) }
    readonly property string picture: { NotificationService.live; return NotificationService.pictureFor(entry) }
    readonly property bool isPhoto: picture !== "" && !picture.startsWith("image://icon/") && !picture.endsWith(".svg")
    readonly property var glyphs: ({ "Mail": "󰇮", "GitHub": "󰊤", "notify-send": "󰂚" })

    width: parent ? parent.width : 380
    height: content.implicitHeight + (toast ? 28 : 20)
    radius: 8
    color: toast ? Theme.cardBg : hover.hovered ? Theme.iconBg : "transparent"
    border.width: toast ? 2 : 0
    border.color: critical ? Theme.red : Theme.accent

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: NotificationService.canActivate(card.entry) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) NotificationService.activate(card.entry)
            else if (mouse.button === Qt.RightButton && card.toast) NotificationService.hidePopup(card.entry.key)
            else NotificationService.dismiss(card.entry.key)
        }
    }

    Rectangle {
        id: avatar
        x: card.toast ? 14 : 10
        y: card.toast ? 14 : 10
        width: 36; height: 36; radius: 6
        color: Theme.iconBg
        clip: true

        Image {
            id: pic
            anchors.fill: parent
            anchors.margins: card.isPhoto ? 0 : 6
            source: card.picture
            sourceSize: Qt.size(72, 72)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        BarText {
            anchors.centerIn: parent
            visible: pic.status !== Image.Ready
            text: card.glyphs[card.entry.app] || card.entry.app.slice(0, 2).toUpperCase()
            font.bold: true
            font.pixelSize: card.glyphs[card.entry.app] ? 18 : 12
            color: card.critical ? Theme.red : Theme.fg
        }
    }

    Column {
        id: content
        x: avatar.x + avatar.width + 12
        y: avatar.y - 1
        width: card.width - x - (card.toast ? 14 : 10)
        spacing: 4

        Item {
            width: parent.width
            height: 14
            BarText {
                width: parent.width - when.implicitWidth - close.width - 12
                text: card.entry.app
                color: card.critical ? Theme.red : Theme.muted
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            BarText {
                id: when
                anchors.right: close.left
                anchors.rightMargin: 6
                text: NotificationService.ago(card.entry.time)
                color: Theme.muted
                font.pixelSize: 10
            }
            BarText {
                id: close
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                horizontalAlignment: Text.AlignHCenter
                text: "󰅖"
                font.pixelSize: 12
                opacity: card.hovered ? 1 : 0
                color: closeArea.containsMouse ? Theme.red : Theme.muted
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    onClicked: NotificationService.dismiss(card.entry.key)
                }
            }
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: card.entry.summary
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        BarText {
            width: parent.width
            visible: text !== ""
            text: card.entry.body.replace(/\n/g, "<br>")
            textFormat: Text.StyledText
            color: Theme.fg
            opacity: 0.85
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: card.toast ? 5 : 3
            elide: Text.ElideRight
            lineHeight: 1.1
        }

        Flow {
            width: parent.width
            visible: card.actions.length > 0
            spacing: 6
            topPadding: 4

            Repeater {
                model: card.actions
                Rectangle {
                    required property var modelData
                    width: label.implicitWidth + 16
                    height: 24
                    radius: 5
                    color: actionArea.containsMouse ? Theme.accent : Theme.iconBg
                    BarText {
                        id: label
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        font.pixelSize: 11
                        color: actionArea.containsMouse ? Theme.barBg : Theme.fg
                    }
                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: NotificationService.invoke(card.entry.key, parent.modelData)
                    }
                }
            }
        }
    }
}
