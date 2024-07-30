---@module Watcher

local Class = require("class")

---@class Watcher
local _Watcher = Class(
    function(self, name)
        self.name = name
        self.value = nil
        self.deps = {}
        self.newDeps = {}
        self.lazy = true
        self.staticDeps = true -- 是否依赖关系固定
        self.dirty = true
        self.getter = nil
        self.vm = nil
    end
)
Watcher = _Watcher


local global_watchers = {}
function _Watcher:GlobalWatchers()
    return global_watchers
end

function _Watcher:Init(userDef, vm, name)
    if type(userDef) == "function" then
        self.getter = userDef
    elseif type(userDef) == "table" then
        self.getter = userDef.get
        self.lazy = userDef.lazy == nil or userDef.lazy
    end
    self.vm = vm
    self.name = name
end

---@param dep Dep
function _Watcher:AddDep(dep)
    pprint(string.format(" * <Watcher: %s> add <Dep: %s>, current deps:", self.name, dep.name))
    table.insert(self.newDeps, dep)
    for i, depWatcher in ipairs(self.newDeps) do
        pprint(string.format("   -  <Dep: %s>", depWatcher.name))
    end
    dep:AddSub(self)
end

function _Watcher:Update()
    self.dirty = true
    if not self.lazy then
        self:Run()
    end
end

function _Watcher:Get()
    pprint(string.format(" * <Watcher: %s> get", self.name))
    if self.dirty then
        self:PushTarget()
        local value = self.getter(self.vm)
        self:PopTarget()
        self:CleanupDeps()
        self.value = value
    end
    return self.value
end

function _Watcher:Set(value)
    pprint(string.format(" * <Watcher: %s> set", self.name))
    self.value = value
end

function _Watcher:Run()
    return self:Get()
end

function _Watcher:Execute()
    return self:Get()
end

function _Watcher:PushTarget()
    if self.deps and #self.deps > 0 then -- 旧依赖关系
        for i, depWatcher in ipairs(self.deps) do
            depWatcher:RemoveSub(self)
        end
    end
    local __watchers = global_watchers
    __watchers[coroutine.running()] = self
    pprint(string.format(" * <Watcher: %s> set as active watcher", self.name))
end

function _Watcher:PopTarget()
    pprint(string.format(" * <Watcher: %s> remove active watcher", self.name))
    local __watchers = global_watchers
    if __watchers and __watchers[coroutine.running()] then
        __watchers[coroutine.running()] = nil
    end
end

function _Watcher:CleanupDeps()
    pprint(string.format(" * <Watcher: %s> cleanup deps", self.name))

    self.deps, self.newDeps = self.newDeps, self.deps

    for dep in pairs(self.newDeps) do
        self.newDeps[dep] = nil
    end

    self.dirty = false
end

return _Watcher
