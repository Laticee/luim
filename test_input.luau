local process = require("@lune/process")
-- Test script for Keyboard key splitting logic

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

local function processHex(hexLine)
    for hex in string.gmatch(hexLine, "%S+") do
        local str = ""
        for i = 1, #hex, 2 do
            local byte = tonumber(string.sub(hex, i, i + 1), 16)
            if byte then
                str = str .. string.char(byte)
            end
        end
        
        local i = 1
        while i <= #str do
            if string.sub(str, i, i) == "\27" then
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
end

local function test(hex, expected)
    keyQueue = {}
    processHex(hex)
    print("Testing hex: " .. hex)
    for i, exp in ipairs(expected) do
        local got = table.remove(keyQueue, 1)
        if got == exp then
            print(string.format("  [%d] OK: %s", i, tostring(got)))
        else
            print(string.format("  [%d] FAIL: expected %s, got %s", i, tostring(exp), tostring(got)))
            process.exit(1)
        end
    end
    if #keyQueue > 0 then
        print("  FAIL: Extra keys in queue: " .. table.concat(keyQueue, ", "))
        process.exit(1)
    end
end

-- 'i' (69)
test("69", {"i"})

-- 'hello' (68 65 6c 6c 6f)
test("68656c6c6f", {"h", "e", "l", "l", "o"})

-- Escape then 'i' (1b 69)
test("1b69", {"esc", "i"})

-- Arrow Up (1b 5b 41)
test("1b5b41", {"up"})

-- Merged Arrow Up and 'x' (1b 5b 41 78)
test("1b5b4178", {"up", "x"})

-- Merged 'jj' (6a 6a)
test("6a6a", {"j", "j"})

print("\nAll tests passed!")
