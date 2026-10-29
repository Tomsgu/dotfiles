pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var status: null
    property string mac: ""
    property bool busy: false
    property int cardId: -1
    property string profile: ""
    property int a2dpIndex: -1
    property int headsetIndex: -1

    readonly property bool daemonRunning: status !== null
    readonly property bool connected: daemonRunning && status.connected === true
    readonly property bool micOn: profile.startsWith("headset")
    readonly property bool audioConnected: cardId >= 0 && profile !== "" && profile !== "off"
    readonly property bool linked: connected || audioConnected
    readonly property bool paired: mac !== ""
    readonly property string ctl: Quickshell.env("HOME") + "/.local/bin/librepods-ctl"
    readonly property string statusPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/librepods/status.json"
    readonly property string title: connected ? (status.model_name || status.device_name || "AirPods") : "AirPods"

    readonly property var pods: {
        if (!connected) return []
        if (status.is_headset && status.headset) return [{ name: "Headphones", part: status.headset }]
        return [
            { name: "Left", part: status.left },
            { name: "Right", part: status.right },
            { name: "Case", part: status.case }
        ].filter(row => row.part && row.part.available)
    }

    readonly property var modes: {
        if (!connected || !status.supports_noise_control) return []
        const list = []
        if (status.supports_noise_off !== false) list.push({ id: 0, verb: "noise:off", name: "Off" })
        list.push({ id: 2, verb: "noise:transparency", name: "Transparency" })
        if (status.supports_adaptive) list.push({ id: 3, verb: "noise:adaptive", name: "Adaptive" })
        list.push({ id: 1, verb: "noise:anc", name: "Noise Cancellation" })
        return list
    }

    readonly property int lowestLevel: {
        const levels = pods.filter(row => row.name !== "Case" && row.part.level >= 0).map(row => row.part.level)
        return levels.length ? Math.min(...levels) : -1
    }

    function batteryColor(part) {
        if (part.level < 0) return Theme.muted
        if (part.charging) return Theme.green
        return part.level <= 20 ? Theme.red : Theme.fg
    }

    function podMeta(row) {
        if (row.name === "Case") return row.part.charging ? "Charging" : status.lid_state === 0 ? "Open" : status.lid_state === 1 ? "Closed" : ""
        if (row.part.charging) return "Charging"
        return row.part.in_ear ? "In ear" : ""
    }

    function send(verb) {
        control.command = [ctl, verb]
        control.running = true
    }

    function toggleMic() {
        if (cardId < 0) return
        setProfile.command = ["wpctl", "set-profile", String(cardId), String(micOn ? a2dpIndex : headsetIndex)]
        setProfile.running = true
    }

    function toggleConnection() {
        if (mac === "" || busy) return
        busy = true
        link.command = ["bluetoothctl", linked ? "disconnect" : "connect", mac]
        link.running = true
    }

    function refreshProfile() { profileQuery.running = true }

    onConnectedChanged: profileRefresh.restart()

    FileView {
        id: statusFile
        path: root.statusPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.status = JSON.parse(text()) } catch (e) { root.status = null } }
        onLoadFailed: root.status = null
    }

    Timer { interval: 5000; running: !root.daemonRunning; repeat: true; onTriggered: statusFile.reload() }

    Process { id: control }

    Process { id: link; onExited: root.busy = false }

    Process {
        id: findMac
        running: true
        command: ["sh", "-c", "for m in $(bluetoothctl devices Paired | awk '{print $2}'); do bluetoothctl info \"$m\" | grep -q 74ec2172 && echo \"$m\" && break; done"]
        stdout: StdioCollector { onStreamFinished: root.mac = text.trim() }
    }

    Process {
        id: profileQuery
        command: ["sh", "-c", "pw-dump | jq -r '.[] | select(.type==\"PipeWire:Interface:Device\" and .info.props[\"device.api\"]==\"bluez5\") | \"\\(.id) \\(.info.params.Profile[0].name) \\((.info.params.EnumProfile[] | select(.name==\"a2dp-sink\") | .index) // -1) \\((.info.params.EnumProfile[] | select(.name==\"headset-head-unit\") | .index) // -1)\"' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                const ok = parts.length === 4
                root.cardId = ok ? parseInt(parts[0]) : -1
                root.profile = ok ? parts[1] : ""
                root.a2dpIndex = ok ? parseInt(parts[2]) : -1
                root.headsetIndex = ok ? parseInt(parts[3]) : -1
                if (ok && root.profile === "off" && root.a2dpIndex >= 0) {
                    setProfile.command = ["wpctl", "set-profile", String(root.cardId), String(root.a2dpIndex)]
                    setProfile.running = true
                }
            }
        }
    }

    Process { id: setProfile; onExited: profileRefresh.restart() }

    Timer { id: profileRefresh; interval: 1200; onTriggered: profileQuery.running = true }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: profileQuery.running = true }

    IpcHandler {
        target: "airpods"
        function cycle(): void { root.send("noise:cycle") }
        function mic(): void { root.toggleMic() }
    }
}
