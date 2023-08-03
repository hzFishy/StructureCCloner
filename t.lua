local t = {
    1,2,3,4,5,6,7,8,9,10
}

local text = "downloading "
local endtext = "/"..#t

local function init()
    print(text.."0"..endtext)
end

local x,y = term.getCursorPos()
init()
local function update(i)
    term.setCursorPos(x,y)
    print(text..i..endtext)
end

for index, _ in ipairs(t) do
    update(index)
    sleep(1)
end
