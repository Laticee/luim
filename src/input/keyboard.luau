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
    ["\9"] = "tab",
}

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
    if not stdout then return "" end
    
    -- Read one line from the driver (hex representation of keypress)
    local hex = stdout:read()
    if not hex or hex == "" then return "" end
    
    -- Trim newline
    hex = string.gsub(hex, "%s+", "")
    
    -- Convert hex back to string
    local str = ""
    for i = 1, #hex, 2 do
        local byte = tonumber(string.sub(hex, i, i + 1), 16)
        if byte then
            str = str .. string.char(byte)
        end
    end
    
    return KEY_MAP[str] or str
end

return Keyboard
