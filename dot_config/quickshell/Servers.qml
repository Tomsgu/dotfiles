import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    required property date now

    property var servers: []
    property string error: ""
    property string expanded: ""
    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/server-health/all.json"
    readonly property int nowEpoch: Math.floor(now.getTime() / 1000)

    function ago(epoch) {
        if (!epoch) return "never"
        const s = Math.max(0, nowEpoch - epoch)
        if (s < 90) return "just now"
        if (s < 5400) return Math.round(s / 60) + "m ago"
        if (s < 172800) return Math.round(s / 3600) + "h ago"
        return Math.round(s / 86400) + "d ago"
    }

    function duration(s) {
        const d = Math.floor(s / 86400)
        const h = Math.floor(s % 86400 / 3600)
        return d > 0 ? `${d}d ${h}h` : `${h}h ${Math.floor(s % 3600 / 60)}m`
    }

    function gb(kb) {
        return (kb / 1048576).toFixed(1)
    }

    function memPct(s) {
        return s.mem && s.mem.total ? Math.round((s.mem.total - s.mem.available) * 100 / s.mem.total) : 0
    }

    function swapPct(s) {
        return s.mem && s.mem.swap_total ? Math.round((s.mem.swap_total - s.mem.swap_free) * 100 / s.mem.swap_total) : 0
    }

    function siteName(url) {
        return url.replace(/^https?:\/\//, "").split(".")[0]
    }

    function siteOk(w) {
        return w.code >= 200 && w.code < 400
    }

    function issues(s) {
        const list = []
        const critical = text => list.push({ level: 2, text })
        const warning = text => list.push({ level: 1, text })

        if (s.reachable === false) critical("unreachable, last contact " + ago(s.generated_at))
        if (s.fetched_at && nowEpoch - s.fetched_at > 20 * 60) warning("last fetch " + ago(s.fetched_at) + ", is server-health-fetch.timer running?")
        if (!s.generated_at) return list
        if (nowEpoch - s.generated_at > 20 * 60) warning("snapshot is " + ago(s.generated_at))

        for (const unit of s.failed || []) critical("failed unit " + unit)
        for (const svc of s.services || []) if (svc.state !== "active") critical(`${svc.name} is ${svc.state}`)
        for (const t of s.timers || []) if (t.result !== "success" && t.result !== "unknown") critical(`${t.name} last run ${t.result}`)
        for (const w of s.sites || []) if (!siteOk(w)) critical(`${siteName(w.url)} answers HTTP ${w.code}`)

        if (s.watch) {
            if (s.watch.procs > 0) critical(`${s.watch.procs} process(es) running as ${s.watch.user}`)
            if (s.watch.cron > 0) critical(`${s.watch.user} has a crontab`)
        }

        const disk = s.disk ? s.disk.pct : 0
        if (disk >= 85) critical(`disk ${disk}% full`)
        else if (disk >= 70) warning(`disk ${disk}% full`)

        const mem = memPct(s)
        if (mem >= 90) critical(`memory ${mem}% used`)
        else if (mem >= 80) warning(`memory ${mem}% used`)

        if (s.cpu && parseFloat(s.cpu.load[0]) > s.cpu.cores * 2) warning(`load ${s.cpu.load[0]} on ${s.cpu.cores} cores`)

        if (s.updates) {
            if (s.updates.reboot_required) warning("reboot pending")
            if (s.updates.pending > 0) warning(`${s.updates.pending} package update(s) pending`)
            if (s.updates.last > 0 && nowEpoch - s.updates.last > 14 * 86400) warning(`no package upgrade for ${Math.round((nowEpoch - s.updates.last) / 86400)} days`)
        }

        for (const j of s.jails || []) if (j.banned > 50) warning(`${j.name}: ${j.banned} IP(s) banned now`)

        if (s.backup && s.backup.newest !== undefined) {
            if (!s.backup.at) warning("no backup found")
            else if (nowEpoch - s.backup.at > 36 * 3600) warning("last backup " + ago(s.backup.at))
        }
        return list
    }

    function level(s) {
        return issues(s).reduce((m, i) => Math.max(m, i.level), 0)
    }

    function levelColor(l) {
        return l >= 2 ? Theme.red : l === 1 ? Theme.yellow : Theme.green
    }

    readonly property int worst: servers.reduce((m, s) => Math.max(m, level(s)), 0)
    readonly property int issueCount: servers.reduce((n, s) => n + issues(s).length, 0)

    function parse(text) {
        try {
            servers = JSON.parse(text)
            error = ""
            if (servers.length === 1) expanded = servers[0].name
        } catch (e) {
            error = "Unreadable " + cachePath
        }
    }

    active: popup.visible

    FileView {
        path: root.cachePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.error = "No data yet: run server-health-fetch"
    }

    Process {
        id: fetch
        command: ["systemctl", "--user", "start", "server-health-fetch.service"]
    }

    Process {
        id: openDashboard
        command: ["xdg-open", "http://127.0.0.1:8090"]
    }

    IpcHandler {
        target: "servers"
        function toggle(): void { popup.toggle() }
        function refresh(): void { fetch.running = true }
    }

    Row {
        spacing: 5
        BarText { text: "󰒋"; color: root.servers.length ? root.levelColor(root.worst) : Theme.muted; font.pixelSize: Theme.barFontSize }
        Repeater {
            model: root.servers
            BarText {
                required property var modelData
                text: "●"
                color: root.levelColor(root.level(modelData))
                font.pixelSize: Theme.barFontSize
            }
        }
        BarText {
            visible: root.issueCount > 0
            text: root.issueCount
            color: root.levelColor(root.worst)
            font.pixelSize: Theme.barFontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.toggle()
    }

    component ServerCard: Column {
        id: card
        required property var modelData
        readonly property var s: modelData || ({})
        readonly property var problems: root.issues(s)
        readonly property int lvl: root.level(s)
        readonly property bool open: root.expanded === s.name
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 22

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                BarText { text: "●"; color: root.levelColor(card.lvl); font.pixelSize: 13 }
                BarText { text: card.s.name || card.s.host || ""; font.bold: true; font.pixelSize: 13 }
                BarText { text: [card.s.host, card.s.uptime ? "up " + root.duration(card.s.uptime) : ""].filter(Boolean).join(" · "); color: Theme.muted; font.pixelSize: 11 }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                ServerPct { visible: card.s.cpu !== undefined; label: "cpu"; pct: card.s.cpu ? card.s.cpu.pct : 0 }
                ServerPct { visible: card.s.mem !== undefined; label: "ram"; pct: root.memPct(card.s) }
                ServerPct { visible: card.s.disk !== undefined; label: "disk"; pct: card.s.disk ? card.s.disk.pct : 0 }
                BarText { text: card.open ? "󰅃" : "󰅀"; color: Theme.muted; font.pixelSize: 13 }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.expanded = card.open ? "" : card.s.name
            }
        }

        Repeater {
            model: card.problems
            BarText {
                required property var modelData
                width: parent.width
                leftPadding: 22
                text: (modelData.level === 2 ? "✗ " : "! ") + modelData.text
                color: root.levelColor(modelData.level)
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }

        BarText {
            visible: card.problems.length === 0 && card.s.reachable === true
            leftPadding: 22
            text: "✓ all checks pass"
            color: Theme.green
            font.pixelSize: 11
        }

        Column {
            visible: card.open && card.s.generated_at !== undefined
            width: parent.width
            spacing: 7
            leftPadding: 22

            Item { width: 1; height: 2 }

            ServerMeter {
                width: parent.width - 22
                label: "CPU"
                pct: card.s.cpu ? card.s.cpu.pct : 0
                detail: card.s.cpu ? `load ${card.s.cpu.load.join(" / ")} · ${card.s.cpu.cores} core${card.s.cpu.cores === 1 ? "" : "s"}` : ""
            }
            ServerMeter {
                width: parent.width - 22
                label: "RAM"
                pct: root.memPct(card.s)
                detail: card.s.mem ? `${root.gb(card.s.mem.total - card.s.mem.available)} / ${root.gb(card.s.mem.total)} GB · swap ${root.swapPct(card.s)}%` : ""
            }
            ServerMeter {
                width: parent.width - 22
                label: "Disk /"
                pct: card.s.disk ? card.s.disk.pct : 0
                detail: card.s.disk ? `${root.gb(card.s.disk.used)} / ${root.gb(card.s.disk.total)} GB` : ""
            }

            Item { width: 1; height: 4 }

            ServerDetailRow {
                width: parent.width - 22
                label: "System"
                ServerChip { text: "linux " + (card.s.kernel || "?") }
                ServerChip { text: "snapshot " + root.ago(card.s.generated_at) }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "Updates"
                ServerChip { text: card.s.updates && card.s.updates.last ? "upgraded " + root.ago(card.s.updates.last) : "never upgraded"; textColor: card.s.updates && card.s.updates.last && root.nowEpoch - card.s.updates.last > 14 * 86400 ? Theme.yellow : Theme.fg }
                ServerChip { text: (card.s.updates ? card.s.updates.pending : 0) + " pending"; textColor: card.s.updates && card.s.updates.pending > 0 ? Theme.yellow : Theme.fg }
                ServerChip { text: card.s.updates && card.s.updates.reboot_required ? "reboot required" : "no reboot needed"; textColor: card.s.updates && card.s.updates.reboot_required ? Theme.yellow : Theme.fg }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "Services"
                visible: (card.s.services || []).length > 0 || (card.s.failed || []).length > 0
                Repeater {
                    model: card.s.services || []
                    ServerChip { required property var modelData; text: modelData.name + (modelData.state === "active" ? " ✓" : " " + modelData.state); textColor: modelData.state === "active" ? Theme.green : Theme.red }
                }
                Repeater {
                    model: card.s.failed || []
                    ServerChip { required property var modelData; text: modelData + " failed"; textColor: Theme.red }
                }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "Timers"
                visible: (card.s.timers || []).length > 0
                Repeater {
                    model: card.s.timers || []
                    ServerChip { required property var modelData; text: modelData.name + " " + root.ago(modelData.last); textColor: modelData.result === "success" || modelData.result === "unknown" ? Theme.fg : Theme.red }
                }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "fail2ban"
                visible: (card.s.jails || []).length > 0
                Repeater {
                    model: card.s.jails || []
                    ServerChip { required property var modelData; text: `${modelData.name} ${modelData.banned} now · ${modelData.total} total`; textColor: modelData.banned > 50 ? Theme.yellow : Theme.fg }
                }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "Sites"
                visible: (card.s.sites || []).length > 0
                Repeater {
                    model: card.s.sites || []
                    ServerChip { required property var modelData; text: `${root.siteName(modelData.url)} ${modelData.code} · ${modelData.ms} ms`; textColor: root.siteOk(modelData) ? Theme.green : Theme.red }
                }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "SSH"
                visible: card.s.logins !== undefined
                ServerChip { text: (card.s.logins ? card.s.logins.accepted_24h : 0) + " logins / 24h" }
                ServerChip { visible: !!card.s.logins && card.s.logins.last !== ""; text: "last " + (card.s.logins ? card.s.logins.last.split(" ")[0] : "") }
                ServerChip {
                    visible: !!card.s.watch && card.s.watch.user !== ""
                    text: card.s.watch ? (card.s.watch.procs === 0 && card.s.watch.cron === 0 ? card.s.watch.user + " user clean" : `${card.s.watch.user}: ${card.s.watch.procs} procs, ${card.s.watch.cron ? "crontab!" : "no crontab"}`) : ""
                    textColor: card.s.watch && (card.s.watch.procs > 0 || card.s.watch.cron > 0) ? Theme.red : Theme.green
                }
            }
            ServerDetailRow {
                width: parent.width - 22
                label: "Backup"
                visible: card.s.backup !== undefined && card.s.backup.newest !== ""
                ServerChip { text: card.s.backup ? `${card.s.backup.newest} · ${root.ago(card.s.backup.at)} · ${card.s.backup.size}` : ""; textColor: card.s.backup && card.s.backup.at && root.nowEpoch - card.s.backup.at > 36 * 3600 ? Theme.yellow : Theme.fg }
                ServerChip { visible: card.s.forgejo_users >= 0; text: "forgejo users " + card.s.forgejo_users; textColor: card.s.forgejo_users > 1 ? Theme.yellow : Theme.fg }
            }
        }
    }

    BarPopup {
        id: popup
        anchorItem: root
        cardWidth: 520

        PopupHeader {
            icon: "󰒋"
            iconColor: root.levelColor(root.worst)
            title: "Servers"
            subtitle: root.servers.length + " monitored · " + (root.issueCount === 0 ? "no issues" : root.issueCount + " issue(s)")
        }

        Item { width: 1; height: 2 }

        BarText {
            visible: root.servers.length === 0
            text: root.error !== "" ? root.error : "Loading..."
            color: Theme.muted
            font.pixelSize: 11
        }

        Repeater {
            model: root.servers
            Column {
                required property var modelData
                required property int index
                width: parent.width
                spacing: 8
                Divider { visible: index > 0 }
                ServerCard { modelData: parent.modelData }
            }
        }

        Divider {}

        Item {
            width: parent.width
            height: 14
            BarText {
                text: "Click a server for details · refreshed every 5 min · dashboard ↗"
                color: Theme.muted
                font.pixelSize: 10
                MouseArea {
                    anchors.fill: parent
                    onClicked: openDashboard.running = true
                }
            }
            BarText {
                anchors.right: parent.right
                text: "󰑐"
                color: refreshArea.containsMouse ? Theme.fg : Theme.muted
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: fetch.running = true
                }
            }
        }
    }
}
