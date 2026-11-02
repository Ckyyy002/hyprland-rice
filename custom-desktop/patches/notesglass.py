#!/usr/bin/env python3
"""Desktop.qml hands the notes pad the wallpaper copy it blurs (see notesblur.py).

Usage: notesglass.py <Desktop.qml> <output>

Runs after notestyping.py. Two changes: the wallpaper copy is also loaded while
the notes pad is shown, and the pad gets it plus its own position.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()


def swap(old, new):
    global s
    if s.count(old) != 1:
        sys.stderr.write(f"notesglass.py: anchor not found: {old.strip()[:50]}\n")
        sys.exit(1)
    s = s.replace(old, new)


swap("""                || (musicLoader.active && musicLoader.visible
                    && musicLoader.item !== null && Config.musicStyle === "glass"))
""", """                || (musicLoader.active && musicLoader.visible
                    && musicLoader.item !== null && Config.musicStyle === "glass")
                || (notesLoader.active && notesLoader.visible && notesLoader.item !== null))
""")

swap("""                    hLogical: root.widgetValue("notes", "Height")
                }
""", """                    hLogical: root.widgetValue("notes", "Height")
                    wallpaperSource: glassBackdrop
                    wallpaperRect: Qt.rect(notesSlot.x, notesSlot.y,
                        notesSlot.width, notesSlot.height)
                }
""")

open(out, "w").write(s)
