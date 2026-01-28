--[[
    Dashboard module for the startup screen.
]]

local stdio = require("@lune/stdio")

local Dashboard = {}

local LOGO = {
    "   __         _         ",
    "  / /  __ __ (_) __ _  ",
    " / /__/ // / / / /  ' \\ ",
    "/____/\\_,_/ /_/ /_/_/_/ ",
    "                        ",
}

local OPTIONS = {
    { key = "f", label = "Find File", desc = "Ctrl+P or f" },
    { key = "n", label = "New File", desc = "i or n" },
    { key = "q", label = "Quit", desc = "Ctrl+Q or q" },
}

function Dashboard.render(width, height)
    local out = "\27[H\27[2J" -- Clear and move to 1,1
    
    -- Center vertically roughly
    local startY = math.floor(height / 4)
    for _ = 1, startY do
        out = out .. "\r\n"
    end
    
    -- Render Logo centered
    local logoWidth = #LOGO[1]
    local logoX = math.floor((width - logoWidth) / 2)
    for _, line in ipairs(LOGO) do
        out = out .. string.rep(" ", logoX) .. "\27[35m" .. line .. "\27[0m\r\n"
    end
    
    out = out .. "\r\n"
    
    -- Render Options
    for _, opt in ipairs(OPTIONS) do
        local labelStr = string.format("%s  %s", opt.label, opt.desc)
        local optX = math.floor((width - #labelStr - 10) / 2)
        out = out .. string.rep(" ", optX)
        out = out .. "\27[36m" .. opt.label .. "\27[0m"
        out = out .. string.rep(" ", 10)
        out = out .. "\27[90m" .. opt.desc .. "\27[0m"
        out = out .. "\r\n\r\n"
    end
    
    -- Fill remaining space
    local currentLines = startY + #LOGO + (#OPTIONS * 2) + 1
    for _ = currentLines, height - 2 do
        out = out .. "\r\n"
    end
    
    -- Footer
    local footer = "unstable pre-release"
    local footerX = math.floor((width - #footer) / 2)
    out = out .. string.rep(" ", footerX) .. "\27[90m" .. footer .. "\27[0m"
    
    stdio.write(out)
end

return Dashboard
