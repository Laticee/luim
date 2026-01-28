--[[
    Renderer module for terminal output.
]]

local stdio = require("@lune/stdio")

local Renderer = {}

-- ANSI Colors
local COLORS = {
    RESET = "\27[0m",
    BOLD = "\27[1m",
    BG_BLUE = "\27[44m",
    FG_CYAN = "\27[36m",
    FG_YELLOW = "\27[33m",
    FG_MAGENTA = "\27[35m",
    FG_GREEN = "\27[32m",
    FG_GRAY = "\27[90m",
    INVERT = "\27[7m",
}

function Renderer.clear()
    stdio.write("\27[2J\27[H")
end

function Renderer.moveCursor(row, col)
    return string.format("\27[%d;%dH", row, col)
end

local function highlight(line)
    -- Very basic syntax highlighting for Luau
    -- Keywords
    line = string.gsub(line, "%f[%w](local)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](function)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](return)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](if)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](then)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](else)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](end)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](for)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](while)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "%f[%w](do)%f[%w]", COLORS.FG_MAGENTA .. "%1" .. COLORS.RESET)
    
    -- Strings
    line = string.gsub(line, "(\".-\")", COLORS.FG_GREEN .. "%1" .. COLORS.RESET)
    line = string.gsub(line, "('.-')", COLORS.FG_GREEN .. "%1" .. COLORS.RESET)
    
    -- Comments
    line = string.gsub(line, "(%-%-.*)", COLORS.FG_GRAY .. "%1" .. COLORS.RESET)
    
    return line
end

function Renderer.renderBuffer(buffer, startRow, width, height, cursorRow, cursorCol, mode)
    local out = "\27[H" -- Move to 1,1
    local lineCount = buffer:getLineCount()
    
    -- Rows available for text (total height - 1 for status bar)
    local textRows = height - 1
    
    for i = 1, textRows do
        local bufferRow = startRow + i - 1
        out = out .. "\27[K" -- Clear line
        
        if bufferRow <= lineCount then
            local line = buffer:getLine(bufferRow)
            -- Simple horizontal trimming if line is too long
            if #line > width then
                line = string.sub(line, 1, width)
            end
            out = out .. highlight(line)
        else
            out = out .. COLORS.FG_GRAY .. "~" .. COLORS.RESET
        end
        out = out .. "\r\n"
    end
    
    -- Render status bar at the bottom
    out = out .. Renderer.renderStatusBar(height, width, cursorRow, cursorCol, mode)
    
    -- Final cursor placement
    out = out .. Renderer.moveCursor(cursorRow - startRow + 1, cursorCol)
    
    stdio.write(out)
end

function Renderer.renderStatusBar(row, width, cursorRow, cursorCol, mode)
    local modeColor = (mode == "INSERT") and COLORS.BG_BLUE or COLORS.INVERT
    local out = Renderer.moveCursor(row, 1)
    out = out .. modeColor .. "\27[K" -- Mode color + Clear line
    
    local modeStr = mode or "NORMAL"
    local statusLeft = string.format(" -- %s --  Line: %d, Col: %d", modeStr, cursorRow, cursorCol)
    local statusRight = "(Ctrl+P: Menu, Ctrl+S: Save, Ctrl+Q: Quit)"
    
    -- Fill with spaces for right alignment if possible
    local padding = width - #statusLeft - #statusRight
    if padding < 1 then padding = 1 end
    local status = statusLeft .. string.rep(" ", padding) .. statusRight
    
    -- Final trim if still too long for width
    if #status > width then
        status = string.sub(status, 1, width)
    end
    
    out = out .. status .. COLORS.RESET
    return out
end

return Renderer
