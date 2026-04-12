#!/bin/bash

# Simple volume script for wpctl (PipeWire)
# Outputs JSON for waybar custom module

# Get volume percentage
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')

# Get mute status
muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")

if [ "$muted" = "MUTED" ]; then
    text="muted"
    alt="muted"
    class="muted"
    icon=""
else
    text="$vol%"
    class="unmuted"
    
    if [ "$vol" -ge 65 ]; then
        alt="high"
        icon=""
    elif [ "$vol" -ge 30 ]; then
        alt="medium"
        icon=""
    else
        alt="low"
        icon=""
    fi
fi

# Tooltip
desc=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep "node.description" | cut -d '"' -f 2)

# JSON Output
echo "{\"text\": \"$icon $text\", \"alt\": \"$alt\", \"tooltip\": \"Volume: $vol%\\nDevice: $desc\", \"class\": \"$class\", \"percentage\": $vol}"
