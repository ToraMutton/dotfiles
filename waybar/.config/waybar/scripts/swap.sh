#!/bin/bash

# Swap between transparent and background waybar styles
# 透明モード ↔ 背景付きモードを切り替え

config_dir="${HOME}/.config/waybar"
style_file="${config_dir}/style.css"
style_background_file="${config_dir}/style-background.css"

# Swap style files
mv "${style_file}" "${style_file}.temp"
mv "${style_background_file}" "${style_file}"
mv "${style_file}.temp" "${style_background_file}"

echo "Style swapped successfully!"

# Restart waybar
pkill waybar
sleep 0.3
waybar &
