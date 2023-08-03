local defaultColor = colors.white


--[[ Color ]]--
local function resetColor()
    term.setTextColor(defaultColor)
end
local function changeColor(v)
    term.setTextColor(v)
end


--[[ Cursor ]]--
local function resetCursor()
    term.setCursorPos(1,1)
end


--[[ Special ]]--
local function errorr(message)
    changeColor(colors.red)
    print(message)
    resetColor()
end
local function askInput()
    resetColor()
    write("> ")
end
local function press2Continue(text)
    text = text or "to continue"
    changeColor(colors.gray)
    write("[[Press any key "..text.."...]]")
    read("")
end
local function clear()
    term.clear()
    resetCursor()
end
local function manualretry()
    press2Continue("to retry")
end

--[ Write ]--
local function splitWrite(tbltext,tblcolors,skipline)
    if Utils ~= nil then skipline = Utils.ternary(skipline == nil, true, skipline) end
    for i, text in ipairs(tbltext) do
        local color = tblcolors[i]
        if color then
            changeColor(color)
        else
            changeColor(colors.white)
        end
        write(text)
    end
    if skipline then
        print()
    end
    resetColor()
end


--[ scrolling ]--
local function scrollingEvents()
    while true do
        local _, dir, _, _ = os.pullEvent("mouse_scroll")
        term.scroll(dir)
    end
end



return {
    resetColor = resetColor,
    changeColor = changeColor,
    splitWrite = splitWrite,

    resetCursor = resetCursor,
    press2Continue = press2Continue,
    manualretry = manualretry,
    scrollingEvents = scrollingEvents,

    clear = clear,

    errorr = errorr,
    askInput = askInput
}