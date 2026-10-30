#!/usr/bin/env python3
"""Floating bubbles stop merging into the island during volume/brightness popups.

Usage: islandrest.py <IrisIsland.qml> <output>

Floating pieces merge into the island when its published shape reaches them.
Ryoku already holds back that shape while the island is open or morphing, but
not while it briefly widens for volume/brightness feedback or a short event,
so a nearby bubble (the tray) got absorbed for those seconds.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    ("""        if (name.length === 0 || root.expanded || root.morphing) return
        const next = root.islandGeometry
""",
     """        // Custom (islandrest.py): nor while it briefly widens for feedback or an event.
        if (name.length === 0 || root.expanded || root.morphing || root.feedback || root.eventShown) return
        const next = root.islandGeometry
"""),
    ("""    onIslandGeometryChanged: geometrySettle.restart()
""",
     """    onIslandGeometryChanged: geometrySettle.restart()
    onFeedbackChanged: if (!root.feedback) geometrySettle.restart()
    onEventShownChanged: if (!root.eventShown) geometrySettle.restart()
"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("islandrest.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
