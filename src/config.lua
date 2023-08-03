local config = {
    noLogging = true,
    detailedLogging = false,

    turtle = {
        initposition = vector.new(
            0,
            0,
            0
        ),
        initfacing = "x",
    },

    scan = {
        placeholderBlockIfEmpty = "minecraft:air",
        scanfilepreffix = "GuestUser",
        autoupload = false,
        removeMCNamespace = true,
        showIndexs = false,
        fuelSlots = {1,2,3},
        fuelChest =  vector.new(
            0,
            0,
            0
        ),
        dropoff = false,
        dropoffChest = vector.new(
            0,
            0,
            0
        )
    },

    build = {
        fuelSlots = {1,2,3},
        fuelChest =  vector.new(
            0,
            0,
            0
        ),
        ressourceChestModem = vector.new(
            0,
            0,
            0
        ),
        ressourceChestType = "minecraft:chest"
    },

    dependencies = {
        DiscordHook = {
            enable = false,
            webhook = ""
        }
    }
}

-- DO NOT EDIT THE FOLLOWING !!!
---@type table
local tr = {config = config}
for k, v in pairs(config) do
    tr[k] = v
end
return tr