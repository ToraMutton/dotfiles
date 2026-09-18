-- Minimal Hyprland session dedicated to the Quickshell greeter on rigel-14.

hl.config({
    input = {
        kb_layout = "jp",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_hyprland_guiutils_check = true,
    },
})

hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@90",
    position = "0x0",
    scale = 1.6,
})

hl.on("hyprland.start", function()
    hl.exec_cmd(
        "/usr/bin/env " ..
        "NO_AT_BRIDGE=1 " ..
        "QT_ACCESSIBILITY=0 " ..
        "QT_LINUX_ACCESSIBILITY_ALWAYS_ON=0 " ..
        "/usr/bin/qs -p /etc/greetd/rigel-greeter; " ..
        "/usr/bin/hyprctl dispatch 'hl.dsp.exit()'"
    )
end)
