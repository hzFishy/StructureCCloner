local cb_y
local ccolor1,ccolor2
local lcb_x, lcb_y

local function addBar(percent,color1,color2)
    percent = math.floor(percent)
    if percent < 0 then
        percent = 0
    elseif percent > 100 then
        percent = 100
    end
    local function round(x)
      return math.floor(x+.5)
    end
    local divideRate = 2
    term.setTextColor(color1)
    term.setBackgroundColor(colors.black)
    for i = 1, round(percent/divideRate) do
        term.write("\133")
    end
    term.setTextColor(color2)
    for i = 1, round(100/divideRate)-round(percent/divideRate) do
        term.write("\133")
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    print("")
end

local function updateBar(percent)
    lcb_x, lcb_y = term.getCursorPos()
    term.setCursorPos(0,cb_y)
    term.clearLine(cb_y)
    addBar(percent,ccolor1,ccolor2)
    term.setCursorPos(lcb_x,lcb_y)
end

local function initBar(initcolor1,initcolor2,initpercent)
    ccolor1,ccolor2 = initcolor1,initcolor2
    initpercent = initpercent or 0
    _,cb_y = term.getCursorPos()
    lcb_x, lcb_y = term.getCursorPos()
    addBar(initpercent,ccolor1,ccolor2)
end

return {
    addBar = addBar,
    updateBar = updateBar,
    initBar = initBar
}