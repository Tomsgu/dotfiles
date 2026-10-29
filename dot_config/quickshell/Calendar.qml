import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    required property date now
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-calendar"

    property var data: null
    property date updatedAt: new Date()
    property bool loading: false
    property date viewMonth: new Date(now.getFullYear(), now.getMonth(), 1)
    property var selectedDay: null

    readonly property var events: data ? data.events : []
    readonly property var todayEvents: events.filter(e => sameDay(new Date(e.start * 1000), now))

    function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }
    function dayKey(d) { return d.getFullYear() * 10000 + d.getMonth() * 100 + d.getDate() }

    readonly property var eventDays: {
        const map = {}
        for (const e of events) {
            const start = new Date(e.start * 1000)
            const end = new Date(Math.max(e.start, e.end - 1) * 1000)
            for (let d = new Date(start.getFullYear(), start.getMonth(), start.getDate()); d <= end; d.setDate(d.getDate() + 1)) {
                const key = dayKey(d)
                if (!map[key]) map[key] = []
                map[key].push(e.color)
            }
        }
        return map
    }

    readonly property var monthCells: {
        const first = new Date(viewMonth.getFullYear(), viewMonth.getMonth(), 1)
        const offset = (first.getDay() + 6) % 7
        const cells = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), 1 - offset + i)
            cells.push({ date: d, day: d.getDate(), inMonth: d.getMonth() === first.getMonth(), today: sameDay(d, now), key: dayKey(d) })
        }
        return cells
    }

    readonly property var agenda: {
        const groups = []
        const from = selectedDay ? new Date(selectedDay) : new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const until = selectedDay ? new Date(from.getFullYear(), from.getMonth(), from.getDate() + 1) : new Date(from.getFullYear(), from.getMonth(), from.getDate() + 14)
        for (const e of events) {
            const start = new Date(e.start * 1000)
            const end = new Date(e.end * 1000)
            if (end <= from || start >= until) continue
            const day = start < from ? from : new Date(start.getFullYear(), start.getMonth(), start.getDate())
            const key = dayKey(day)
            let group = groups.find(g => g.key === key)
            if (!group) { group = { key, date: day, label: dayLabel(day), items: [] }; groups.push(group) }
            group.items.push(e)
        }
        return groups
    }

    function dayLabel(d) {
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const diff = Math.round((d - today) / 86400000)
        if (diff === 0) return "TODAY"
        if (diff === 1) return "TOMORROW"
        return Qt.formatDate(d, "ddd d MMM").toUpperCase()
    }

    function timeLabel(e) {
        if (e.allDay) return "All day"
        const s = new Date(e.start * 1000), en = new Date(e.end * 1000)
        return Qt.formatTime(s, "HH:mm") + (en > s ? " – " + Qt.formatTime(en, "HH:mm") : "")
    }

    function refresh() { if (!loading) { loading = true; fetch.running = true } }

    active: popup.visible

    Process {
        id: fetch
        running: true
        command: ["timeout", "110", root.helper, "60"]
        onStarted: root.loading = true
        onExited: root.loading = false
        stdout: StdioCollector { onStreamFinished: { try { root.data = JSON.parse(text); root.updatedAt = new Date() } catch (e) {} } }
    }

    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }

    IpcHandler {
        target: "calendar"
        function toggle(): void { popup.toggle() }
        function refresh(): void { root.refresh() }
    }

    Row {
        spacing: 6
        BarText { text: Qt.formatDateTime(root.now, "ddd dd.MM HH:mm"); font.pixelSize: Theme.barFontSize }
        BarText {
            visible: root.todayEvents.length > 0
            text: "󰃭 " + root.todayEvents.length
            color: Theme.accent
            font.pixelSize: Theme.barFontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.toggle()
    }

    component NavButton: BarText {
        signal clicked
        width: 22; height: 22
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        color: area.containsMouse ? Theme.fg : Theme.muted
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 420
        onVisibleChanged: if (visible) { root.viewMonth = new Date(root.now.getFullYear(), root.now.getMonth(), 1); root.selectedDay = null }

        PopupHeader {
            icon: "󰃭"
            iconColor: Theme.accent
            title: Qt.formatDate(root.now, "dddd d MMMM")
            subtitle: root.data ? root.todayEvents.length + " today · " + root.events.filter(e => e.start * 1000 < root.now.getTime() + 14 * 86400000 && e.end * 1000 > root.now.getTime()).length + " in the next two weeks" : (root.loading ? "Loading calendars…" : "No calendar data")
        }

        Item { width: 1; height: 4 }

        Item {
            width: parent.width
            height: 24
            NavButton { text: "󰅁"; anchors.left: parent.left; onClicked: root.viewMonth = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() - 1, 1) }
            BarText { anchors.centerIn: parent; text: Qt.formatDate(root.viewMonth, "MMMM yyyy"); font.bold: true }
            NavButton { text: "󰅂"; anchors.right: parent.right; onClicked: root.viewMonth = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() + 1, 1) }
        }

        Grid {
            width: parent.width
            columns: 7
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                BarText { required property string modelData; width: parent.width / 7; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Theme.muted; font.pixelSize: 10 }
            }
        }

        Grid {
            width: parent.width
            columns: 7
            Repeater {
                model: root.monthCells
                Item {
                    required property var modelData
                    readonly property var dots: root.eventDays[modelData.key] || []
                    readonly property bool selected: root.selectedDay !== null && root.sameDay(root.selectedDay, modelData.date)
                    width: parent.width / 7
                    height: 34
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28; radius: 6
                        color: parent.modelData.today ? Theme.accent : parent.selected ? Theme.iconBg : cellArea.containsMouse ? Theme.track : "transparent"
                    }
                    BarText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -3
                        text: parent.modelData.day
                        font.pixelSize: 12
                        font.bold: parent.modelData.today
                        color: parent.modelData.today ? Theme.barBg : parent.modelData.inMonth ? Theme.fg : Theme.muted
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        spacing: 2
                        Repeater {
                            model: Math.min(3, parent.parent.dots.length)
                            Rectangle { required property int index; width: 4; height: 4; radius: 2; color: parent.parent.modelData.today ? Theme.barBg : parent.parent.dots[index] }
                        }
                    }
                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.selectedDay = parent.selected ? null : parent.modelData.date
                    }
                }
            }
        }

        Divider {}

        BarText {
            visible: root.agenda.length === 0
            text: root.selectedDay ? "Nothing on " + Qt.formatDate(root.selectedDay, "d MMMM") : (root.loading && !root.data ? "Loading…" : "Nothing in the next two weeks")
            color: Theme.muted
            font.pixelSize: 12
        }

        Repeater {
            model: root.agenda
            Column {
                required property var modelData
                width: parent.width
                spacing: 4
                SectionLabel { text: parent.modelData.label }
                Repeater {
                    model: parent.modelData.items
                    Item {
                        required property var modelData
                        width: parent.width
                        height: 36
                        Rectangle { x: 0; y: 4; width: 3; height: parent.height - 8; radius: 1.5; color: parent.modelData.color }
                        Column {
                            x: 12
                            width: parent.width - 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            BarText { width: parent.width; text: parent.parent.modelData.summary; font.pixelSize: 12; elide: Text.ElideRight }
                            BarText {
                                width: parent.width
                                text: root.timeLabel(parent.parent.modelData) + (parent.parent.modelData.location ? "  ·  " + parent.parent.modelData.location : "") + "  ·  " + parent.parent.modelData.calendar
                                color: Theme.muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                Item { width: 1; height: 4 }
            }
        }

        Divider {}

        Item {
            width: parent.width
            height: 16
            BarText { text: (root.loading ? "󰔛 Syncing…" : "󰔛 Updated " + Qt.formatTime(root.updatedAt, "HH:mm")); color: Theme.muted; font.pixelSize: 11 }
            Row {
                anchors.right: parent.right
                spacing: 6
                NavButton { text: "󰑐"; onClicked: root.refresh() }
                NavButton { text: "󰏌"; onClicked: { Quickshell.execDetached(["gnome-calendar"]); popup.visible = false } }
            }
        }
    }
}
