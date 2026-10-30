#!/usr/bin/env python3
"""The Timers bubble's progress ring fills while a timer runs.

Usage: timerring.py <IrisBubbleFace.qml> <output>

Ryoku draws a ring on the Timers ("tools") bubble but only computes the
timer's progress for the activity ("timer") face, so that ring stayed empty.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    ("""    readonly property real timerProgress: root.kind !== "timer" ? 0 : root.timerKind === "pomodoro"
""",
     """    // Custom (timerring.py): the Timers bubble's ring uses this too.
    readonly property real timerProgress: root.kind !== "timer" && root.kind !== "tools" ? 0 : root.timerKind === "pomodoro"
"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("timerring.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
