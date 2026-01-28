--[[
    Luim - Main Application
]]

local process = require("@lune/process")
local fs = require("@lune/fs")
local stdio = require("@lune/stdio")

local Buffer = require("./src/core/buffer")
local Renderer = require("./src/ui/renderer")
local Keyboard = require("./src/input/keyboard")

local Dashboard = require("./src/ui/dashboard")

-- Configuration
local width = 80
local height = 24

local function updateSize()
    local res = process.exec("stty", { "size" })
    if not res.ok then return end
    local h, w = string.match(res.stdout, "(%d+)%s+(%d+)")
    if h and w then
        height = tonumber(h)
        width = tonumber(w)
    end
end

updateSize()

local buffer = Buffer.new()
local cursorRow = 1
local cursorCol = 1
local startRow = 1
local mode = "NORMAL"
local state = "EDITOR"
local filename = process.args[1]

-- Load file logic
local function loadFile(name)
    if not name then 
        buffer = Buffer.new({ "" })
        filename = nil
        cursorRow = 1
        cursorCol = 1
        startRow = 1
        state = "EDITOR"
        return
    end
    
    if fs.isFile(name) then
        filename = name
        local content = fs.readFile(name)
        local lines = {}
        for line in string.gmatch(content .. "\n", "(.-)\n") do
            table.insert(lines, line)
        end
        buffer = Buffer.new(lines)
    else
        -- New file
        filename = name
        buffer = Buffer.new({ "" })
    end
    cursorRow = 1
    cursorCol = 1
    startRow = 1
    state = "EDITOR"
end

if filename then
    loadFile(filename)
else
    state = "DASHBOARD"
end

Keyboard.init()

local function saveFile()
    if filename then
        local content = table.concat(buffer.lines, "\n")
        fs.writeFile(filename, content)
    end
end

