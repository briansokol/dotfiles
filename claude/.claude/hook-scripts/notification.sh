#!/bin/bash
# Claude Code notification hook
# Receives notification events from Claude Code and sends them to desktop
# Supports both Linux (notify-send) and macOS (osascript)

# Read JSON input from stdin
INPUT=$(cat)

# Parse title and message using jq
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification"')
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')

# Check which notification system is available
if command -v notify-send &> /dev/null; then
  # Linux: use notify-send
  # Set urgency based on notification type
  case "$NOTIFICATION_TYPE" in
    "permission_prompt")
      URGENCY="critical"
      ;;
    "idle_prompt")
      URGENCY="normal"
      ;;
    "auth_success")
      URGENCY="low"
      ;;
    *)
      URGENCY="normal"
      ;;
  esac

  notify-send --urgency="$URGENCY" "$TITLE" "$MESSAGE"
else
  # macOS: use osascript
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
fi

exit 0
