#!/usr/bin/env bash
# Rofi clipboard history via cliphist.
cliphist list | rofi -dmenu -p "Clipboard" -display-columns 2 | cliphist decode | wl-copy
