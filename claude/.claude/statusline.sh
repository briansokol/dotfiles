#!/usr/bin/env bash
input=$(cat)

five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
raw_model=$(echo "$input" | jq -r '.model.display_name // .model // empty' 2>/dev/null)

segment() {
  local label="$1" val="$2"
  [ -z "$val" ] && return
  printf '%s: %.0f%%' "$label" "$val"
}

out=""
append() {
  [ -z "$1" ] && return
  [ -n "$out" ] && out="$out | $1" || out="$1"
}

caveman_text=""
caveman_flag="$HOME/.claude/.caveman-active"
if [ -f "$caveman_flag" ]; then
  caveman_mode=$(cat "$caveman_flag" 2>/dev/null)
  if [ "$caveman_mode" = "full" ] || [ -z "$caveman_mode" ]; then
    caveman_text=$'\033[38;5;172m[CAVEMAN]\033[0m'
  else
    caveman_suffix=$(echo "$caveman_mode" | tr '[:lower:]' '[:upper:]')
    caveman_text=$'\033[38;5;172m[CAVEMAN:'"${caveman_suffix}"$']\033[0m'
  fi
fi

append "$raw_model"
append "$(segment "5h" "$five_h")"
append "$(segment "7d" "$seven_d")"
append "$(segment "Ctx" "$ctx")"
append "$(segment "$caveman_text")"

echo "$out"
