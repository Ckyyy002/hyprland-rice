#!/usr/bin/env python3
"""Smaller text on the desktop notes pad (the pad itself keeps its size).

Usage: notes.py <Ryoku's NotesWidget.qml> <output>

Text size is SIZE x the widget's scale (Ryoku's default is 15). Change SIZE
and run ~/.config/custom-desktop/apply.sh to apply.
"""
import sys

SIZE = 10

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

old = "            font.pixelSize: Math.round(15 * root.s)\n"
new = f"            font.pixelSize: Math.round({SIZE} * root.s)\n"
if s.count(old) != 1:
    sys.stderr.write("notes.py: anchor not found\n")
    sys.exit(1)

open(out, "w").write(s.replace(old, new))
