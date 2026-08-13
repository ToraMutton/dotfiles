-- =============================================================================
-- Environment variables
-- =============================================================================

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Japanese input (fcitx5) and Firefox Wayland support
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("MOZ_ENABLE_WAYLAND", "1")

hl.env("LANG", "ja_JP.UTF-8")

-- Chromium / Electron Wayland support
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NIXOS_OZONE_WL", "1")


-- =============================================================================
-- Autostart
-- =============================================================================

hl.on("hyprland.start", function()
    -- Desktop components
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("fcitx5 -d")

    -- Legacy wallpaper daemon
    -- TODO: remove after migration (swww has been replaced by awww)
    hl.exec_cmd("swww-daemon")

    -- Discord IPC
    hl.exec_cmd("~/scripts/discord-ipc-link.sh")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Wallpapers
    hl.exec_cmd(
        'mpvpaper -o "no-audio --loop" DP-2 ~/Pictures/wallpapers/kaguya.png'
    )

    hl.exec_cmd(
        'mpvpaper -o "no-audio --loop --panscan=1.0 --video-align-x=0.25" HDMI-A-1 ~/Pictures/wallpapers/moonflower.mp4'
    )
end)
