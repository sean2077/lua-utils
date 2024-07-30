---@param base table | function | nil
---@param _ctor function | nil
---@return table
Class = function(base, _ctor)
    local c = {}
    if not _ctor and type(base) == "function" then
        _ctor = base
        base = nil
    elseif type(base) == "table" then
        for i, v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end
    c.__index = c
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, c)
        if _ctor then
            _ctor(obj, ...)
        end
        return obj
    end
    c._ctor = _ctor
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then
                return true
            end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end

return Class
