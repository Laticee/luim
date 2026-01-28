--[[
    Buffer class for managing text content.
]]

local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(lines)
    local self = setmetatable({}, Buffer)
    self.lines = lines or { "" }
    return self
end

function Buffer:getLine(idx)
    return self.lines[idx] or ""
end

function Buffer:getLineCount()
    return #self.lines
end

function Buffer:insertChar(row, col, char)
    if row > #self.lines then
        for i = #self.lines + 1, row do
            self.lines[i] = ""
        end
    end
    local line = self.lines[row]
    self.lines[row] = string.sub(line, 1, col - 1) .. char .. string.sub(line, col)
end

function Buffer:deleteChar(row, col)
    local line = self.lines[row]
    if not line or col < 1 or col > #line then return end
    self.lines[row] = string.sub(line, 1, col - 1) .. string.sub(line, col + 1)
end

function Buffer:insertLine(row, content)
    table.insert(self.lines, row, content or "")
end

function Buffer:deleteLine(row)
    if #self.lines > 1 then
        table.remove(self.lines, row)
    else
        self.lines[1] = ""
    end
end

function Buffer:splitLine(row, col)
    local line = self.lines[row]
    local left = string.sub(line, 1, col - 1)
    local right = string.sub(line, col)
    self.lines[row] = left
    table.insert(self.lines, row + 1, right)
end

function Buffer:mergeLines(row)
    if row >= #self.lines then return end
    local line1 = self.lines[row]
    local line2 = self.lines[row+1]
    self.lines[row] = line1 .. line2
    table.remove(self.lines, row + 1)
end

function Buffer:clampCursor(row, col, mode)
    local lineCount = #self.lines
    local clampedRow = math.clamp(row, 1, math.max(1, lineCount))
    local line = self:getLine(clampedRow)
    local len = #line
    
    local clampedCol
    if mode == "INSERT" then
        clampedCol = math.clamp(col, 1, len + 1)
    else -- NORMAL
        clampedCol = math.clamp(col, 1, math.max(1, len))
    end
    
    return clampedRow, clampedCol
end

return Buffer
