local config = {
    noLogging = false,
    detailedLogging = true,

    turtle = {
        initposition = vector.new(
            -2,
            4,
            -1
        ),
        initfacing = "x",
    },

    scan = {
        placeholderBlockIfEmpty = "minecraft:air",
        scanfilepreffix = "hzFishy",
        autoupload = false,
        removeMCNamespace = true,
        showIndexs = false,
        fuelSlots = {1,2,3},
        fuelChest =  vector.new(
            -1,
            4,
            -3
        ),
        dropoff = true,
        dropoffChest = vector.new(
            1,
            4,
            -3
        )
    },

    build = {
        fuelSlots = {1,2,3},
        fuelChest =  vector.new(
            -1,
            4,
            -3
        ),
        ressourceChestModem = vector.new(
            3,
            4,
            -3
        ),
        ressourceChestType = "minecraft:chest"
    },

    dependencies = {
        DiscordHook = {
            enable = true,
            webhook = "https://discord.com/api/webhooks/1132792570343338126/6CAMVpe3DGeZbPB-oBB5F7pIbcHSwJtJ6pceerKGzu1Cq0rz0xvWYefDIWbStUDizzsy"
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