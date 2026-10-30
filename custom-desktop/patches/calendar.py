#!/usr/bin/env python3
"""Make the iris side-panel calendar use the desktop widget's events.

Usage: calendar.py <Ryoku's IrisSidebarSection.qml> <output>

Applies four exact edits. If any anchor is missing (Ryoku changed the file),
exits 1 and writes nothing, so apply.sh falls back to Ryoku's own file.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

EDITS = [
    # Reach the shared desktop-calendar store.
    ("import Ryoku.Ui.Singletons as RyokuUi\n",
     "import Ryoku.Ui.Singletons as RyokuUi\nimport shell.services as RyokuSvc\n"),
    # Merge its events into every day lookup (list, dots, month grid).
    ("""                Events.list; CalendarSync.events
                return Events.getAllEventsForDate(date)
                    .concat(CalendarSync.getEventsForDate(date))""",
     """                Events.list; CalendarSync.events; RyokuSvc.Events.events
                // Shared desktop-calendar store (~/.local/state/ryoku/events.json),
                // mapped onto the iris entry shape.
                const key = Qt.formatDate(date, "yyyy-MM-dd")
                const shared = RyokuSvc.Events.forDate(key).map(e => {
                    const hm = (e.time || "00:00").split(":")
                    return { title: e.text, allDay: !e.time, ryokuId: e.id,
                        startDate: new Date(date.getFullYear(), date.getMonth(), date.getDate(), Number(hm[0]), Number(hm[1])) }
                })
                return Events.getAllEventsForDate(date)
                    .concat(CalendarSync.getEventsForDate(date))
                    .concat(shared)"""),
    # Shared events can be removed from the panel too.
    ("""                        visible: entryRow.local
                        materialIcon: "close"
                        iconSize: Math.round(15 * root.d)
                        Accessible.name: Translation.tr("Remove event")
                        onClicked: Events.removeEvent(entryRow.modelData.id)""",
     """                        visible: entryRow.local || entryRow.modelData.ryokuId !== undefined
                        materialIcon: "close"
                        iconSize: Math.round(15 * root.d)
                        Accessible.name: Translation.tr("Remove event")
                        onClicked: entryRow.modelData.ryokuId !== undefined
                            ? RyokuSvc.Events.remove(entryRow.modelData.ryokuId)
                            : Events.removeEvent(entryRow.modelData.id)"""),
    # New events from the panel go to the shared store.
    ("""                    Events.addEvent(title, "", when.toISOString(), "general", "normal", eventSheet.reminder, "none")""",
     """                    // Write to the shared store so the desktop calendar widget sees it too.
                    RyokuSvc.Events.add(Qt.formatDate(when, "yyyy-MM-dd"), "", Qt.formatTime(when, "HH:mm"), "", title)"""),
]

for old, new in EDITS:
    if s.count(old) != 1:
        sys.stderr.write("calendar.py: anchor not found:\n" + old[:80] + "\n")
        sys.exit(1)
    s = s.replace(old, new)

open(out, "w").write(s)
