#!/usr/bin/env python3
"""Make iris's Do Not Disturb actually stop banners.

Usage: dnd.py <Ryoku's inir/services/Notifications.qml> <output>

Iris's DND button flips its own `silent` flag, but the banners come from
Ryoku's notification service, which only checks Ryoku's DND flag (Flags.dnd).
This mirrors every change of `silent` into Flags.dnd, so either switch works.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

old = """    onSilentChanged: {
        if (root.silent !== Config.getNestedValue("notifications.silent", false))
            Config.setNestedValue("notifications.silent", root.silent);
    }"""
new = """    onSilentChanged: {
        if (root.silent !== Config.getNestedValue("notifications.silent", false))
            Config.setNestedValue("notifications.silent", root.silent);
        // Ryoku's notification server gates banners on its own DND flag.
        Ryoku.Flags.dnd = root.silent;
    }"""
if s.count(old) != 1 or "import shell.services as Ryoku" not in s:
    sys.stderr.write("dnd.py: anchor not found\n")
    sys.exit(1)

open(out, "w").write(s.replace(old, new))
