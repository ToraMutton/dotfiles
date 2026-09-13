-- Desktop PC (trapezium-08)

hl.monitor({
    output = "HDMI-A-1",
    mode = "2560x1440@75",
    position = "0x0",
    scale = 1,
    transform = 1,
})

hl.monitor({
    output = "DP-2",
    mode = "2560x1440@180",
    position = "1440x560",
    scale = 1,
})

for i = 1, 5 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "DP-2",
        default = i == 1,
    })
end

for i = 6, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "HDMI-A-1",
        default = i == 6,
    })
end

hl.config({
    input = {
        touchpad = {
            natural_scroll = false,
        },
    },
})
