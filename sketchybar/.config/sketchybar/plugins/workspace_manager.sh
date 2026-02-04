#!/bin/bash

# Get focused workspace from event payload
FOCUSED_WORKSPACE="${FOCUSED_WORKSPACE:-}"

# If no focused workspace provided, query it
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Get non-empty workspaces
NON_EMPTY=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)

# Combine focused + non-empty workspaces (focused should always show even if empty)
# Sort with numbers first (reversed), then letters (reversed)
ALL_WORKSPACES=$(echo -e "${NON_EMPTY}\n${FOCUSED_WORKSPACE}" | grep -v '^$' | sort -u)
NUMBERS=$(echo "$ALL_WORKSPACES" | grep '^[0-9]' | sort -rn)
LETTERS=$(echo "$ALL_WORKSPACES" | grep '^[^0-9]' | sort -r)
ACTIVE_WORKSPACES=$(echo -e "${LETTERS}\n${NUMBERS}" | grep -v '^$')

# Get currently displayed workspace items
CURRENT_ITEMS=$(sketchybar --query bar 2>/dev/null | jq -r '.items[]? // empty' | grep '^space\.' | sed 's/^space\.//')

# Remove workspace items that are no longer active
for item in $CURRENT_ITEMS; do
    if ! echo "$ACTIVE_WORKSPACES" | grep -q "^${item}$"; then
        sketchybar --remove "space.${item}" 2>/dev/null
    fi
done

# Define styling constants (matching spaces.sh)
RED=0xffed8796
CONFIG_DIR="$HOME/.config/sketchybar"

# Add new active workspaces that aren't displayed yet
for workspace in $ACTIVE_WORKSPACES; do
    if ! echo "$CURRENT_ITEMS" | grep -q "^${workspace}$"; then
        # Add new workspace item with same styling as original
        sketchybar --add item "space.${workspace}" left \
            --subscribe "space.${workspace}" aerospace_workspace_change \
            --set "space.${workspace}" \
                icon="${workspace}" \
                icon.padding_left=22 \
                icon.padding_right=22 \
                label.padding_right=33 \
                icon.highlight_color=$RED \
                background.color=0x44ffffff \
                background.corner_radius=5 \
                background.height=30 \
                background.drawing=off \
                label.font="sketchybar-app-font:Regular:16.0" \
                label.background.height=30 \
                label.background.drawing=on \
                label.background.color=0xff494d64 \
                label.background.corner_radius=9 \
                label.drawing=off \
                click_script="aerospace workspace ${workspace}" \
                script="$CONFIG_DIR/plugins/workspace_manager.sh" 2>/dev/null
    fi
done

# Reorder all workspace items to maintain sorted order
# Iterate through sorted list and position each before the previous
PREV=""
for workspace in $ACTIVE_WORKSPACES; do
    if [ -n "$PREV" ]; then
        # Only move if both items exist
        if sketchybar --query "space.${workspace}" &>/dev/null && sketchybar --query "space.${PREV}" &>/dev/null; then
            sketchybar --move "space.${workspace}" before "space.${PREV}" 2>/dev/null
        fi
    fi
    PREV="$workspace"
done

# Update highlights for all active workspaces
for workspace in $ACTIVE_WORKSPACES; do
    if [ "$workspace" = "$FOCUSED_WORKSPACE" ]; then
        sketchybar --set "space.${workspace}" background.drawing=on 2>/dev/null
    else
        sketchybar --set "space.${workspace}" background.drawing=off 2>/dev/null
    fi
done
