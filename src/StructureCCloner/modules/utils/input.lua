-- Get the begin and End points vector coords
local function getInput(case)
    Term.splitWrite({case.." coordinate ","(format: x y z)"},{colors.cyan,colors.lightGray})
    Term.askInput()
    local input = read()
    local x, y, z = string.gmatch(input, "(%S+)%s+(%S+)%s+(%S+)")()

    if not x or not y or not z then
        Term.errorr("Invalid input. Please enter three numbers separated by spaces.")
        return getInput(case)
    else
        local res = vector.new(x,y,z)
        Term.changeColor(colors.purple)
        print(case.." vector coords is: "..res:tostring())
        return res*1
    end
end

return {
    vectorgetInput = getInput
}