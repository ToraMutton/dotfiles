-- Dell 14 Plus DB14250 (rigel-14)

hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@90",
    position = "0x0",
    scale = 1.6,
})

for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "eDP-1",
        default = i == 1,
    })
end
