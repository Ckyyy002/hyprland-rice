#!/usr/bin/env bash
# restore-config.sh: put all your desktop customizations back after a Ryoku update.
#
#     bash ~/Scripts/restore-config.sh
#
# Safe to run any time; it only changes what is missing. It:
#   1. Makes sure the update watcher is installed and running (so future
#      updates are fixed automatically, about 15 s after they finish).
#   2. Re-applies the patches and the lock screen theme (custom-desktop/apply.sh).
#   3. Restarts the lock/unlock animation overlay.
#   4. Reloads Hyprland so your keybinds in hypr/user.lua are active.
# Details: ~/.config/custom-desktop/README.md

CD="$HOME/.config/custom-desktop"
UNITS="$HOME/.config/systemd/user"
REVEAL="$CD/unlock-reveal"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

echo "Restoring desktop config..."

# --- 1. Update watcher ---------------------------------------------------------
mkdir -p "$UNITS"
cat > "$UNITS/custom-desktop.path" <<'EOF'
# Re-apply ~/.config/custom-desktop after a Ryoku update rewrites these folders.
# Installed by ~/Scripts/restore-config.sh.
[Unit]
Description=Watch Ryoku-managed folders for update rewrites

[Path]
PathChanged=%h/.config/quickshell/shell/modules/notifications
PathChanged=%h/.config/quickshell/inir/modules/iris/sidebar
PathChanged=%h/.config/quickshell/shell/modules/desktop/notes
PathChanged=%h/.config/quickshell/shell/modules/osd
PathChanged=%h/.config/quickshell/inir/services
PathChanged=%h/.config/quickshell/inir/modules/iris/bar
Unit=custom-desktop.service

[Install]
WantedBy=default.target
EOF
cat > "$UNITS/custom-desktop.service" <<'EOF'
# Started by custom-desktop.path. Waits for the update to finish writing, then
# re-applies the customizations (idempotent: does nothing if all is in place).
[Unit]
Description=Re-apply custom desktop tweaks after a Ryoku update

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 15
ExecStart=%h/.config/custom-desktop/apply.sh
EOF
systemctl --user daemon-reload
if systemctl --user enable --now custom-desktop.path >/dev/null 2>&1 \
        && systemctl --user is-active --quiet custom-desktop.path; then
    ok "update watcher running"
else
    warn "update watcher could not start (see: systemctl --user status custom-desktop.path)"
fi

# --- 2. Patches + lock screen theme -----------------------------------------------
if [ -x "$CD/apply.sh" ]; then
    out=$("$CD/apply.sh")
    if [ -n "$out" ]; then
        echo "$out" | sed 's/^[0-9-]* [0-9:]* /    /'
    fi
    ok "patches and lock screen theme in place"
else
    warn "$CD/apply.sh is missing; patches not applied"
fi

# --- 3. Lock / unlock animation overlay -----------------------------------------
while qs -p "$REVEAL" kill >/dev/null 2>&1 && qs -p "$REVEAL" ipc show >/dev/null 2>&1; do
    sleep 0.2
done
qs -p "$REVEAL" -d >/dev/null 2>&1
for _ in $(seq 1 50); do
    qs -p "$REVEAL" ipc show >/dev/null 2>&1 && break
    sleep 0.2
done
if qs -p "$REVEAL" ipc show >/dev/null 2>&1; then
    ok "lock screen animations running"
else
    warn "lock screen animation overlay failed to start"
fi

# --- Startup hook ------------------------------------------------------------------
# hypr/user.lua starts BootUp.sh at login; if that path is wrong, nothing runs at
# boot (no animations until this script is run by hand).
boot=$(grep -o 'exec_cmd("[^"]*BootUp.sh")' "$HOME/.config/hypr/user.lua" | sed 's/exec_cmd("//; s/")$//')
boot=${boot//\$HOME/$HOME}
if [ -n "$boot" ] && [ -x "$boot" ]; then
    ok "startup hook points to $boot"
else
    warn "hypr/user.lua does not start an existing BootUp.sh (found: ${boot:-nothing})"
fi

# --- 4. Keybinds -----------------------------------------------------------------------
if hyprctl reload >/dev/null 2>&1; then
    ok "keybinds reloaded"
else
    warn "could not reload Hyprland"
fi

echo "Done."
