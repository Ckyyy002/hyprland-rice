#!/usr/bin/env bash
# BootUp.sh: run at login (Hyprland start, from ~/.config/hypr/user.lua).
#
#   0. Re-applies your customizations if an update undid them (~/.config/custom-desktop/apply.sh).
#   1. Refreshes the lock screen animation overlay (~/.config/custom-desktop/unlock-reveal).
#   2. Cleans old cache files in the background (only things untouched for 30+ days).
#
# Run by hand any time:   ~/Scripts/BootUp.sh
# See what cleanup would remove, without deleting:   DRY_RUN=1 ~/Scripts/BootUp.sh
# Cleanup log: ~/.local/state/bootup.log

DAYS=30
REVEAL="$HOME/.config/custom-desktop/unlock-reveal"
LOG="$HOME/.local/state/bootup.log"
mkdir -p "$(dirname "$LOG")"

# --- 1. Lock screen animation overlay ------------------------------------------

refresh_overlay() {
    # Stop every running copy (there should be at most one).
    while qs -p "$REVEAL" kill >/dev/null 2>&1 && qs -p "$REVEAL" ipc show >/dev/null 2>&1; do
        sleep 0.2
    done

    qs -p "$REVEAL" -d >/dev/null 2>&1

    # Wait up to 10 s for it to answer, so a lock right after login still animates.
    for _ in $(seq 1 50); do
        if qs -p "$REVEAL" ipc show >/dev/null 2>&1; then
            echo "unlock-reveal: running"
            return 0
        fi
        sleep 0.2
    done
    echo "unlock-reveal: failed to start" >&2
    return 1
}

# --- 2. Cache cleanup -----------------------------------------------------------

# Delete files under $1 not modified in $DAYS days, then the empty folders left behind.
prune() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    local size
    size=$(find "$dir" -type f -mtime +"$DAYS" -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {printf "%.0f", s/1048576}')
    if [ -n "$DRY_RUN" ]; then
        echo "would free ${size} MB from $dir"
        return 0
    fi
    find "$dir" -type f -mtime +"$DAYS" -delete 2>/dev/null
    find "$dir" -mindepth 1 -type d -empty -delete 2>/dev/null
    echo "$(date '+%F %T') freed ${size} MB from $dir" >> "$LOG"
}

# Trash: remove items deleted more than $DAYS days ago (by their .trashinfo date).
prune_trash() {
    local trash="$HOME/.local/share/Trash"
    [ -d "$trash/info" ] || return 0
    local cutoff count=0
    cutoff=$(date -d "-$DAYS days" +%s)
    for info in "$trash"/info/*.trashinfo; do
        [ -e "$info" ] || continue
        local when name
        when=$(sed -n 's/^DeletionDate=//p' "$info")
        [ -n "$when" ] || continue
        [ "$(date -d "$when" +%s 2>/dev/null || echo "$cutoff")" -lt "$cutoff" ] || continue
        name=$(basename "$info" .trashinfo)
        count=$((count + 1))
        if [ -n "$DRY_RUN" ]; then
            echo "would empty from trash: $name"
        else
            rm -rf -- "$trash/files/$name" "$info"
        fi
    done
    [ -z "$DRY_RUN" ] && echo "$(date '+%F %T') emptied $count old item(s) from trash" >> "$LOG"
}

cleanup() {
    prune "$HOME/.cache/yay"
    prune "$HOME/.cache/paru"
    prune "$HOME/.cache/pip"
    prune "$HOME/.cache/thumbnails"
    prune_trash
}

# --- run ------------------------------------------------------------------------

if [ -n "$DRY_RUN" ]; then
    cleanup
    exit 0
fi

"$HOME/.config/custom-desktop/apply.sh"
refresh_overlay
# Low priority in the background so login stays fast.
( nice -n 19 ionice -c 3 bash -c "$(declare -f prune prune_trash cleanup); DAYS=$DAYS LOG='$LOG' cleanup" ) >/dev/null 2>&1 &
