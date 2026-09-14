-- Dell 14 Plus DB14250 (rigel-14)

hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
	    scroll_factor = 0.35,
        },
    },
})

hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@90",
    position = "1440x1560",
    scale = 1.6,
})

hl.monitor({
    output = "DP-1",
    mode = "2560x1440@59.95",
    position = "0x0",
    scale = 1,
    transform = 1,
})

for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "eDP-1",
        default = i == 1,
    })
end
