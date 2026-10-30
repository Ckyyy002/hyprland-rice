// unlock-reveal: the desktop half of the lock screen transitions.
//
// The lock surface hides the desktop until it closes, so the qylock theme
// hands off to this resident overlay instead:
//   lockIn - Super+L: a dark curtain rises from the bottom, then the lock starts
//   arm    - on Enter: raise a full gold-wash cover (unseen, under the lock)
//   go     - on success: slow shine, then a circle opens from the centre
//   cancel - on a wrong password: drop the cover
// The cover never takes input, and disarms itself if "go" never comes.
//
// Lives in ~/.config/custom-desktop (Ryoku does not manage it). Run with:
//   qs -p ~/.config/custom-desktop/unlock-reveal -d
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property color gold: "#c9a063"
    property bool shown: false
    property real shine: 0      // 0..1 sweep of the light band
    property real radius: 0     // hole radius, 0 = fully covered
    property real curtain: 0    // lock-in: 0 = below the screen, 1 = covering it
    property bool curtainShown: false

    // Lock-in: a dark curtain rises from the bottom, then the real lock starts
    // on top of it. The curtain drops away underneath once the lock is up.
    function lockIn(): void {
        if (curtainAnim.running) return
        root.cancel()
        root.curtain = 0
        root.curtainShown = true
        curtainAnim.restart()
    }

    SequentialAnimation {
        id: curtainAnim
        NumberAnimation { target: root; property: "curtain"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
        ScriptAction { script: Quickshell.execDetached(["ryoku-shell", "lock"]) }
        PauseAnimation { duration: 2500 }
        ScriptAction { script: root.curtainShown = false }
    }

    function arm(): void {
        reveal.stop()
        root.radius = 0
        root.shine = 0
        root.shown = true
        armTimeout.restart()
    }
    function cancel(): void {
        reveal.stop()
        armTimeout.stop()
        root.shown = false
    }
    function go(): void {
        if (!root.shown) root.arm()
        armTimeout.stop()
        reveal.restart()
    }

    // An armed cover with no verdict (lock crashed, PAM hung) goes away on its own.
    Timer { id: armTimeout; interval: 15000; onTriggered: root.cancel() }

    SequentialAnimation {
        id: reveal
        // Slow shine across the gold wash.
        NumberAnimation { target: root; property: "shine"; from: 0; to: 1; duration: 900; easing.type: Easing.InOutSine }
        // Then the circle opens from the centre.
        NumberAnimation { target: root; property: "radius"; from: 0; to: 1; duration: 950; easing.type: Easing.InOutCubic }
        ScriptAction { script: root.shown = false }
    }

    IpcHandler {
        target: "reveal"
        function arm(): void { root.arm() }
        function go(): void { root.go() }
        function cancel(): void { root.cancel() }
        function lockIn(): void { root.lockIn() }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.shown || root.curtainShown
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "unlock-reveal"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            readonly property real cx: width / 2
            readonly property real cy: height / 2
            // Enough to clear the corners, plus the soft edge.
            readonly property real maxR: Math.sqrt(cx * cx + cy * cy) + 80
            readonly property real r: root.radius * maxR

            // Lock-in curtain: dark panel with a gold leading edge, rising from below.
            Item {
                visible: root.curtainShown
                width: win.width; height: win.height
                y: (1 - root.curtain) * win.height
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#0d0a06" }
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                }
                Rectangle {
                    width: parent.width; height: 2; color: root.gold
                    opacity: 1 - root.curtain * 0.6
                }
                Rectangle {
                    width: parent.width; height: 120; y: -120
                    opacity: 0.35 * (1 - root.curtain)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: root.gold }
                    }
                }
            }

            // Gold wash with a circular hole (odd-even: the circle punches through).
            Shape {
                anchors.fill: parent
                visible: root.shown
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillRule: ShapePath.OddEvenFill
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: 0; y2: win.height
                        GradientStop { position: 0.0; color: "#000000" }
                        GradientStop { position: 0.5; color: Qt.darker(root.gold, 1.6) }
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                    PathRectangle { x: 0; y: 0; width: win.width; height: win.height }
                    PathAngleArc { centerX: win.cx; centerY: win.cy; radiusX: win.r; radiusY: win.r; startAngle: 0; sweepAngle: 360 }
                }
            }

            // Shine: a soft diagonal light band sweeping across.
            Rectangle {
                visible: root.shown
                width: win.width * 0.35; height: win.height * 2.2
                anchors.verticalCenter: parent.verticalCenter
                x: -width + (win.width + width * 2) * root.shine - width / 2
                rotation: 18
                opacity: root.radius > 0 ? 0 : 0.55 * Math.sin(Math.PI * root.shine)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.lighter(root.gold, 1.5) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Glowing rim on the opening circle.
            Shape {
                anchors.fill: parent
                visible: root.shown && root.radius > 0
                opacity: 1 - root.radius
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: root.gold; strokeWidth: 3; fillColor: "transparent"
                    PathAngleArc { centerX: win.cx; centerY: win.cy; radiusX: win.r; radiusY: win.r; startAngle: 0; sweepAngle: 360 }
                }
            }
        }
    }
}
