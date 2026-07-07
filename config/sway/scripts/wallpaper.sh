#!/bin/bash
# Cycle wallpapers in ~/Pictures/wallpaper and set them with swaybg (Wayland).
# Usage: wallpaper.sh [next|prev]   (no arg = set current/fallback)
set -e
WALL_DIR="$HOME/Pictures/wallpaper"
FALLBACK="$HOME/.config/wallpaper.jpg"
STATE="$HOME/.cache/sway-wallpaper-index"
mkdir -p "$(dirname "$STATE")"

set_wall() {
    local img="$1"
    pkill -x swaybg 2>/dev/null || true
    swaybg -i "$img" -m fill &
    disown
}

mapfile -t imgs < <(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) 2>/dev/null | sort)
if [ "${#imgs[@]}" -eq 0 ]; then
    [ -f "$FALLBACK" ] && set_wall "$FALLBACK"
    exit 0
fi

idx=0
[ -f "$STATE" ] && idx=$(cat "$STATE")
case "$1" in
    next) idx=$(( (idx + 1) % ${#imgs[@]} ));;
    prev) idx=$(( (idx - 1 + ${#imgs[@]}) % ${#imgs[@]} ));;
esac
echo "$idx" > "$STATE"
set_wall "${imgs[$idx]}"
