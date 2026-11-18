-- Common input configuration

hl.config({
    input = {
        kb_layout = "jp",
        follow_mouse = 1,
        sensitivity = 0,
    },
})

-- Workspace swipe feel
--   Commit point = distance * cancel_ratio (finger travel needed to switch)
--   default: 300 * 0.5 = 150  ->  now: 250 * 0.3 = 75 (half the travel)
hl.config({
    gestures = {
        workspace_swipe_distance = 250,          -- screen moves 1.2x per finger travel
        workspace_swipe_cancel_ratio = 0.15,     -- commit after 30% of the way
        workspace_swipe_min_speed_to_force = 20, -- a light flick also commits
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
