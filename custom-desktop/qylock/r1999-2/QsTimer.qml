// Loaded only under the Quickshell lock (Main.qml gates it): mirrors the iris
// timers (countdown, pomodoro, stopwatch) from their saved state, so the lock
// screen can show them live. Read-only; the shell still owns the timers.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: t

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")

    property var timer: ({})
    property var pomo: ({})
    property real now: Date.now()

    // [{ label, text }] for every active timer, countdown first.
    readonly property var rows: {
        const out = []
        const sec = Math.floor(t.now / 1000)
        const c = t.timer.countdown
        if (c && c.running) {
            const left = c.duration - (sec - c.start)
            if (c.paused) out.push({ label: "TIMER", text: "PAUSED" })
            else if (left > 0) out.push({ label: "TIMER", text: t.clock(left) })
        }
        const p = t.timer.pomodoro
        if (p && p.running) {
            const cycles = t.pomo.cyclesBeforeLongBreak ?? 4
            const longBreak = p.isBreak && (p.cycle + 1 === cycles)
            const lap = longBreak ? (t.pomo.longBreak ?? 900) : p.isBreak ? (t.pomo.breakTime ?? 300) : (t.pomo.focus ?? 1500)
            const label = p.isBreak ? "BREAK" : "FOCUS"
            out.push({ label: label, text: p.paused ? "PAUSED" : t.clock(Math.max(0, lap - (sec - p.start))) })
        }
        const w = t.timer.stopwatch
        if (w && w.running)
            out.push({ label: "STOPWATCH", text: w.paused ? "PAUSED" : t.clock(Math.floor((Math.floor(t.now / 10) - w.start) / 100)) })
        return out
    }

    function clock(s) {
        s = Math.max(0, Math.floor(s))
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60
        const mm = (h > 0 && m < 10 ? "0" : "") + m
        return (h > 0 ? h + ":" : "") + mm + ":" + (r < 10 ? "0" : "") + r
    }

    function parse(text, apply) {
        try { apply(JSON.parse(text)) } catch (e) {}
    }

    FileView {
        path: t.stateDir + "/quickshell/ryoku/inir/states.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: t.parse(text(), d => t.timer = d.timer ?? ({}))
    }

    FileView {
        path: t.configDir + "/ryoku/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: t.parse(text(), d => t.pomo = d.inir?.time?.pomodoro ?? ({}))
    }

    Timer {
        interval: 250; repeat: true
        running: t.rows.length > 0 || (t.timer.countdown?.running ?? false) || (t.timer.pomodoro?.running ?? false) || (t.timer.stopwatch?.running ?? false)
        onTriggered: t.now = Date.now()
    }
}
