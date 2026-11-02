#!/usr/bin/env python3
"""A lightly blurred wallpaper behind the desktop notes pad (Ryoku's is clear).

Usage: notesblur.py <NotesWidget.qml> <output>

Runs after notes.py. Needs notesglass.py on Desktop.qml, which hands the pad
the wallpaper copy it blurs (the same one the glass calendar uses).
BLUR is 0..1 (1 = as frosted as the glass calendar). Change it and run
~/.config/custom-desktop/apply.sh.
"""
import sys

BLUR = 0.45

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()


def swap(old, new):
    global s
    if s.count(old) != 1:
        sys.stderr.write(f"notesblur.py: anchor not found: {old.strip()[:50]}\n")
        sys.exit(1)
    s = s.replace(old, new)


swap("import Quickshell.Io\n", "import Quickshell.Io\nimport Quickshell.Widgets\nimport QtQuick.Effects\n")

swap("    property int hLogical: 180                // Config.notesHeight\n",
     "    property int hLogical: 180                // Config.notesHeight\n"
     "    property Item wallpaperSource: null       // custom-desktop: wallpaper copy to blur\n"
     "    property rect wallpaperRect: Qt.rect(0, 0, 0, 0)\n")

blur = f"""    // custom-desktop (notesblur.py): the wallpaper behind the pad, lightly blurred.
    ClippingRectangle {{
        id: frost
        anchors.fill: parent
        radius: 18 * root.s
        color: "transparent"
        visible: root.wallpaperSource !== null && !Performance.blurDisabled
        readonly property real bleed: 36 * root.s
        readonly property rect src: root.wallpaperRect
        readonly property real cx: Math.max(0, src.x - bleed)
        readonly property real cy: Math.max(0, src.y - bleed)
        readonly property real cr: root.wallpaperSource ? Math.min(root.wallpaperSource.width, src.x + width + bleed) : 0
        readonly property real cb: root.wallpaperSource ? Math.min(root.wallpaperSource.height, src.y + height + bleed) : 0
        ShaderEffectSource {{
            id: frostCrop
            x: frost.cx - frost.src.x
            y: frost.cy - frost.src.y
            width: Math.max(1, frost.cr - frost.cx)
            height: Math.max(1, frost.cb - frost.cy)
            sourceItem: root.wallpaperSource
            sourceRect: Qt.rect(frost.cx, frost.cy, width, height)
            live: frost.visible
            hideSource: true
            recursive: false
            smooth: true
            visible: false
        }}
        MultiEffect {{
            x: frostCrop.x
            y: frostCrop.y
            width: frostCrop.width
            height: frostCrop.height
            source: frostCrop
            autoPaddingEnabled: false
            blurEnabled: true
            blur: {BLUR}
            blurMax: 64
            blurMultiplier: 1.2
        }}
    }}

    Rectangle {{
        anchors.fill: parent
        radius: 18 * root.s
        color: Qt.rgba(root.plateInk.r, root.plateInk.g, root.plateInk.b, 0.26)
"""
swap("""    Rectangle {
        anchors.fill: parent
        radius: 18 * root.s
        color: Qt.rgba(root.plateInk.r, root.plateInk.g, root.plateInk.b, 0.26)
""", blur)

open(out, "w").write(s)
