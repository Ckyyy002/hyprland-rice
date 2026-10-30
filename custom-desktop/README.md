# custom-desktop

Your own desktop customizations, kept outside Ryoku's managed folders so a
system update can't delete them. Ryoku does not manage this folder
(`ryoku owner ~/.config/custom-desktop` says "user").

## What's here

| Path | What it is |
|---|---|
| `apply.sh` | Re-applies everything below if an update undid it. Runs at every login from `~/Scripts/BootUp.sh`. Safe to run by hand any time. |
| `unlock-reveal/shell.qml` | Lock screen animations on the desktop side: the Super+L curtain, and the gold shine + circle reveal after unlocking. |
| `patches/calendar.py` | Makes the Shima/iris right-panel calendar use the desktop widget's events. |
| `patches/notes.py` | Smaller text on the desktop notes pad (`SIZE = 10`; Ryoku's default is 15). |
| `patches/osd.py` | Hides Ryoku's bottom volume/brightness box while iris shows the level in the top bar. |
| `patches/dnd.py` | Iris's Do Not Disturb switch also turns on Ryoku's DND, so banners actually stop. |
| `patches/btleft.py` | Bluetooth bubble on the left of the island, same gap as the Wi-Fi bubble on the right. |
| `qylock/r1999-2/` | Backup of your lock screen theme edits (sleep button, animations, timer, clock layout). |
| `state/` | Bookkeeping for apply.sh. |

## How each one survives an update

- **Single notification banner**: your fork in
  `~/.config/ryoku/user_edits/quickshell/shell/modules/notifications/NotificationPopups.qml`
  gets the one-line fix. Ryoku lays user_edits over its files on every update.
- **Calendar**: a fork in user_edits, rebuilt from Ryoku's newest file each time
  Ryoku ships a new one, so it never goes stale. If Ryoku changes the file so
  much the patch no longer fits, apply.sh drops the fork and logs it, and you
  get Ryoku's normal calendar instead of a broken one.
- **Notes pad text size**: same as the calendar, a fork rebuilt from Ryoku's
  newest file + `patches/notes.py`. To change the size, edit `SIZE` there and
  run apply.sh.
- **Lock screen theme**: restored from `qylock/r1999-2/` if the theme is
  reinstalled from Ryostore.
- **Bottom OSD hidden**, **Do Not Disturb** and the **left Bluetooth bubble**: same
  as the calendar, forks rebuilt from Ryoku's newest file + `patches/osd.py`,
  `patches/dnd.py`, `patches/btleft.py`.
- **Keybinds**: in `~/.config/hypr/user.lua`, which Ryoku never overwrites. This
  includes the brightness-key hook that makes the iris top bar show brightness,
  and the rule that tiles Files (Nautilus) instead of floating it.
- **Update watcher**: `~/.config/systemd/user/custom-desktop.path` watches the
  Ryoku folders the patches live in and runs apply.sh ~15 s after an update
  rewrites them. Installed (and re-installed if missing) by
  `~/Scripts/restore-config.sh`.

## Commands

    bash ~/Scripts/restore-config.sh       restore everything after an update (one command)
    ~/.config/custom-desktop/apply.sh      re-apply now (after an update, no reboot needed)
    cat ~/.local/state/custom-desktop.log  what apply.sh changed or skipped

After you edit the lock screen theme, copy the files here too so apply.sh
doesn't put the old ones back:

    cp ~/.local/share/qylock/themes/r1999-2/{Main.qml,QsReveal.qml,QsTimer.qml} ~/.config/custom-desktop/qylock/r1999-2/

## Timer, bubbles, notes (2026-10-29)
Patches (rebuilt by apply.sh on every Ryoku update):
- timerisland.py + timerstage.py: a running timer gets its own Timers bubble (shown only while running) instead of taking the music bubble.
- timerring.py: the Timers bubble's progress ring fills.
- toolsclock.py: the Timers card shows time left, pause and stop.
- notestyping.py + irisbar.py: typing in a desktop note no longer hides the bars.
- islandrest.py: volume/brightness popups no longer merge the tray bubble into the island.

Settings and files (apply.sh `settings`, restore_settings.py):
- settings.json lists settings put back only when a reset returns them to Ryoku's
  default (timer sound on, gong ringtone, Timers bubble, Network bubble on the
  right of the clock). Change one in Settings and it is respected.
  To pin another setting, add an entry with its path, your value, and Ryoku's default.
- sounds/timer-gong.ogg: backup of the ringtone, copied back if it goes missing.
