#!/usr/bin/env python3
"""Bluetooth bubble on the LEFT of the iris island, mirroring the Wi-Fi bubble.

Usage: btleft.py <Ryoku's inir/modules/iris/bar/IrisIsland.qml> <output>

The Wi-Fi bubble is the island's trailing satellite, so it sits close to the
island without merging into it. The matching left satellite belongs to the
"activity" bubble (media, timer, recording). Whenever that one is not using the
spot (moved elsewhere, or idle), this shows Bluetooth there instead, with the
same gap, curve and click-to-open card.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    # When the left satellite is free for Bluetooth.
    ("""    readonly property bool leftSatelliteShown: root.leftSatelliteRest && !root.inlineExpanded
""",
     """    // Custom (btleft.py): Bluetooth takes the left satellite while the activity
    // bubble is placed elsewhere or has nothing to show.
    readonly property bool btLeading: IrisStyle.cluster && BluetoothStatus.available
        && (root.floatingSlots.includes("left") || root.primary === "idle")
    readonly property bool leftSatelliteShown: root.leftSatelliteRest && !root.inlineExpanded
"""),
    # Rest (and so show) the left satellite for Bluetooth too.
    ("""        && !root.floatingSlots.includes("left")
        && root.primary !== "idle"
""",
     """        && (root.btLeading || (!root.floatingSlots.includes("left")
        && root.primary !== "idle"))
"""),
    # The island does not also carry what the satellite shows.
    ("""        return root.leftSatelliteRest && kind === "media"
""",
     """        return root.leftSatelliteRest && kind === (root.btLeading ? "bluetooth" : "media")
"""),
    # No album-art handoff from a satellite that shows Bluetooth.
    ("""    readonly property Item restingCover: IrisStyle.cluster && leftSatellite.shown
""",
     """    readonly property Item restingCover: IrisStyle.cluster && leftSatellite.shown && !root.btLeading
"""),
    # What it shows and what a click does.
    ("""        slot: "left"
        leftSide: true
        kind: root.primary
        shown: root.leftSatelliteShown
        resting: root.leftSatelliteRest
        onActivated: {
            if (root.mediaBubbleCard)""",
     """        slot: "left"
        leftSide: true
        kind: root.btLeading ? "bluetooth" : root.primary
        shown: root.leftSatelliteShown
        resting: root.leftSatelliteRest
        onActivated: {
            if (root.btLeading) root.activateBubble("bluetooth", leftSatellite)
            else if (root.mediaBubbleCard)"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("btleft.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
