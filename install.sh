#!/usr/bin/env bash
# install.sh: put this rice on a Ryoku Linux desktop.
#
#   git clone https://github.com/Ckyyy002/hyprland-rice && cd hyprland-rice && ./install.sh
#
# Anything it would overwrite is backed up to ~/.local/state/hyprland-rice-backup-<date>/ first.
# Requires Ryoku (Hyprland edition): the patches apply on top of Ryoku's own shell files.
set -e
cd "$(dirname "$0")"

command -v ryoku >/dev/null || { echo "This rice patches Ryoku Linux's shell; ryoku was not found." >&2; exit 1; }

backup="$HOME/.local/state/hyprland-rice-backup-$(date +%F-%H%M%S)"
keep() { [ -e "$1" ] && { mkdir -p "$backup/$(dirname "${1#$HOME/}")"; cp -a "$1" "$backup/${1#$HOME/}"; }; return 0; }

keep "$HOME/.config/custom-desktop"
keep "$HOME/.config/hypr/user.lua"
keep "$HOME/Scripts/BootUp.sh"
keep "$HOME/Scripts/restore-config.sh"

mkdir -p "$HOME/.config/custom-desktop" "$HOME/Scripts" "$HOME/.config/hypr"
cp -a custom-desktop/. "$HOME/.config/custom-desktop/"
cp hypr/user.lua "$HOME/.config/hypr/user.lua"
cp scripts/BootUp.sh scripts/restore-config.sh "$HOME/Scripts/"
chmod +x "$HOME/Scripts/"*.sh "$HOME/.config/custom-desktop/apply.sh" "$HOME/.config/custom-desktop/sounds/get-gong.sh"

# The timer ringtone is downloaded, not shipped.
if command -v yt-dlp >/dev/null && command -v ffmpeg >/dev/null; then
    "$HOME/.config/custom-desktop/sounds/get-gong.sh" || echo "Could not download the gong; the timer uses Ryoku's default sound."
else
    echo "Install yt-dlp and ffmpeg, then run ~/.config/custom-desktop/sounds/get-gong.sh for the timer gong."
fi

# Installs the update watcher, applies every patch, restarts the lock overlay, reloads Hyprland.
bash "$HOME/Scripts/restore-config.sh"

[ -d "$backup" ] && echo "Your previous files are in $backup"
echo "Done."
