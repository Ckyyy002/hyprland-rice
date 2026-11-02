#!/usr/bin/env python3
"""The workspace dots under the island's workspace number go in number order.

Usage: wsdots.py <IrisBubbleFace.qml> <output>

Hyprland lists workspaces in the order they were created (e.g. 3, 1, 4, 2), and
Ryoku drew the dots in that order, so the lit dot was in the wrong place.
Runs after timerring.py.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

old = "            readonly property var list: (WorkspaceService.allWorkspaces ?? []).filter(ws => ws.output === root.screenName)\n"
new = ("            readonly property var list: (WorkspaceService.allWorkspaces ?? []).filter(ws => ws.output === root.screenName)\n"
       "                .sort((a, b) => Number(a.idx) - Number(b.idx))\n")
if s.count(old) != 1:
    sys.stderr.write("wsdots.py: anchor not found\n")
    sys.exit(1)

open(out, "w").write(s.replace(old, new))
