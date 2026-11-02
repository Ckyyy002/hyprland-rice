#!/usr/bin/env python3
"""Calendars start the week on Monday (your locale, en_US, says Sunday).

Usage: weekstart.py <Ryoku's file> <output>

One script for every calendar that reads the week start from the locale:
  shell/modules/desktop/calendar/CalendarWidget.qml   desktop calendar widget
  inir/modules/iris/sidebar/IrisSidebarSection.qml    iris right-panel calendar
  inir/modules/iris/widgets/IrisAgendaFace.qml        iris "upcoming" week strip
FIRST_DAY: 0 = Sunday, 1 = Monday, ... 6 = Saturday.
"""
import sys

FIRST_DAY = 1

ANCHORS = [
    ("    readonly property int firstDay: root.loc.firstDayOfWeek === 7 ? 0 : root.loc.firstDayOfWeek\n",
     f"    readonly property int firstDay: {FIRST_DAY}\n"),
    ("            readonly property int weekStart: Qt.locale().firstDayOfWeek % 7\n",
     f"            readonly property int weekStart: {FIRST_DAY}\n"),
    ("        const lead = (first.getDay() - Qt.locale().firstDayOfWeek + 7) % 7\n",
     f"        const lead = (first.getDay() - {FIRST_DAY} + 7) % 7\n"),
]

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

hits = [(old, new) for old, new in ANCHORS if s.count(old) == 1]
if len(hits) != 1:
    sys.stderr.write("weekstart.py: anchor not found\n")
    sys.exit(1)

old, new = hits[0]
open(out, "w").write(s.replace(old, new))
