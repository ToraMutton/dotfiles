-- =============================================================================
-- Window rules
-- =============================================================================

-- Suppress maximize events for all windows
hl.window_rule({
    name = "suppress-maximize-events",

    match = {
        class = ".*",
    },

    suppress_event = "maximize",
})


-- Work around problematic XWayland drag windows
hl.window_rule({
    name = "fix-xwayland-drags",

    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },

    no_focus = true,
})


-- Hyprland runner
hl.window_rule({
    name = "move-hyprland-run",

    match = {
        class = "hyprland-run",
    },

    move = {
        20,
        "monitor_h-120",
    },

    float = true,
})


-- =============================================================================
-- Transparency
-- =============================================================================

-- Kitty
hl.window_rule({
    name = "glass-kitty",

    match = {
        class = "kitty",
    },

    opacity = "0.85 0.7",
})


-- VS Code / Antigravity
hl.window_rule({
    name = "glass-vscode",

    match = {
        class = "^(code|Code|antigravity|Antigravity)$",
    },

    opacity = "0.95 0.85",
})


-- Browsers
hl.window_rule({
    name = "glass-browser",

    match = {
        class = "^(vivaldi|Vivaldi|firefox|Firefox|chromium|Chromium|google-chrome|brave-browser)$",
    },

    opacity = "0.95 0.85",
})


-- =============================================================================
-- Layer rules
-- =============================================================================

-- Blur behind wofi
hl.layer_rule({
    name = "wofi_blur",

    match = {
        namespace = "wofi",
    },

    blur = true,
})
