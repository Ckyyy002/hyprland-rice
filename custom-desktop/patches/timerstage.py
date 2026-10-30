#!/usr/bin/env python3
"""The floating Timers bubble only shows while a timer is running.

Usage: timerstage.py <IrisStage.qml> <output>

It stays visible in edit mode so it can still be dragged into place.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    ("""        const kind = slot.slice(6)
        return IrisPieces.available(kind) ? kind : ""
""",
     """        const kind = slot.slice(6)
        // Custom (timerstage.py): Timers bubble only while a timer runs.
        if (kind === "tools" && !GlobalStates.irisEdit && !(TimerService.countdownRunning
                || TimerService.pomodoroRunning || TimerService.stopwatchRunning)) return ""
        return IrisPieces.available(kind) ? kind : ""
"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("timerstage.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
