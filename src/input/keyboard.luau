local process = require("@lune/process")

local Keyboard = {}

-- Key mappings for escape sequences
local KEY_MAP = {
    ["\27[A"] = "up",
    ["\27[B"] = "down",
    ["\27[C"] = "right",
    ["\27[D"] = "left",
    ["\27"] = "esc",
    ["\127"] = "backspace",
    ["\13"] = "enter",
    ["\10"] = "enter",
    ["\r\n"] = "enter",
    ["\9"] = "tab",
}

local keyQueue = {}
local child = nil
local stdout = nil

-- Setup the C driver
function Keyboard.init()
    local luimDir = process.env.LUIM_DIR
    local paths = {}
    
    if luimDir then
        table.insert(paths, luimDir .. "/src/input/driver")
    end
    
    table.insert(paths, "./src/input/driver")
    table.insert(paths, "./luim/src/input/driver")
    table.insert(paths, "luim/src/input/driver")
    
    for _, path in ipairs(paths) do
        local success, res = pcall(function()
            return process.create(path, {})
        end)
        if success then
            child = res
            stdout = child.stdout
            return
        end
    end
    
    error("Could not find or start the input driver (src/input/driver). Please ensure it is compiled.")
end

-- Restore terminal mode (driver does this automatically on exit)
function Keyboard.cleanup()
    if child then
        child:kill()
    end
end

function Keyboard.readKey()
    if #keyQueue > 0 then
        return table.remove(keyQueue, 1)
    end

    if not stdout then return "" end
    
    -- Read one line from the driver (hex representation of keypresses)
    local hexLine = stdout:read()
    if not hexLine or hexLine == "" then return "" end
    
    -- Split by whitespace if driver sends multiple lines in one read (unlikely but safe)
    for hex in string.gmatch(hexLine, "%S+") do
        -- Convert hex back to string
        local str = ""
        for i = 1, #hex, 2 do
            local byte = tonumber(string.sub(hex, i, i + 1), 16)
            if byte then
                str = str .. string.char(byte)
            end
        end
        
        -- Special case: split escape sequences or multiple characters if they were merged without newlines
        -- (though the driver currently appends \n after each read, stdout:read() might read multiple lines)
        -- Actually, the driver does `printf("\n")` after each read cycle.
        -- If user typed very fast, we might get multiple characters in one read cycle too.
        
        -- Simple splitting: if it's an escape sequence, keep it together.
        -- Otherwise, each byte is a separate key.
        local i = 1
        while i <= #str do
            if string.sub(str, i, i) == "\27" then
                -- Check if it's a known sequence
                local foundSequence = false
                for seq, _ in pairs(KEY_MAP) do
                    if seq ~= "\27" and string.sub(str, i, i + #seq - 1) == seq then
                        table.insert(keyQueue, KEY_MAP[seq])
                        i = i + #seq
                        foundSequence = true
                        break
                    end
                end
                
                if not foundSequence then
                    -- Just a literal Esc or unknown sequence
                    table.insert(keyQueue, KEY_MAP["\27"])
                    i = i + 1
                end
            else
                local char = string.sub(str, i, i)
                table.insert(keyQueue, KEY_MAP[char] or char)
                i = i + 1
            end
        end
    end
    
    if #keyQueue > 0 then
        return table.remove(keyQueue, 1)
    end
    
    return ""
end

return Keyboard
