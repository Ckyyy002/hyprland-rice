#!/usr/bin/env bash
# Downloads the timer ringtone (a gong from YouTube) into ~/.local/share/sounds/custom.
# Not shipped in the repo: it's someone else's audio. Needs yt-dlp and ffmpeg.
set -e
out="$HOME/.local/share/sounds/custom/timer-gong.ogg"
tmp=$(mktemp -d)
mkdir -p "$(dirname "$out")"
yt-dlp -q --no-playlist -x --audio-format wav -o "$tmp/src.%(ext)s" "https://www.youtube.com/watch?v=VaN5aiO3Qcg"
# Trim the silence at both ends and level the loudness.
ffmpeg -v error -y -i "$tmp/src.wav" \
    -af "silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-60dB,areverse,loudnorm=I=-14:TP=-1" \
    -ar 48000 -c:a libvorbis -q:a 6 "$out"
rm -rf "$tmp"
cp "$out" "$(dirname "$0")/timer-gong.ogg"
echo "saved $out"
