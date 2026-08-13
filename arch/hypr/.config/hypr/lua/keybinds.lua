-- =============================================================================
-- Program definitions
-- =============================================================================

local terminal = "kitty"
local fileManager = "dolphin"
local editor = "zeditor"
local mainMod = "SUPER"


-- =============================================================================
-- Application launch
-- =============================================================================

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(
    mainMod .. " + Space",
    hl.dsp.exec_cmd("caelestia shell drawers toggle launcher")
)
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(editor))

-- =============================================================================
-- System operations
-- =============================================================================

-- Close the active window
hl.bind(mainMod .. " + C", hl.dsp.window.close())

-- Exit Hyprland
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd(
        "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
    )
)

-- =============================================================================
-- Convenience
-- =============================================================================

-- Maximize while keeping gaps / bar
hl.bind(
    mainMod .. " + W",
    hl.dsp.window.fullscreen({ mode = "maximized" })
)

-- True fullscreen
hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.window.fullscreen({ mode = "fullscreen" })
)

-- Lock screen
hl.bind(
    mainMod .. " + L",
    hl.dsp.exec_cmd("caelestia shell lock lock")
)

-- Clipboard history
hl.bind(
    mainMod .. " + SHIFT + V",
    hl.dsp.exec_cmd(
        "cliphist list | wofi --dmenu | cliphist decode | wl-copy"
    )
)


-- =============================================================================
-- Window operations
-- =============================================================================

-- Toggle floating
hl.bind(
    mainMod .. " + V",
    hl.dsp.window.float({ action = "toggle" })
)

-- Toggle pseudotiling
hl.bind(
    mainMod .. " + P",
    hl.dsp.window.pseudo({ action = "toggle" })
)

-- Toggle dwindle split direction
hl.bind(
    mainMod .. " + J",
    hl.dsp.layout("togglesplit")
)

-- Focus windows
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))


-- =============================================================================
-- Workspaces
-- =============================================================================

for i = 1, 10 do
    -- Workspace 10 uses the physical "0" key
    local key = tostring(i % 10)
    local workspace = tostring(i)

    -- SUPER + number: switch workspace
    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = workspace })
    )

    -- SUPER + SHIFT + number:
    -- move active window and follow it
    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({
            workspace = workspace,
            follow = true,
        })
    )
end

-- Special workspace
hl.bind(
    mainMod .. " + grave",
    hl.dsp.workspace.toggle_special("magic")
)

-- =============================================================================
-- Window cycling
-- =============================================================================

hl.bind(
    mainMod .. " + Tab",
    hl.dsp.window.cycle_next()
)

hl.bind(
    mainMod .. " + SHIFT + Tab",
    hl.dsp.window.cycle_next({ next = false })
)


-- =============================================================================
-- Mouse controls
-- =============================================================================

-- Scroll through workspaces
hl.bind(
    mainMod .. " + mouse_down",
    hl.dsp.focus({ workspace = "e+1" })
)

hl.bind(
    mainMod .. " + mouse_up",
    hl.dsp.focus({ workspace = "e-1" })
)

-- Move / resize windows with the mouse
hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)


-- =============================================================================
-- Monitor controls
-- =============================================================================

-- Focus another monitor
hl.bind(
    mainMod .. " + comma",
    hl.dsp.focus({ monitor = "l" })
)

hl.bind(
    mainMod .. " + period",
    hl.dsp.focus({ monitor = "r" })
)

-- Move active window to another monitor
hl.bind(
    mainMod .. " + SHIFT + comma",
    hl.dsp.window.move({
        monitor = "l",
        follow = true,
    })
)

hl.bind(
    mainMod .. " + SHIFT + period",
    hl.dsp.window.move({
        monitor = "r",
        follow = true,
    })
)

-- Move current workspace to another monitor
hl.bind(
    mainMod .. " + CTRL + comma",
    hl.dsp.workspace.move({ monitor = "l" })
)

hl.bind(
    mainMod .. " + CTRL + period",
    hl.dsp.workspace.move({ monitor = "r" })
)


