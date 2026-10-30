#!/usr/bin/env python3
"""A running timer no longer takes the activity (music) bubble on the iris island.

Usage: timerisland.py <IrisIsland.qml> <output>

Only while the Timers bubble (extras.tools) floats on its own: the timer then
lives in that bubble, so the activity bubble keeps showing media.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    ("""        if (root.timerKind.length > 0) list.push("timer")
""",
     """        // Custom (timerisland.py): the floating Timers bubble carries the timer.
        if (root.timerKind.length > 0 && !root.floatsAlone("tools")) list.push("timer")
"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("timerisland.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
