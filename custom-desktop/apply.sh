#!/usr/bin/env bash
# apply.sh: keep your desktop customizations in place across Ryoku updates.
#
# Run at every login by ~/Scripts/BootUp.sh, and safe to run by hand any time:
#     ~/.config/custom-desktop/apply.sh
#
# Idempotent: it only writes when something is missing. If an update changed a
# file so much that a patch no longer fits, it skips that patch and logs it,
# leaving Ryoku's file alone rather than breaking the shell.
#
# What it keeps:
#   1. Notification banners: one banner, not two (iris draws its own).
#      Patches your fork in ~/.config/ryoku/user_edits.
#   2. Forks kept fresh: Ryoku's newest file + a patch in patches/, rebuilt
#      whenever Ryoku ships a new version, so they never go stale:
#        - calendar.py: Shima/iris right-panel calendar uses the desktop events.
#        - notes.py:    smaller text on the desktop notes pad.
#        - osd.py:      no bottom volume/brightness box while iris shows its own.
#        - dnd.py:      iris's Do Not Disturb also stops the banners.
#        - btleft.py:   Bluetooth bubble on the left of the island, like Wi-Fi.
#        - timerisland.py + timerstage.py: a running timer gets its own bubble
#                       instead of replacing the music bubble.
#        - timerring.py: that bubble's progress ring fills as the timer runs.
#        - toolsclock.py: its card shows the time left, with pause and stop.
#        - islandrest.py: volume/brightness popups no longer merge the tray bubble.
#        - notestyping.py + irisbar.py: typing in a desktop note no longer
#                       hides the bars.
#   4. Settings (settings.json) and the timer ringtone, put back after a reset.
#   3. Lock screen theme r1999-2 (sleep, animations, timer, clock layout).
#      Restored from the backup here if the theme gets reinstalled; while your
#      edits are present, the backup is refreshed from them instead.
# Log: ~/.local/state/custom-desktop.log

DIR="$HOME/.config/custom-desktop"
LOG="$HOME/.local/state/custom-desktop.log"
SHIPPED=/usr/share/ryoku/config/quickshell
OVERLAY="$HOME/.config/ryoku/user_edits/quickshell"
LIVE="$HOME/.config/quickshell"
mkdir -p "$(dirname "$LOG")" "$DIR/state"

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }
reload=0

# Copy an overlay fork onto the live tree if they differ.
sync_live() {
    local rel="$1"
    if ! cmp -s "$OVERLAY/$rel" "$LIVE/$rel"; then
        cp "$OVERLAY/$rel" "$LIVE/$rel"
        reload=1
    fi
}

# --- 1. Single notification banner ------------------------------------------------

notif() {
    local rel=shell/modules/notifications/NotificationPopups.qml
    local f="$OVERLAY/$rel"
    [ -f "$f" ] || return 0   # no fork: Ryoku's own file already has the fix
    if ! grep -q 'styleOwnsBanners' "$SHIPPED/shell/services/Config.qml"; then
        log "notif: Ryoku no longer has Config.styleOwnsBanners; skipped"
        return 0
    fi
    if ! grep -q '!Config.styleOwnsBanners' "$f"; then
        if grep -q '^    visible: mapped && Config.barStyle !== "nacre"$' "$f"; then
            sed -i 's/^    visible: mapped && Config.barStyle !== "nacre"$/    visible: mapped \&\& Config.barStyle !== "nacre" \&\& !Config.styleOwnsBanners/' "$f"
            log "notif: re-applied single-banner fix to your fork"
        else
            log "notif: visibility line changed in your fork; skipped"
            return 0
        fi
    fi
    sync_live "$rel"
}

# --- 2. Forks rebuilt from Ryoku's newest file + a patch script -----------------