local function handleMenu()
    local query = ""
    local lastQuery = nil
    local filtered = {}
    local currentPath = process.cwd
    local allFiles = fs.readDir(currentPath)
    local selectedIdx = 1
    local menuStartRow = 1
    
    local function refreshFiles()
        allFiles = fs.readDir(currentPath)
        -- Add ".." if not at root
        if currentPath ~= "/" then
            table.insert(allFiles, 1, "..")
        end
        lastQuery = nil -- Force filter update
    end
    
    refreshFiles()
    
    while true do
        updateSize()
        
        if query ~= lastQuery then
            filtered = {}
            for _, file in ipairs(allFiles) do
                if string.find(string.lower(file), string.lower(query), 1, true) then
                    local fullPath = currentPath == "." and file or (currentPath .. "/" .. file)
                    table.insert(filtered, {
                        name = file,
                        path = fullPath,
                        isDir = (file == ".." or fs.isDir(fullPath))
                    })
                end
            end
            
            table.sort(filtered, function(a, b)
                if a.name == ".." then return true end
                if b.name == ".." then return false end
                
                if a.isDir ~= b.isDir then
                    return a.isDir -- Directories first
                end
                
                local aHidden = string.sub(a.name, 1, 1) == "."
                local bHidden = string.sub(b.name, 1, 1) == "."
                if aHidden ~= bHidden then return not aHidden end
                return a.name:lower() < b.name:lower()
            end)
            
            selectedIdx = 1
            menuStartRow = 1
            lastQuery = query
        end
        
        local menuRows = height - 1
        if selectedIdx < menuStartRow then
            menuStartRow = selectedIdx
        elseif selectedIdx >= menuStartRow + menuRows then
            menuStartRow = selectedIdx - menuRows + 1
        end

        local out = "\27[H"
        for i = 1, menuRows do
            out = out .. "\27[K"
            local idx = menuStartRow + i - 1
            local item = filtered[idx]
            if item then
                local display = item.name
                if item.isDir and item.name ~= ".." then display = display .. "/" end
                if idx == selectedIdx then
                    out = out .. "\27[7m > " .. display .. "\27[0m"
                else
                    out = out .. "   " .. display
                end
            end
            out = out .. "\r\n"
        end
        local pathDisp = currentPath == "." and "Root" or currentPath
        out = out .. "\27[7m\27[K Dir: " .. pathDisp .. " | Search: " .. query .. " (Enter: Open, Esc: Cancel)\27[0m"
        stdio.write(out)
        
        local key = Keyboard.readKey()
        if key == "esc" then
            return false
        elseif key == "enter" then
            if #filtered > 0 and filtered[selectedIdx] then
                local selected = filtered[selectedIdx]
                
                if selected.name == ".." then
                    currentPath = string.gsub(currentPath, "/?[^/]+$", "")
                    if currentPath == "" then currentPath = "/" end
                    query = ""
                    refreshFiles()
                elseif selected.isDir then
                    currentPath = selected.path
                    query = ""
                    refreshFiles()
                else
                    loadFile(selected.path)
                    return true
                end
            end
        elseif key == "up" or key == "k" then
            selectedIdx = math.max(1, selectedIdx - 1)
        elseif key == "down" or key == "j" then
            selectedIdx = math.min(#filtered, selectedIdx + 1)
        elseif key == "backspace" then
            query = string.sub(query, 1, -2)
        elseif #key == 1 then
            query = query .. key
        end
    end
end

local commandBuffer = ""

local function handleInput()
    local key = Keyboard.readKey()
    if key == "" then return true end
    
    -- Global shortcuts
    if key == "\17" then -- Ctrl+Q
        return false
    elseif key == "\19" then -- Ctrl+S
        saveFile()
        return true
    elseif key == "\16" then -- Ctrl+P
        handleMenu()
        return true
    end

    if state == "DASHBOARD" then
        if key == "f" then
            if handleMenu() then
                state = "EDITOR"
            end
        elseif key == "n" then
            loadFile(nil)
        elseif key == "i" then
            loadFile(nil)
            mode = "INSERT"
        elseif key == "q" then
            return false
        end
        return true
    end

    if mode == "NORMAL" then
        if key == "esc" then
            commandBuffer = ""
            return true
        end

        commandBuffer = commandBuffer .. key
        
        local handled = false
        if commandBuffer == "i" then
            mode = "INSERT"
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "h" or commandBuffer == "left" then
            cursorCol = cursorCol - 1
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "l" or commandBuffer == "right" then
            cursorCol = cursorCol + 1
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "k" or commandBuffer == "up" then
            cursorRow = cursorRow - 1
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "j" or commandBuffer == "down" then
            cursorRow = cursorRow + 1
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "x" then
            buffer:deleteChar(cursorRow, cursorCol)
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "dd" then 
            buffer:deleteLine(cursorRow)
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "o" then
            buffer:insertLine(cursorRow + 1, "")
            cursorRow = cursorRow + 1
            cursorCol = 1
            mode = "INSERT"
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "O" then
            buffer:insertLine(cursorRow, "")
            cursorCol = 1
            mode = "INSERT"
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "0" then -- Jump to start
            cursorCol = 1
            commandBuffer = ""
            handled = true
        elseif commandBuffer == "G" then -- Jump to end
            cursorRow = buffer:getLineCount()
            commandBuffer = ""
            handled = true
        end

        if not handled then
            -- If it's a prefix of a longer command, keep it
            if commandBuffer == "d" then
                -- Wait for next char
            else
                -- Not a command, clear buffer
                commandBuffer = ""
            end
        end
        
    elseif mode == "INSERT" then
        if key == "esc" then
            mode = "NORMAL"
            cursorCol = cursorCol - 1
        elseif key == "backspace" then
            if cursorCol > 1 then
                buffer:deleteChar(cursorRow, cursorCol - 1)
                cursorCol = cursorCol - 1
            elseif cursorRow > 1 then
                local prevLineLen = #buffer:getLine(cursorRow - 1)
                buffer:mergeLines(cursorRow - 1)
                cursorRow = cursorRow - 1
                cursorCol = prevLineLen + 1
            end
        elseif key == "enter" then
            buffer:splitLine(cursorRow, cursorCol)
            cursorRow = cursorRow + 1
            cursorCol = 1
        elseif #key == 1 then
            buffer:insertChar(cursorRow, cursorCol, key)
            cursorCol = cursorCol + 1
        end
    end
    
    -- Final cursor placement and scrolling logic
    cursorRow, cursorCol = buffer:clampCursor(cursorRow, cursorCol, mode)

    -- Adjust scroll
    local textRows = height - 1
    if cursorRow < startRow then
        startRow = cursorRow
    elseif cursorRow >= startRow + textRows then
        startRow = cursorRow - textRows + 1
    end
    
    return true
end

-- Main Loop
local running = true
local frameCount = 0
while running do
    -- Update size every 10 frames to avoid overhead
    if frameCount % 10 == 0 then
        updateSize()
    end
    frameCount = frameCount + 1
    
    if state == "DASHBOARD" then
        Dashboard.render(width, height)
    else
        Renderer.renderBuffer(buffer, startRow, width, height, cursorRow, cursorCol, mode)
    end
    
    running = handleInput()
end

Keyboard.cleanup()
stdio.write("\27[2J\27[H") -- Clear on exit
print("Exited Luim.")
