#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha powerline style.
# Reads session JSON on stdin, prints a single colored line.
# Requires a Nerd Font in your terminal.

input=$(cat)

# Catppuccin Mocha — truecolor ANSI
BG_ROSEWATER='\033[48;2;245;224;220m'
BG_FLAMINGO='\033[48;2;242;205;205m'
BG_PINK='\033[48;2;245;194;231m'
BG_MAUVE='\033[48;2;203;166;247m'
BG_RED='\033[48;2;243;139;168m'
BG_MAROON='\033[48;2;235;160;172m'
BG_PEACH='\033[48;2;250;179;135m'
BG_YELLOW='\033[48;2;249;226;175m'
BG_GREEN='\033[48;2;166;227;161m'
BG_TEAL='\033[48;2;148;226;213m'
BG_SKY='\033[48;2;137;220;235m'
BG_SAPPHIRE='\033[48;2;116;199;236m'
BG_BLUE='\033[48;2;137;180;250m'
BG_LAVENDER='\033[48;2;180;190;254m'
BG_TEXT='\033[48;2;205;214;244m'
BG_SUBTEXT1='\033[48;2;186;194;222m'
BG_SUBTEXT0='\033[48;2;166;173;200m'
BG_OVERLAY2='\033[48;2;147;153;178m'
BG_OVERLAY1='\033[48;2;127;132;156m'
BG_OVERLAY0='\033[48;2;108;112;134m'
BG_SURFACE2='\033[48;2;88;91;112m'
BG_SURFACE1='\033[48;2;69;71;90m'
BG_SURFACE0='\033[48;2;49;50;68m'
BG_BASE='\033[48;2;30;30;46m'
BG_MANTLE='\033[48;2;24;24;37m'
BG_CRUST='\033[48;2;17;17;27m'

FG_ROSEWATER='\033[38;2;245;224;220m'
FG_FLAMINGO='\033[38;2;242;205;205m'
FG_PINK='\033[38;2;245;194;231m'
FG_MAUVE='\033[38;2;203;166;247m'
FG_RED='\033[38;2;243;139;168m'
FG_MAROON='\033[38;2;235;160;172m'
FG_PEACH='\033[38;2;250;179;135m'
FG_YELLOW='\033[38;2;249;226;175m'
FG_GREEN='\033[38;2;166;227;161m'
FG_TEAL='\033[38;2;148;226;213m'
FG_SKY='\033[38;2;137;220;235m'
FG_SAPPHIRE='\033[38;2;116;199;236m'
FG_BLUE='\033[38;2;137;180;250m'
FG_LAVENDER='\033[38;2;180;190;254m'
FG_TEXT='\033[38;2;205;214;244m'
FG_SUBTEXT1='\033[38;2;186;194;222m'
FG_SUBTEXT0='\033[38;2;166;173;200m'
FG_OVERLAY2='\033[38;2;147;153;178m'
FG_OVERLAY1='\033[38;2;127;132;156m'
FG_OVERLAY0='\033[38;2;108;112;134m'
FG_SURFACE2='\033[38;2;88;91;112m'
FG_SURFACE1='\033[38;2;69;71;90m'
FG_SURFACE0='\033[38;2;49;50;68m'
FG_BASE='\033[38;2;30;30;46m'
FG_MANTLE='\033[38;2;24;24;37m'
FG_CRUST='\033[38;2;17;17;27m'

BOLD='\033[1m'
RESET='\033[0m'

# Nerd Font glyphs
SEP=$''         # right rounded cap
CAP_L=$''       # left rounded cap
CAP_R=$''       # right rounded cap
ICON_DIR=$''    # folder
ICON_BRANCH=$''  # git branch
ICON_MODEL=$'󰍛'    # chip
ICON_5H=$''     # clock
ICON_7D=$''     # calendar
ICON_CTX=$'󰆅'    # context window
ICON_COST=$''   # dollar

# Extract all fields in one jq pass (unit separator handles empties)
IFS=$'\x1f' read -r DIR MODEL FIVE_H SEVEN_D CTX COST < <(
  echo "$input" | jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // .model // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.context_window.used_percentage // ""),
    (.cost.total_cost_usd // "")
  ] | join("")'
)

DIR_NAME=""
[ -n "$DIR" ] && DIR_NAME=$(basename "$DIR")

GIT_BRANCH=""
if [ -n "$DIR" ]; then
  GIT_BRANCH=$(git -C "$DIR" symbolic-ref --short -q HEAD 2>/dev/null \
    || git -C "$DIR" describe --tags --exact-match 2>/dev/null \
    || git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
fi

# Pick BG|FG colors for a percentage (0-100).
pct_color() {
  local n
  n=$(printf '%.0f' "$1" 2>/dev/null) || n=0
  if   [ "$n" -ge 80 ]; then printf '%s|%s' "$BG_PEACH"  "$FG_PEACH"
  elif [ "$n" -ge 50 ]; then printf '%s|%s' "$BG_YELLOW" "$FG_YELLOW"
  else                       printf '%s|%s' "$BG_GREEN"  "$FG_GREEN"
  fi
}

LINE=""
LAST_FG=""

# Append a segment; uses left cap on the first segment, powerline arrow otherwise.
append_segment() {
  local bg="$1" fg="$2" content="$3"
  if [ -z "$LAST_FG" ]; then
    LINE="${RESET}${fg}${CAP_L}${bg}${FG_BASE}${BOLD}${content}"
  else
    LINE="${LINE}${LAST_FG}${bg}${SEP}${FG_BASE}${BOLD} ${content}"
  fi
  LAST_FG="$fg"
}

[ -n "$DIR_NAME"   ] && append_segment "$BG_BLUE"     "$FG_BLUE"     "${ICON_DIR} ${DIR_NAME}"
[ -n "$GIT_BRANCH" ] && append_segment "$BG_SAPPHIRE" "$FG_SAPPHIRE" "${ICON_BRANCH} ${GIT_BRANCH}"
[ -n "$MODEL"      ] && append_segment "$BG_MAUVE"    "$FG_MAUVE"    "${ICON_MODEL} ${MODEL}"

add_pct() {
  local icon="$1" pct="$2"
  [ -z "$pct" ] && return
  local n; n=$(printf '%.0f' "$pct" 2>/dev/null) || n=0
  IFS='|' read -r bg fg <<<"$(pct_color "$pct")"
  append_segment "$bg" "$fg" "${icon} ${n}%"
}

add_pct "$ICON_CTX" "$CTX"
add_pct "$ICON_5H"  "$FIVE_H"
add_pct "$ICON_7D"  "$SEVEN_D"

if [ -n "$COST" ] && awk -v c="$COST" 'BEGIN { exit !(c+0 > 0) }'; then
  COST_FMT=$(awk -v c="$COST" 'BEGIN { printf "%.4f", c+0 }')
  append_segment "$BG_TEAL" "$FG_TEAL" "${ICON_COST} ${COST_FMT}"
fi

# Right rounded cap
[ -n "$LAST_FG" ] && LINE="${LINE}${RESET}${LAST_FG}${CAP_R}${RESET}"

printf '%b\n' "$LINE"