# forked_patch <name> <path under quickshell/> <patch script>...
# Keeps a fork in user_edits = Ryoku's current file + the patch. Rebuilt whenever
# Ryoku ships a new version of the file (tracked by hash), and also when the
# patch script itself changes. If the patch no longer fits, the fork is dropped
# so the shell runs Ryoku's own, working file.
forked_patch() {
    local name="$1" rel="$2"; shift 2
    local scripts=() s
    for s in "$@"; do scripts+=("$DIR/patches/$s"); done
    local base="$SHIPPED/$rel" fork="$OVERLAY/$rel" stamp="$DIR/state/$name.sha256"
    [ -f "$base" ] || { log "$name: Ryoku file missing; skipped"; return 0; }
    local hash
    hash=$(cat "$base" "${scripts[@]}" | sha256sum | cut -d' ' -f1)
    if [ ! -f "$fork" ] || [ "$(cat "$stamp" 2>/dev/null)" != "$hash" ]; then
        mkdir -p "$(dirname "$fork")"
        # Several scripts chain: each one patches the previous one's output.
        local ok=1
        cp "$base" "$fork.new"
        for s in "${scripts[@]}"; do
            python3 "$s" "$fork.new" "$fork.step" && mv "$fork.step" "$fork.new" || { ok=0; break; }
        done
        if [ "$ok" = 1 ]; then
            mv "$fork.new" "$fork"
            echo "$hash" > "$stamp"
            log "$name: rebuilt fork from Ryoku's current file"
        else
            rm -f "$fork.new" "$fork.step"
            log "$name: patch no longer fits Ryoku's file; using Ryoku's version"
            if [ -f "$fork" ]; then rm -f "$fork" "$stamp"; cp "$base" "$LIVE/$rel"; reload=1; fi
            return 0
        fi
    fi
    sync_live "$rel"
}

# --- 3. Lock screen theme ---------------------------------------------------------

theme() {
    local live="$HOME/.local/share/qylock/themes/r1999-2" backup="$DIR/qylock/r1999-2"
    [ -d "$backup" ] || return 0
    [ -d "$live" ] || { log "theme: r1999-2 is not installed; skipped"; return 0; }
    local f
    if [ -f "$live/QsTimer.qml" ] && grep -q 'QsReveal.qml' "$live/Main.qml" 2>/dev/null; then
        # Our edits are still there: the live theme is the newest, so the
        # backup follows it (your own later edits are kept, never reverted).
        for f in Main.qml QsReveal.qml QsTimer.qml; do
            if ! cmp -s "$live/$f" "$backup/$f"; then
                cp "$live/$f" "$backup/$f"
                log "theme: backed up your edited $f"
            fi
        done
    else
        # Theme was reinstalled (our files gone): put them back.
        for f in Main.qml QsReveal.qml QsTimer.qml; do cp "$backup/$f" "$live/$f"; done
        log "theme: restored your r1999-2 lock screen files"
    fi
    return 0
}

# --- 4. Settings and the timer ringtone ----------------------------------------

# Puts back the ringtone file and the settings in settings.json, but only those
# a reset sent back to Ryoku's default; anything changed in Settings is kept.
settings() {
    local snd="$HOME/.local/share/sounds/custom/timer-gong.ogg"
    if [ ! -f "$snd" ] && [ -f "$DIR/sounds/timer-gong.ogg" ]; then
        mkdir -p "$(dirname "$snd")"; cp "$DIR/sounds/timer-gong.ogg" "$snd"
        log "settings: restored the timer ringtone"
    fi
    local line
    python3 -I "$DIR/restore_settings.py" "$DIR/settings.json" 2>&1 | while read -r line; do log "$line"; done
}

notif
forked_patch calendar inir/modules/iris/sidebar/IrisSidebarSection.qml calendar.py
forked_patch notes    shell/modules/desktop/notes/NotesWidget.qml       notes.py
forked_patch osd      shell/modules/osd/OsdWindow.qml                   osd.py
forked_patch dnd      inir/services/Notifications.qml                   dnd.py
forked_patch island   inir/modules/iris/bar/IrisIsland.qml             btleft.py timerisland.py islandrest.py
forked_patch stage    inir/modules/iris/stage/IrisStage.qml            timerstage.py
forked_patch face     inir/modules/iris/components/IrisBubbleFace.qml  timerring.py
forked_patch tools    inir/modules/iris/bar/IrisTools.qml              toolsclock.py
forked_patch desktop  shell/modules/desktop/Desktop.qml                notestyping.py
forked_patch irisbar  inir/modules/iris/bar/IrisBar.qml                irisbar.py
theme
settings

if [ $reload = 1 ]; then
    log "reloading the shell"
    ryoku-shell reload >/dev/null 2>&1
fi
exit 0
