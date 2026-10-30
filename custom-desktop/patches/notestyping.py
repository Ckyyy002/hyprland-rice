#!/usr/bin/env python3
"""Typing in the desktop note publishes itself like other desktop text fields.

Usage: notestyping.py <shell/modules/desktop/Desktop.qml> <output>

While a note is focused the widgets layer lifts into the Top layer (to take the
keyboard) and, since it paints the wallpaper, covered the iris bars. Other
desktop text fields announce typing through Stage.GlobalStates.widgetTypingOwner;
the note did not. This makes it, so irisbar.py can lift the bars above it.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    ("""                onEditingChanged: win.kbWanted += editing ? 1 : -1
                Component.onDestruction: if (editing) win.kbWanted -= 1
                NotesWidget {
""",
     """                onEditingChanged: {
                    win.kbWanted += editing ? 1 : -1
                    // Custom (notestyping.py): announce note typing for the iris bars.
                    const tag = root.monitorName + "|notes"
                    if (editing) {
                        if (!Stage.GlobalStates.widgetTypingOwner) Stage.GlobalStates.widgetTypingOwner = tag
                    } else if (Stage.GlobalStates.widgetTypingOwner === tag) Stage.GlobalStates.widgetTypingOwner = ""
                }
                Component.onDestruction: {
                    if (editing) win.kbWanted -= 1
                    if (Stage.GlobalStates.widgetTypingOwner === root.monitorName + "|notes")
                        Stage.GlobalStates.widgetTypingOwner = ""
                }
                NotesWidget {
"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("notestyping.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
