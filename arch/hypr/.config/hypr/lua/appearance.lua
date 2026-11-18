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
            inactive_border = "rgba(" .. scheme.outlineVariant .. "aa)",
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

-- Design principles
--   * Duration tiers: 100 / 150 / 225 / 350 ms (geometric x1.5; time-perception
--     Weber fraction is ~10-20%, so neighbouring tiers stay distinguishable)
--   * Longer travel -> longer duration; exit is faster than enter
--   * Enter = decelerate (ease-out), exit = accelerate
--   * No overshoot on large (full-screen) or exit motion

-- General-purpose Bezier curves

hl.curve("easeOutQuint", {
    type = "bezier",
    points = {
        { 0.23, 1 },
        { 0.32, 1 },
    },
})

-- Material 3 motion tokens
hl.curve("standardDecel", {
    type = "bezier",
    points = {
        { 0, 0 },
        { 0, 1 },
    },
})

hl.curve("emphasizedDecel", {
    type = "bezier",
    points = {
        { 0.05, 0.7 },
        { 0.1,  1 },
    },
})

hl.curve("emphasizedAccel", {
    type = "bezier",
    points = {
        { 0.3, 0 },
        { 0.8, 0.15 },
    },
})

-- Physical spring curves
--   Parameterised by response T (s) and damping ratio zeta (mass = 1):
--     stiffness = (2*pi / T)^2
--     dampening = 4*pi * zeta / T
--   zeta = 1.0 -> no overshoot, smaller -> bouncier.
--   Springs are integrated in real time, so the leaf `speed` likely has no effect.

-- T=0.40s, zeta=1.00 | full-screen travel: longest tier, no bounce
--   t90 ~248ms, settle(2%) ~372ms
hl.curve("workspaceSpring", {
    type = "spring",
    mass = 1,
    stiffness = 247,
    dampening = 31.4,
})

-- T=0.32s, zeta=0.82 | enter: slight life (~1% overshoot)
--   t90 ~156ms, settle(2%) ~200ms
hl.curve("windowInSpring", {
    type = "spring",
    mass = 1,
    stiffness = 386,
    dampening = 32.2,
})

-- T=0.22s, zeta=1.00 | exit: faster than enter, no bounce
--   t90 ~137ms, settle(2%) ~205ms
hl.curve("windowOutSpring", {
    type = "spring",
    mass = 1,
    stiffness = 816,
    dampening = 57.1,
})

-- T=0.30s, zeta=0.90 | move: practically no overshoot, smooth on retarget
--   t90 ~163ms, settle(2%) ~225ms
hl.curve("windowMoveSpring", {
    type = "spring",
    mass = 1,
    stiffness = 439,
    dampening = 37.7,
})

-- =============================================================================
-- Global animation
-- =============================================================================

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 3.5, -- fallback: longest tier (350ms)
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
    speed = 4.4,
    spring = "workspaceSpring",
    style = "slide",
})

-- =============================================================================
-- Layer animations
-- =============================================================================

hl.animation({
    leaf = "layers",
    enabled = false,
})

-- =============================================================================
-- Fade animation
-- =============================================================================

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 1.5, -- 150ms: opacity change has no travel distance
    bezier = "standardDecel",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1, -- 100ms: exit is faster, accelerating away
    bezier = "emphasizedAccel",
})

-- =============================================================================
-- Visual feedback animations
-- =============================================================================

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 1.5, -- 150ms: focus feedback should feel near-instant
    bezier = "standardDecel",
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