-- =============================================================================
-- Window resizing
-- =============================================================================

hl.bind(
    mainMod .. " + ALT + left",
    hl.dsp.window.resize({
        x = -50,
        y = 0,
        relative = true,
    })
)

hl.bind(
    mainMod .. " + ALT + right",
    hl.dsp.window.resize({
        x = 50,
        y = 0,
        relative = true,
    })
)

hl.bind(
    mainMod .. " + ALT + up",
    hl.dsp.window.resize({
        x = 0,
        y = -50,
        relative = true,
    })
)

hl.bind(
    mainMod .. " + ALT + down",
    hl.dsp.window.resize({
        x = 0,
        y = 50,
        relative = true,
    })
)


-- =============================================================================
-- Screenshots
-- =============================================================================

-- Quick region screenshot -> clipboard
hl.bind(
    mainMod .. " + S",
    hl.dsp.exec_cmd(
        "caelestia shell picker openFreezeClip"
    )
)

-- Region screenshot -> edit with Swappy
hl.bind(
    mainMod .. " + SHIFT + S",
    hl.dsp.exec_cmd(
        "caelestia screenshot -r -f"
    )
)

-- Current output
hl.bind(
    mainMod .. " + ALT + S",
    hl.dsp.exec_cmd(
        "caelestia screenshot"
    )
)

-- =============================================================================
-- Media keys
-- =============================================================================

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd(
        "brightnessctl -e4 -n2 set 5%+"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd(
        "brightnessctl -e4 -n2 set 5%-"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true }
)


-- =============================================================================
-- Window groups
-- =============================================================================

-- Toggle group
hl.bind(
    mainMod .. " + G",
    hl.dsp.group.toggle()
)

-- Remove active window from group
hl.bind(
    mainMod .. " + SHIFT + G",
    hl.dsp.window.move({ out_of_group = true })
)

-- Next tab in group
hl.bind(
    mainMod .. " + ALT + Tab",
    hl.dsp.group.next()
)


-- =============================================================================
-- Advanced window management
-- =============================================================================

hl.bind(
    mainMod .. " + SHIFT + left",
    hl.dsp.window.swap({ direction = "l" })
)

hl.bind(
    mainMod .. " + SHIFT + right",
    hl.dsp.window.swap({ direction = "r" })
)

hl.bind(
    mainMod .. " + SHIFT + up",
    hl.dsp.window.swap({ direction = "u" })
)

hl.bind(
    mainMod .. " + SHIFT + down",
    hl.dsp.window.swap({ direction = "d" })
)

-- Pin floating window
hl.bind(
    mainMod .. " + T",
    hl.dsp.window.pin()
)

-- Center window
hl.bind(
    mainMod .. " + SHIFT + C",
    hl.dsp.window.center()
)

-- Toggle floating
hl.bind(
    mainMod .. " + SHIFT + F",
    hl.dsp.window.float({ action = "toggle" })
)


-- =============================================================================
-- Utilities
-- =============================================================================

hl.bind(
    mainMod .. " + SHIFT + E",
    hl.dsp.exec_cmd(
        "caelestia shell drawers toggle session"
    )
)

hl.bind(
    mainMod .. " + D",
    hl.dsp.exec_cmd("hyprpicker -a")
)

-- Suspend
hl.bind(
    mainMod .. " + SHIFT + L",
    hl.dsp.exec_cmd("systemctl suspend")
)


-- =============================================================================
-- Keyboard media controls
-- =============================================================================

hl.bind(
    mainMod .. " + F10",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    mainMod .. " + F11",
    hl.dsp.exec_cmd(
        "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    mainMod .. " + F12",
    hl.dsp.exec_cmd(
        "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    ),
    {
        repeating = true,
        locked = true,
    }
)

hl.bind(
    mainMod .. " + SHIFT + P",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    mainMod .. " + SHIFT + bracketleft",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true }
)

hl.bind(
    mainMod .. " + SHIFT + bracketright",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true }
)
