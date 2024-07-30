---@module Reactive System Base Class

local Watcher = require("reactive.watcher")
require("utils")

---@class Base
---@field _watchers table<string, Watcher> 键为属性名
local _Base = Class()
Base = _Base

--- 如果要开启观察者模式，需要在调用 Observe 方法以生成 _watchers 字段
function _Base:Observe()
    self._watchers = {}
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
    local wt = Watcher(k)
    self._watchers[k] = wt -- 支持覆盖已有的属性

    local suffix = string.upperFirstChar(k)
    local setKey = "Setter" .. suffix
    local getKey = "Getter" .. suffix

    ---@param self Base
    self[getKey] = function(self)
        pprint("{ " .. getKey .. " begin")
        local wt = self._watchers[k]
        self:GatherWatcher(wt)
        pprint("  " .. getKey .. " end, return value: " .. tostring(self[k]) .. " }")
        return self[k]
    end
    ---@param self Base
    self[setKey] = function(self, value)
        pprint("{ " .. setKey .. " begin")
        self[k] = value
        local wt = self._watchers[k]
        wt:Notify()
        pprint("  " .. setKey .. " end }")
    end
end

function _Base:GeneralComputedField(ck, cv)
    local wt = Watcher(ck)
    wt:Init(cv, self, ck)
    self._watchers[ck] = wt -- 支持覆盖已有的计算属性

    local suffix = string.upperFirstChar(ck)
    local getKey = "Getter" .. suffix
    local setKey = "Setter" .. suffix

    -- 定义计算属性的 Getter 方法
    ---@param self Base
    self[getKey] = function(self)
        pprint("{ " .. getKey .. " begin")
        local wt = self._watchers[ck]
        self:GatherWatcher(wt)
        local is_dirty = wt:IsDirty() -- 是否脏数据
        local value = wt:Get()
        if is_dirty then
            wt:Notify() -- 如果是脏数据，通知订阅者更新
        end
        pprint("  " .. getKey .. " end, return value: " .. tostring(value) .. " }")
        return value
    end

    -- 特殊用法，不建议直接使用 Setter 更新计算属性
    self[setKey] = function(self, value)
        pprint("{ " .. setKey .. " begin")
        local wt = self._watchers[ck] ---@type Watcher
        wt:Set(value)
        wt:Notify()
        pprint("  " .. setKey .. " end }")
    end
end

---将 dep 添加到当前活跃的 Watcher 的依赖列表中
---@param wt Watcher
function _Base:GatherWatcher(wt)
    local activeWt = GetCurrentWatcher() -- 当前活跃的 Watcher，即正在获取的计算属性
    if activeWt then
        activeWt:AddDep(wt)
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
    local wt = self._watchers[fieldName]
    if wt then
        wt:Update()
    end
end

--- 停止观察，如果开启了观察者，清理对象前务必调用该方法，防止引用悬空
function _Base:StopObserve()
    if self._watchers then
        for k, wt in pairs(self._watchers) do
            wt:Destroy()
            self._watchers[k] = nil
        end
    end
    -- 清理 Getter 和 Setter 方法
end

return _Base
