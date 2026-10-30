#!/usr/bin/env python3
"""The iris bars stay above the desktop while a desktop widget takes typing.

Usage: irisbar.py <inir/modules/iris/bar/IrisBar.qml> <output>

A focused desktop text field lifts the wallpaper-painting widgets layer into
Top, the bars' own layer, where it stacks over them. While that screen's
Stage.GlobalStates.widgetTypingOwner is set, the chassis goes to Overlay.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    ("""import shell.services as Ryoku
""",
     """import shell.services as Ryoku
import stage as Stage
"""),
    ("""                onOverlaidChanged: if (!barWindow.overlaid) GlobalStates.irisChassisEpoch++
                WlrLayershell.layer: barWindow.overlaid || cardFrameLayer.framed ? WlrLayer.Overlay : WlrLayer.Top
""",
     """                onOverlaidChanged: if (!barWindow.overlaid) GlobalStates.irisChassisEpoch++
                // Custom (irisbar.py): above the desktop layer while a desktop widget is typing.
                readonly property bool desktopTyping: String(Stage.GlobalStates.widgetTypingOwner || "")
                    .indexOf((barWindow.screen?.name ?? "") + "|") === 0
                onDesktopTypingChanged: if (!barWindow.desktopTyping) GlobalStates.irisChassisEpoch++
                WlrLayershell.layer: barWindow.overlaid || cardFrameLayer.framed || barWindow.desktopTyping
                    ? WlrLayer.Overlay : WlrLayer.Top
"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("irisbar.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
