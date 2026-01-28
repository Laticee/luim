--[[
    Build script for Luim.
    Compiles the C input driver.
]]

local process = require("@lune/process")
local fs = require("@lune/fs")

print("Building Luim Input Driver...")

local driverPath = "src/input/driver.c"
local outputPath = "src/input/driver"

if not fs.isFile(driverPath) then
    error("Could not find " .. driverPath)
end

local compiler = "gcc"
-- Check if clang is available if gcc isn't (common on macOS)
local checkClang = process.exec("clang", { "--version" })
if checkClang.ok then
    compiler = "clang"
end

print("Using compiler: " .. compiler)

local result = process.exec(compiler, {
    driverPath,
    "-o", outputPath,
    "-O3",
})

if result.ok then
    print("Successfully built driver at: " .. outputPath)
else
    print("Failed to build driver:")
    print(result.stderr)
    process.exit(1)
end
