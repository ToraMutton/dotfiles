-- Workspace configuration

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
