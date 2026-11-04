// Loaded only under the Quickshell lock (Main.qml gates it): volume and
// brightness indicators so the media keys give feedback while locked.
// Brightness grows out of the left edge, volume out of the right, each a
// dynamic-island capsule in the theme's black and gold.
// Read-only: Hyprland's `locked` binds still do the actual change.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: o

    // Set by Main.qml so it matches the theme.
    property real s: 1
    property color fg: "#fdfaf2"
    property color gold: "#c9a063"
    property string fontName: ""

    // Ignore the first readings so nothing flashes when the lock opens.
    property bool ready: false
    Timer { interval: 1200; running: true; onTriggered: o.ready = true }

    // ── volume ────────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: o.sink ? [o.sink] : [] }
    readonly property real vol: (o.sink && o.sink.audio) ? o.sink.audio.volume : 0
    readonly property bool volMuted: (o.sink && o.sink.audio) ? o.sink.audio.muted : false
    onVolChanged: if (o.ready) volIsland.pop()
    onVolMutedChanged: if (o.ready) volIsland.pop()

    // ── brightness (sysfs, polled while locked) ──────────────────────────
    property string blDir: ""
    property real bright: -1
    property real brightMax: 1
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/backlight/* 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: o.blDir = text.trim() }
    }
    FileView { path: o.blDir ? o.blDir + "/max_brightness" : ""
        onLoaded: o.brightMax = Math.max(1, parseInt(text())) }
    FileView { id: curFile; path: o.blDir ? o.blDir + "/brightness" : ""
        onLoaded: {
            const v = parseInt(text())
            if (isNaN(v) || v === o.bright) return
            const first = o.bright < 0
            o.bright = v
            if (!first && o.ready) brightIsland.pop()
        } }
    Timer { interval: 200; repeat: true; running: o.blDir !== ""; onTriggered: curFile.reload() }

    // ── the island ───────────────────────────────────────────────────────
    component Island: Item {
        id: isl
        property bool onLeft: true
        property string glyph: ""
        property string caption: ""
        property real value: 0
        property bool muted: false
        property bool open: false

        function pop() { isl.open = true; closeTimer.restart() }
        Timer { id: closeTimer; interval: 1600; onTriggered: isl.open = false }

        anchors.verticalCenter: parent.verticalCenter
        x: onLeft ? 90 * o.s : parent.width - width - 90 * o.s
        width: 92 * o.s
        height: 360 * o.s

        // The capsule: a small dot at rest, springs open into a tall pill.
        Rectangle {
            id: capsule
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: isl.onLeft ? parent.left : undefined
            anchors.right: isl.onLeft ? undefined : parent.right
            width: isl.open ? isl.width : 12 * o.s
            height: isl.open ? isl.height : 12 * o.s
            radius: width / 2
            color: "#e6000000"
            border.color: o.gold
            border.width: 1
            opacity: isl.open ? 1 : 0
            Behavior on width { NumberAnimation { duration: isl.open ? 520 : 320; easing.type: isl.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.4 } }
            Behavior on height { NumberAnimation { duration: isl.open ? 560 : 300; easing.type: isl.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.1 } }
            Behavior on opacity { NumberAnimation { duration: isl.open ? 160 : 380 } }

            // Faint inner ring, like the theme's orbits.
            Rectangle {
                anchors.fill: parent; anchors.margins: 4 * o.s
                radius: width / 2; color: "transparent"
                border.color: o.gold; border.width: 1; opacity: 0.25
            }

            Column {
                id: content
                anchors.centerIn: parent
                spacing: 14 * o.s
                opacity: isl.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: isl.open ? 260 : 120 } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: isl.glyph
                    font.pixelSize: 27 * o.s
                    color: isl.muted ? "#ff6b6b" : o.gold
                }
                // Vertical gauge, fills from the bottom.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 7 * o.s; height: 185 * o.s
                    Rectangle { anchors.fill: parent; radius: width / 2; color: o.fg; opacity: 0.15 }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; radius: width / 2
                        height: parent.height * (isl.muted ? 0 : Math.max(0, Math.min(1, isl.value)))
                        color: o.gold
                        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                    // Gold star riding the top of the fill.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * (1 - (isl.muted ? 0 : Math.max(0, Math.min(1, isl.value)))) - height / 2
                        text: "✦"; font.pixelSize: 14 * o.s; color: o.fg
                        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: isl.muted ? "MUTE" : Math.round(isl.value * 100)
                    font.family: o.fontName; font.pixelSize: 18 * o.s; font.letterSpacing: 1 * o.s
                    color: isl.muted ? "#ff6b6b" : o.fg
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: isl.caption
                    font.family: o.fontName; font.pixelSize: 10 * o.s; font.letterSpacing: 2 * o.s
                    color: o.gold; opacity: 0.8
                }
            }
        }
    }

    Island {
        id: brightIsland
        onLeft: true
        glyph: "☀"
        caption: "LUX"
        value: o.bright < 0 ? 0 : o.bright / o.brightMax
    }
    Island {
        id: volIsland
        onLeft: false
        glyph: o.volMuted ? "✕" : "♪"
        caption: "VOL"
        value: o.vol
        muted: o.volMuted
    }
}
