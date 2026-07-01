#!/usr/bin/env bash
# Outputs waybar JSON with the count of pending official + AUR updates.
official=$(checkupdates 2>/dev/null | wc -l)
aur=$(command -v yay >/dev/null && yay -Qua 2>/dev/null | wc -l || echo 0)
total=$((official + aur))

if [ "$total" -eq 0 ]; then
  printf '{"text":"","tooltip":"System up to date","class":"updated"}\n'
else
  tooltip="$official official + $aur AUR updates"
  printf '{"text":"󰚰 %s","tooltip":"%s","class":"pending"}\n' "$total" "$tooltip"
fi
