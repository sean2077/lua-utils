local CoroutinePool = {}

-- 私有变量
local coroutinePool = {}

-- 私有函数
local function createCoroutine()
    return coroutine.create(function(func, ...)
        local args = { ... }
        while (func) do
            func, args = coroutine.yield({ func(table.unpack(args)) })
        end
    end)
end

-- 公共函数

function CoroutinePool.get()
    local co = table.remove(coroutinePool)
    if co then
        return co
    else
        return createCoroutine()
    end
end

function CoroutinePool.release(co)
    table.insert(coroutinePool, co)
end

function CoroutinePool.execute(func, ...)
    local co = CoroutinePool.get()
    local success, results = coroutine.resume(co, func, { ... })
    if not success then
        CoroutinePool.release(co)
        error("Coroutine error: " .. tostring(results))
    end
    CoroutinePool.release(co)
    return table.unpack(results)
end

return CoroutinePool
