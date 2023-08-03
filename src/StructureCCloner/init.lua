Config = require "config"
Utils = require "modules.utils"
Term = require "modules.term"
Completion = require "cc.completion"
Depend = require "modules.external"

local movement = require "modules.movement"
local inventory = require "modules.inventory"

Utils.clearLogs()
local selffilename = "main"
Utils.logtoFile(selffilename,"CONFIG LOADED: "..textutils.serialise(Config.config))

local potentialError = Depend.checkUp()
if potentialError  then
    Term.errorr("Error was found when checking dependencies !")
    Term.errorr(potentialError)
end

movement.initSpawnCoords(Config.turtle.initposition) -- Initial coords of the turtle before any movement
movement.initSpawnFacing(Config.turtle.initfacing) -- Initial facing direction of the turtle before any movement

Term.clear()
Term.splitWrite({"Welcome to ","Structure","CC","loner"," !"},{nil,colors.lime,colors.yellow,colors.lime,nil})


local function run()
    local allModes = {
        scan = { mode = (require "modules.mapping.scan"), desc = "Scans a volume using two vectors"},
        build = { mode = (require "modules.mapping.build"), desc = "Builds from a scan file"}
    }

    local modenames = {}
    local selected = false
    local redo = true
    while (not selected) or redo do
        Term.changeColor(colors.orange)
        print("Select a mode from the list below:")
        print("=======")

        for k, value in pairs(allModes) do
            table.insert(modenames, k)
            Term.splitWrite({"- ",k," | Desc: ",value.desc},{colors.lightGray,colors.purple,colors.lightGray,colors.lightBlue})
        end

        Term.changeColor(colors.orange)
        print("=======")
        Term.askInput()

        local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, modenames) end)," ","")))

        for _, value in ipairs(modenames) do
            if value == ans then
                term.clear()
                Term.resetCursor()
                Term.changeColor(colors.green)

                parallel.waitForAny(allModes[value].mode.init,inventory.inventoryEvents)
                inventory.stopinventoryEvents()

                selected = true
                Term.changeColor(colors.cyan)
                print("Do something else ?")
                Term.askInput()
                ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, {"yes","no"}) end)," ","")))
                if ans == "yes" then
                    Term.clear()
                    redo = true
                else
                    redo = false
                end
            end
        end
        if not selected then
            Term.clear()
            Term.changeColor(colors.red)
            print("Please enter an existing Module")
        end
    end
    Term.changeColor(colors.blue)
    print("See you soon !")
end

local function mainEvents()
    parallel.waitForAny(run,Term.scrollingEvents)
end
mainEvents()