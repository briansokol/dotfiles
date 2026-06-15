#!/usr/bin/env bash
# awww (formerly swww) wallpaper setter / random cycler.
# Usage: wallpaper.sh [init|next]
DIR="$HOME/Pictures/wallpapers"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/current-wallpaper"

mapfile -t papers < <(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)
[ "${#papers[@]}" -eq 0 ] && exit 0

pick="${papers[RANDOM % ${#papers[@]}]}"

case "$1" in
  init)
    awww-daemon 2>/dev/null &
    sleep 0.3
    last=$(cat "$STATE" 2>/dev/null)
    [ -f "$last" ] && pick="$last"
    ;;
esac

awww img "$pick" \
  --transition-type grow \
  --transition-pos 0.95,0.05 \
  --transition-duration 1.2 \
  --transition-fps 60
echo "$pick" > "$STATE"
