import Quickshell
import Quickshell.Io
import QtQuick

BarItem {
    id: root
    required property date now

    property var usage: null
    property string error: ""
    property string accessToken: ""
    property string plan: ""
    property date updatedAt: new Date()

    readonly property var windows: {
        if (!usage) return []
        const rows = []
        const add = (title, pct, resetsAt, length) => rows.push({ title, pct: Math.round(pct), resetsAt: Date.parse(resetsAt) / 1000, length })
        if (usage.five_hour && usage.five_hour.utilization !== null) add("Session", usage.five_hour.utilization, usage.five_hour.resets_at, 5 * 3600)
        if (usage.seven_day && usage.seven_day.utilization !== null) add("Weekly", usage.seven_day.utilization, usage.seven_day.resets_at, 7 * 86400)
        for (const limit of usage.limits || [])
            if (limit.kind === "weekly_scoped" && limit.scope && limit.scope.model)
                add(limit.scope.model.display_name + " · Weekly", limit.percent, limit.resets_at, 7 * 86400)
        return rows
    }

    readonly property var extra: usage && usage.extra_usage && usage.extra_usage.is_enabled ? usage.extra_usage : null
    readonly property int sessionPct: windows.length > 0 ? windows[0].pct : 0
    readonly property int weeklyPct: windows.length > 1 ? windows[1].pct : 0

    function countdown(seconds) {
        if (seconds <= 0) return "now"
        const d = Math.floor(seconds / 86400)
        const h = Math.floor(seconds % 86400 / 3600)
        const m = Math.floor(seconds % 3600 / 60)
        if (d > 0) return `${d}d ${h}h`
        if (h > 0) return `${h}h ${m}m`
        return `${m}m`
    }

    function money(credits) {
        const places = extra && extra.decimal_places !== null ? extra.decimal_places : 2
        return "$" + (credits / Math.pow(10, places)).toFixed(places)
    }

    function readCredentials(text) {
        try {
            const oauth = JSON.parse(text).claudeAiOauth
            accessToken = oauth.accessToken || ""
            const tier = (oauth.rateLimitTier || "").match(/(\d+x)$/)
            plan = ((oauth.subscriptionType || "") + (tier ? " " + tier[1] : "")).toUpperCase()
            fetch.running = true
        } catch (e) {
            error = "No Claude login found"
        }
    }

    function applyResponse(output) {
        const cut = output.lastIndexOf("\n")
        const status = output.slice(cut + 1)
        if (status === "200") {
            usage = JSON.parse(output.slice(0, cut))
            updatedAt = new Date()
            error = ""
        } else if (status === "401") {
            error = "Token expired, run claude to refresh"
        } else {
            error = "Usage API error " + status
        }
    }

    active: popup.visible

    FileView {
        path: Quickshell.env("HOME") + "/.claude/.credentials.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.readCredentials(text())
        onLoadFailed: root.error = "No Claude login found"
    }

    Timer {
        interval: 5 * 60 * 1000
        running: root.accessToken !== ""
        repeat: true
        onTriggered: fetch.running = true
    }

    Process {
        id: fetch
        command: ["sh", "-c", "curl -s --max-time 10 -w '\\n%{http_code}' -H \"Authorization: Bearer $CLAUDE_TOKEN\" -H 'anthropic-beta: oauth-2025-04-20' https://api.anthropic.com/api/oauth/usage"]
        environment: ({ CLAUDE_TOKEN: root.accessToken })
        stdout: StdioCollector { onStreamFinished: root.applyResponse(text) }
    }

    IpcHandler {
        target: "claude"
        function toggle(): void { popup.toggle() }
        function refresh(): void { fetch.running = true }
    }

    Row {
        spacing: 5
        BarText { text: "✱"; color: Theme.peach; font.pixelSize: Theme.barFontSize }
        BarText {
            text: root.usage ? root.sessionPct + "%" : "--"
            color: root.usage ? Theme.levelColor(root.sessionPct) : Theme.muted
            font.pixelSize: Theme.barFontSize
        }
        BarText {
            text: "•"
            color: root.usage ? Theme.levelColor(root.weeklyPct) : Theme.muted
            font.pixelSize: Theme.barFontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.toggle()
    }

    component UsageRow: Column {
        required property var modelData
        readonly property int secondsLeft: modelData.resetsAt - Math.floor(root.now.getTime() / 1000)
        readonly property int elapsed: Math.min(100, Math.max(0, Math.round((modelData.length - secondsLeft) * 100 / modelData.length)))
        readonly property int diff: modelData.pct - elapsed

        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 16
            BarText { text: parent.parent.modelData.title; color: Theme.accent }
            BarText {
                anchors.right: parent.right
                text: parent.parent.modelData.pct + "%"
                color: Theme.levelColor(parent.parent.modelData.pct)
                font.bold: true
            }
        }

        UsageBar { pct: parent.modelData.pct; marker: parent.elapsed }

        Item {
            width: parent.width
            height: 14
            BarText { text: "Resets in " + root.countdown(parent.parent.secondsLeft); color: Theme.muted; font.pixelSize: 11 }
            BarText {
                anchors.right: parent.right
                readonly property int diff: parent.parent.diff
                text: diff > 5 ? `↑ ${diff}pts ahead` : diff < -5 ? `↓ ${-diff}pts under` : "→ on pace"
                color: diff > 5 ? Theme.red : diff < -5 ? Theme.green : Theme.muted
                font.pixelSize: 11
            }
        }

        Item { width: 1; height: 6 }
    }

    BarPopup {
        id: popup
        anchorItem: root

        PopupHeader { icon: "✱"; title: "Claude"; subtitle: root.plan }

        Item { width: 1; height: 8 }
        SectionLabel { text: "USAGE" }

        BarText {
            visible: root.windows.length === 0
            text: root.error !== "" ? root.error : "Loading..."
            color: Theme.muted
            font.pixelSize: 11
        }

        Repeater {
            model: root.windows
            UsageRow {}
        }

        Divider { visible: root.extra !== null }
        SectionLabel { visible: root.extra !== null; text: "EXTRA USAGE" }

        Column {
            visible: root.extra !== null
            width: parent.width
            spacing: 6

            Item {
                width: parent.width
                height: 16
                BarText {
                    text: root.extra ? `Spent: ${root.money(root.extra.used_credits || 0)} / ${root.money(root.extra.monthly_limit || 0)}` : ""
                    color: Theme.muted
                    font.pixelSize: 11
                }
                BarText {
                    anchors.right: parent.right
                    text: root.extra ? Math.round(root.extra.utilization || 0) + "%" : ""
                    color: Theme.levelColor(root.extra ? root.extra.utilization || 0 : 0)
                    font.bold: true
                }
            }

            UsageBar { pct: root.extra ? Math.round(root.extra.utilization || 0) : 0 }

            BarText {
                text: root.extra ? `Available: ${root.money((root.extra.monthly_limit || 0) - (root.extra.used_credits || 0))} · Monthly limit: ${root.money(root.extra.monthly_limit || 0)}` : ""
                color: Theme.muted
                font.pixelSize: 11
            }
        }

        Divider {}

        Item {
            width: parent.width
            height: 16
            BarText {
                text: "󰔛 Updated " + Qt.formatTime(root.updatedAt, "HH:mm") + (root.error !== "" && root.usage ? "  (" + root.error + ")" : "")
                color: root.error !== "" ? Theme.red : Theme.muted
                font.pixelSize: 11
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
