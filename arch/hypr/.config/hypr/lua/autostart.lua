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
    -- Re-sync the ai-usage overlay (~/.config/quickshell/caelestia) with the
    -- installed caelestia-shell before starting it, so package upgrades are
    -- picked up at login. If the sync fails the previous overlay is kept.
    hl.exec_cmd(
        '/usr/bin/env QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME=gtk3 ' ..
        'PATH="$HOME/.local/bin:$PATH" sh -c ' ..
        '"$HOME/Projects/caelestia-ai-usage/install.sh >/dev/null 2>&1; caelestia shell -d"'
    )
    hl.exec_cmd("fcitx5 -d")

    -- Discord IPC
    hl.exec_cmd("~/scripts/discord-ipc-link.sh")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist -max-items 20 store")
    hl.exec_cmd("wl-paste --type image --watch cliphist -max-items 20 store")
end)
