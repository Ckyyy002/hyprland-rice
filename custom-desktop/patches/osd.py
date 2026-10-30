#!/usr/bin/env python3
"""Hide Ryoku's bottom volume/brightness OSD while the iris bar shows its own.

Usage: osd.py <Ryoku's OsdWindow.qml> <output>

Ryoku hides its OSD for the python and nomarchy bar styles but not for iris, so
with iris both the top-bar Island and the bottom box show. This adds iris to the
rule, following iris's own OSD switch (Iris settings: iris.modules.osd).
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

old = "        && !Config.styleOwnsFeedback\n"
new = ("        && !Config.styleOwnsFeedback\n"
       "        && !(Config.barStyle === \"iris\" && (Config.inir?.iris?.modules?.osd ?? true))\n")
if s.count(old) != 1:
    sys.stderr.write("osd.py: anchor not found\n")
    sys.exit(1)

open(out, "w").write(s.replace(old, new))
