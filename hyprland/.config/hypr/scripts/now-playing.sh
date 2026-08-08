#!/usr/bin/env bash
# Now-playing line for hyprlock.
# Prints "artist - title" (or just the title when there's no artist, e.g. YouTube),
# or a single space when nothing is playing so hyprlock doesn't fall back to its
# built-in "Sample Text" placeholder.

case "$(playerctl status 2>/dev/null)" in
  Playing|Paused) ;;
  *) printf ' '; exit 0 ;;
esac

title=$(playerctl metadata xesam:title 2>/dev/null)
artist=$(playerctl metadata xesam:artist 2>/dev/null)

[ -z "$title" ] && { printf ' '; exit 0; }

if [ -n "$artist" ]; then
  line="$artist - $title"
else
  line="$title"
fi

printf '%s' "${line:0:60}"
