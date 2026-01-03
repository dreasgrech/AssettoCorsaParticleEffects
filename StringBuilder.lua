-- A single-threaded StringBuilder implementation
local StringBuilder = {}

-- local bindings
local table_insert = table.insert
local table_concat = table.concat
local table_clear = table.clear

local NEWLINE = "\n"

local buffer = {}

StringBuilder.clear = function()
    table_clear(buffer)
end

StringBuilder.append = function(text)
    table_insert(buffer, text)
end

StringBuilder.toString = function()
    return table_concat(buffer, NEWLINE)
end

return StringBuilder