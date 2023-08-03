local inventory = require "modules.inventory"

local selffilename = "building"


local function placeDown(slot)
    if not slot then
        if not inventory.selectSlotBlock() then
            Utils.logtoFile(selffilename,"placeDown()",nil, "couldn't be done because 'inventory.selectSlotBlock()' failed")
            return false
        end
    else
        turtle.select(slot)
    end

    Utils.logtoFile(selffilename,"placeDown()", "(item: "..(textutils.serialise(turtle.getItemDetail(turtle.getSelectedSlot())))..")","")
    local try = turtle.placeDown()
    if try then Utils.logtoFile(selffilename,"placeDown()",nil, "sucessful") else Utils.logtoFile(selffilename,"placeDown(), failed") end
    return try
end

local function remove(side)
    if side == "f" then
        turtle.dig()
    elseif side == "u" then
        turtle.digUp()
    elseif side == "d" then
        turtle.digDown()
    end
end

return {
    placeDown = placeDown,
    remove = remove
}