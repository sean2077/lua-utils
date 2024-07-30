---@module Base

local Watcher = require("reactive.watcher")
local Dep = require("reactive.dep")
require("utils")

---@class Base
---@field deps table<string, Dep> 属性消息订阅器
---@field __watchers table<string, Watcher> 计算属性观察者
local _Base = Class()
Base = _Base

function _Base:Observe()
    self.deps = {}
    self.__watchers = {}
    local metatable = getmetatable(self)
    self:GeneralGetSet(metatable)
    self:GeneralGetSet(self)
end

function _Base:GeneralGetSet(table)
    if self and table then
        for k, v in pairs(table) do
            if type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "nil" then
                self:GeneralFieldGetSet(k)
            elseif type(v) == "table" and k == "computed" then
                for ck, cv in pairs(self.computed) do
                    self:GeneralComputedField(ck, cv)
                end
            end
        end
    end
end

function _Base:GeneralFieldGetSet(k)
    self.deps[k] = Dep(k)
    local suffix = string.upperFirstChar(k)
    local setKey = "Setter" .. suffix
    local getKey = "Getter" .. suffix
    self[getKey] = function(self)
        pprint("{ " .. getKey .. " begin")
        local dep = self.deps[k]
        self:GatherWatcher(dep)
        pprint(getKey .. " end, return value: " .. tostring(self[k]) .. " }")
        return self[k]
    end
    self[setKey] = function(self, value)
        pprint("{ " .. setKey .. " begin")
        self[k] = value
        local dep = self.deps[k]
        dep:Notify()
        pprint(setKey .. " end }")
    end
end

local co = nil -- 重用协程

function _Base:GeneralComputedField(ck, cv)
    local watcher = Watcher(ck)
    self.deps[ck] = Dep(ck)
    watcher:Init(cv, self, ck)
    self.__watchers[ck] = watcher

    local suffix = string.upperFirstChar(ck)
    local getKey = "Getter" .. suffix
    local setKey = "Setter" .. suffix

    -- 定义计算属性的 Getter 方法

    self[getKey] = function(self)
        local func = function(self) ---@param self Base
            pprint("{ " .. getKey .. " begin")
            local wt = self.__watchers[ck]
            local dep = self.deps[ck]
            self:GatherWatcher(dep)
            local is_dirty = wt.dirty
            local value = wt:Get()
            if is_dirty then
                dep:Notify()
            end
            pprint(getKey .. " end, return value: " .. tostring(value) .. " }")
            return value
        end
        if not co then
            co = coroutine.create(function(func, self)
                while true do
                    func, self = coroutine.yield(func(self))
                end
            end)
        end
        local status, ret = coroutine.resume(co, func, self)
        return ret
    end

    -- 特殊用法，不建议直接使用 Setter 更新计算属性
    self[setKey] = function(self, value)
        pprint("{ " .. setKey .. " begin")
        local wt = self.__watchers[ck]
        wt:Set(value)
        local dep = self.deps[ck]
        dep:Notify()
        pprint(" " .. setKey .. " end }")
    end
end

function _Base:GatherWatcher(dep)
    local __watchers = Watcher:GlobalWatchers() ---@type table<thread, Watcher>
    if __watchers and coroutine.running() and __watchers[coroutine.running()] then
        local __watcher = __watchers[coroutine.running()]
        if __watcher then
            __watcher:AddDep(dep)
            return
        end
    end
end

function _Base:AddField(fieldName, v)
    self[fieldName] = v
    self:GeneralFieldGetSet(fieldName)
end

function _Base:AddComputedField(fieldName, userDef)
    self:GeneralComputedField(fieldName, userDef)
end

function _Base:Notify(fieldName)
    local wt = self.__watchers[fieldName]
    if wt then
        wt.dirty = true
    end
end

return _Base
