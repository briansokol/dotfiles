#!/usr/bin/env sh

sketchybar --add event aerospace_workspace_change

# Get initial active workspaces (non-empty + focused)
FOCUSED=$(aerospace list-workspaces --focused)
NON_EMPTY=$(aerospace list-workspaces --monitor all --empty no)
# Sort with numbers first (reversed), then letters (reversed)
ACTIVE=$(echo -e "$NON_EMPTY\n$FOCUSED" | grep -v '^$' | sort -u | (grep '^[0-9]' 2>/dev/null | sort -rn; grep '^[^0-9]' 2>/dev/null | sort -r) | uniq)

RED=0xffed8796
for sid in $ACTIVE; do
    sketchybar --add item "space.$sid" left \
        --subscribe "space.$sid" aerospace_workspace_change \
        --set "space.$sid" \
        icon="$sid"\
                              icon.padding_left=22                          \
                              icon.padding_right=22                         \
                              label.padding_right=33                        \
                              icon.highlight_color=$RED                     \
                              background.color=0x44ffffff \
                              background.corner_radius=5 \
                              background.height=30 \
                              background.drawing=off                         \
                              label.font="sketchybar-app-font:Regular:16.0" \
                              label.background.height=30                    \
                              label.background.drawing=on                   \
                              label.background.color=0xff494d64             \
                              label.background.corner_radius=9              \
                              label.drawing=off                             \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/workspace_manager.sh"
done
