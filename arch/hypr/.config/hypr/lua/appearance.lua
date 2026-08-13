local scheme = require("scheme.current")

-- Appearance configuration

-- =============================================================================
-- General appearance
-- =============================================================================

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 14,
        border_size = 2,

        col = {
            active_border = {
                colors = {
                    "rgba(" .. scheme.primary .. "ee)",
                    "rgba(" .. scheme.tertiary .. "ee)",
                },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        rounding_power = 4,
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 8,
            render_power = 3,
            color = "rgba(1a1a1aaa)",
        },

        blur = {
            enabled = true,
            size = 10,
            passes = 3,
            vibrancy = 0.1696,
            noise = 0.02,
            contrast = 1.1,
            brightness = 0.9,
        },
    },
})

-- =============================================================================
-- Animation curves
-- =============================================================================

-- General-purpose Bezier curves

hl.curve("easeOutQuint", {
    type = "bezier",
    points = {
        { 0.23, 1 },
        { 0.32, 1 },
    },
})

hl.curve("quick", {
    type = "bezier",
    points = {
        { 0.15, 0 },
        { 0.1,  1 },
    },
})

-- Physical spring curves

hl.curve("workspaceSpring", {
    type = "spring",
    mass = 1,
    stiffness = 220,
    dampening = 20,
})

hl.curve("windowInSpring", {
    type = "spring",
    mass = 1,
    stiffness = 260,
    dampening = 22,
})

hl.curve("windowOutSpring", {
    type = "spring",
    mass = 1,
    stiffness = 300,
    dampening = 26,
})

hl.curve("windowMoveSpring", {
    type = "spring",
    mass = 1,
    stiffness = 240,
    dampening = 24,
})

-- =============================================================================
-- Global animation
-- =============================================================================

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 10,
    bezier = "default",
})

-- =============================================================================
-- Window animations
-- =============================================================================

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.79,
    bezier = "easeOutQuint",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4,
    spring = "windowInSpring",
    style = "popin 87%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    spring = "windowOutSpring",
    style = "popin 87%",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4,
    spring = "windowMoveSpring",
})

-- =============================================================================
-- Workspace animations
-- =============================================================================

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    spring = "workspaceSpring",
    style = "slidefade 20%",
})

-- =============================================================================
-- Layer animations
-- =============================================================================

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
    style = "fade",
})

-- =============================================================================
-- Fade animation
-- =============================================================================

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3,
    bezier = "quick",
})

-- =============================================================================
-- Visual feedback animations
-- =============================================================================

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})

-- =============================================================================
-- Layout / miscellaneous
-- =============================================================================

hl.config({
    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})
