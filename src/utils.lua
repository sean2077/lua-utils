--- ====================================================================================== ---
---                                       string utils                                     ---
--- ====================================================================================== ---

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == '') then
        return false
    end
    local pos, arr = 0, {}
    for st, sp in function()
        return string.find(input, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function string.upperFirstChar(s, sep)
    local parts = string.split(s, "_")
    for i = 1, #parts do
        local str = parts[i]
        parts[i] = string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
    end
    return table.concat(parts, sep)
end

function rpad(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

--- ====================================================================================== ---
---                                       table utils                                      ---
--- ====================================================================================== ---




--- ====================================================================================== ---
---                                       math utils                                       ---
--- ====================================================================================== ---



--- ====================================================================================== ---
---                                       print utils                                      ---
--- ====================================================================================== ---

function getCurCoId()
    local co, _ = coroutine.running()
    return tostring(co):match("thread: (.+)")
end

local originalPrint = print
function pprint(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = rpad(info.short_src .. ":" .. info.currentline, 30)
    local prefix = string.format("[%s][ %s] ", getCurCoId(), lineinfo)
    -- 使用table.concat来连接所有参数，并去除开头的空格
    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    local message = table.concat(args, " ")

    originalPrint(prefix .. " " .. message)
end

-- _G.print = pprint
