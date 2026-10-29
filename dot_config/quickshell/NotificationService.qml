pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property int historyLimit: 150
    readonly property int defaultTimeout: 5000
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/notifications.json"

    property var history: []
    property var popups: []
    property bool dnd: false
    property var live: ({})
    property int serial: 0

    readonly property int unread: history.filter(e => !e.read).length
    readonly property date now: clock.date

    function ago(time) {
        const minutes = Math.floor((now.getTime() - time) / 60000)
        if (minutes < 1) return "now"
        if (minutes < 60) return minutes + "m"
        const d = new Date(time)
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        if (d >= today) return Qt.formatTime(d, "HH:mm")
        if (d >= today - 86400000) return "yesterday " + Qt.formatTime(d, "HH:mm")
        return Qt.formatDateTime(d, "d MMM HH:mm")
    }

    readonly property var appActions: ({
        "Mail": ["ghostty", "-e", "aerc"],
        "GitHub": ["xdg-open", "https://github.com/notifications"]
    })

    function iconFor(entry) {
        if (entry.image !== "") return entry.image
        if (entry.icon === "") return ""
        if (entry.icon.startsWith("/") || entry.icon.startsWith("file://")) return entry.icon
        return Quickshell.iconPath(entry.icon, true)
    }

    function pictureFor(entry) {
        const image = liveFor(entry.key) !== null ? entry.liveImage : entry.image
        if (image.startsWith("image://icon/")) {
            const resolved = Quickshell.iconPath(image.slice(13), true)
            if (resolved !== "") return resolved
        } else if (image !== "") {
            return image
        }
        return iconFor(entry)
    }

    function liveFor(key) {
        const n = live[key]
        return n && n.tracked ? n : null
    }

    function actionsFor(key) {
        const n = liveFor(key)
        return n ? n.actions.filter(a => a.identifier !== "default") : []
    }

    function canActivate(entry) {
        const n = liveFor(entry.key)
        return (n !== null && n.actions.some(a => a.identifier === "default")) || appActions[entry.app] !== undefined
    }

    function timeoutFor(n) {
        if (n.urgency === NotificationUrgency.Critical) return 0
        const t = n.expireTimeout
        if (t <= 0) return defaultTimeout
        return t < 300 ? t * 1000 : t
    }

    function snapshot(n, key) {
        return {
            key,
            nid: n.id,
            session: persist.session,
            app: n.appName || "Unknown",
            summary: n.summary,
            body: n.body,
            icon: n.appIcon || "",
            image: n.image.startsWith("image://") ? "" : n.image,
            liveImage: n.image,
            urgency: n.urgency,
            timeout: timeoutFor(n),
            time: Date.now(),
            read: false
        }
    }

    function receive(n) {
        n.tracked = true
        const known = history.find(e => e.session === persist.session && e.nid === n.id && e.summary === n.summary && e.body === n.body && !(e.key in live))
        if (known) {
            live = Object.assign({}, live, { [known.key]: n })
            n.closed.connect(() => forget(known.key))
            return
        }
        const key = Date.now() + "-" + (serial++)
        live = Object.assign({}, live, { [key]: n })
        n.closed.connect(() => forget(key))

        const entry = snapshot(n, key)
        if (!n.transient) {
            const kept = [entry].concat(history)
            for (const old of kept.slice(historyLimit)) dropLive(old.key)
            history = kept.slice(0, historyLimit)
            save()
        }
        if (!dnd || n.urgency === NotificationUrgency.Critical) popups = [entry].concat(popups.filter(p => p.key !== key))
    }

    function refresh(n) {
        const key = Object.keys(live).find(k => live[k] === n)
        if (!key) return
        const update = e => e.key === key ? Object.assign({}, e, { summary: n.summary, body: n.body, liveImage: n.image, time: Date.now(), read: false }) : e
        history = history.map(update)
        popups = popups.map(update)
        save()
    }

    function unlink(key) {
        if (!(key in live)) return
        const next = Object.assign({}, live)
        delete next[key]
        live = next
    }

    function forget(key) {
        unlink(key)
        hidePopup(key)
    }

    function dropLive(key) {
        const n = liveFor(key)
        unlink(key)
        if (n) n.dismiss()
    }

    function hideAllPopups() {
        popups = []
    }

    function hidePopup(key) {
        popups = popups.filter(p => p.key !== key)
    }

    function activate(entry) {
        const n = liveFor(entry.key)
        const action = n ? n.actions.find(a => a.identifier === "default") : null
        if (action) action.invoke()
        else if (appActions[entry.app]) Quickshell.execDetached(appActions[entry.app])
        else return
        if (!n || !n.resident) dismiss(entry.key)
    }

    function invoke(key, action) {
        const n = liveFor(key)
        action.invoke()
        if (!n || !n.resident) dismiss(key)
    }

    function dismiss(key) {
        dropLive(key)
        hidePopup(key)
        history = history.filter(e => e.key !== key)
        save()
    }

    function clear() {
        for (const e of history) dropLive(e.key)
        history = []
        popups = []
        save()
    }

    function markRead() {
        if (unread === 0) return
        history = history.map(e => e.read ? e : Object.assign({}, e, { read: true }))
        save()
    }

    function toggleDnd() {
        dnd = !dnd
        if (dnd) popups = popups.filter(p => p.urgency === NotificationUrgency.Critical)
        save()
    }

    function save() { saveTimer.restart() }

    PersistentProperties {
        id: persist
        reloadableId: "notificationService"
        property string session: ""
        Component.onCompleted: if (session === "") session = String(Date.now())
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        actionsSupported: true
        imageSupported: true
        onNotification: n => root.receive(n)
    }

    Instantiator {
        model: Object.values(root.live)
        delegate: Connections {
            required property var modelData
            target: modelData
            function onSummaryChanged() { root.refresh(modelData) }
            function onBodyChanged() { root.refresh(modelData) }
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: store.setText(JSON.stringify({
            dnd: root.dnd,
            history: root.history.map(e => Object.assign({}, e, { liveImage: "" }))
        }))
    }

    FileView {
        id: store
        path: root.statePath
        printErrors: false
        atomicWrites: true
        blockLoading: true
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                const old = (saved.history || []).filter(s => !root.history.some(e => e.key === s.key))
                root.dnd = saved.dnd === true
                root.history = root.history.concat(old).slice(0, root.historyLimit)
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "notifications"
        function dnd(): void { root.toggleDnd() }
        function clear(): void { root.clear() }
        function dismissLatest(): void { if (root.popups.length > 0) root.hidePopup(root.popups[0].key) }
    }
}
