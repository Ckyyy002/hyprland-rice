#!/usr/bin/env python3
"""Put custom-desktop settings back into Ryoku's settings store after a reset.

Usage: restore_settings.py <settings.json>

Reads ~/.config/ryoku/shell.json and, for each entry whose current value is
missing or equal to Ryoku's default, writes ours through the ryoku-shell
daemon (`settings.patch`, the same call the Hub uses). A value you changed
yourself is left alone. Prints one line per setting it restores.
"""
import json, os, socket, sys

home = os.path.expanduser("~")
conf = json.load(open(sys.argv[1]))
store = os.path.join(os.environ.get("XDG_CONFIG_HOME", home + "/.config"), "ryoku/shell.json")
sock = os.path.join(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "ryoku-shell.sock")

try:
    current = json.load(open(store))
except Exception:
    current = {}

def lookup(path):
    node = current
    for seg in path.split("."):
        if not isinstance(node, dict) or seg not in node:
            return None
        node = node[seg]
    return node

def expand(v):
    if isinstance(v, str) and v.startswith("~/"):
        return home + v[1:]
    return v

def patch(path, value):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(5)
    s.connect(sock)
    s.sendall(("call settings.patch " + json.dumps({"path": path, "value": value, "id": "cd"}) + "\n").encode())
    reply = json.loads(s.recv(4096).decode().splitlines()[0])
    s.close()
    return reply.get("ok") is True

for entry in conf["settings"]:
    path, value, default = entry["path"], expand(entry["value"]), entry["default"]
    now = lookup(path)
    if "check" in entry:
        # Objects: judge by one field (e.g. enable) instead of the whole object.
        key = entry["check"]
        now = None if not isinstance(now, dict) else now.get(key)
        mine = value.get(key)
        reset = now is None or (now != mine and now == (default or {}).get(key, False if isinstance(mine, bool) else None))
    else:
        reset = now is None or (now == default and now != value)
    if not reset:
        continue
    try:
        ok = patch(path, value)
    except Exception as e:
        print(f"settings: could not reach ryoku-shell for {path} ({e})")
        continue
    print(f"settings: restored {path}" if ok else f"settings: ryoku-shell refused {path}")
