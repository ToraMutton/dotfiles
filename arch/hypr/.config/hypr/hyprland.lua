-- =============================================================================
-- ToraMutton's Hyprland Configuration
-- =============================================================================

local hostname_file = assert(io.open("/etc/hostname", "r"))
local hostname = hostname_file:read("*l")
hostname_file:close()

local machine_modules = {
    ["rigel-14"] = "lua/machines/rigel-14",
    ["trapezium-08"] = "lua/machines/trapezium-08",
}

local machine_module = assert(
    machine_modules[hostname],
    "Unsupported hostname: " .. tostring(hostname)
)

require("lua/input")
require(machine_module)
require("lua/appearance")
require("lua/autostart")
require("lua/keybinds")
require("lua/windowrules")
