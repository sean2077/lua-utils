---@module watcher

local Class = require("class")

---@class Watcher
---@field name string
---@field private _value any
---@field private _deps Watcher[] 原依赖关系，即上一次该 watcher 对应属性依赖的 watchers
---@field private _newDeps Watcher[] 新依赖关系，即当前该 watcher 对应属性依赖的 watchers
---@field private _subs Watcher[] 订阅者, 即依赖该 watcher 对应属性的 watchers
---@field private _lazy boolean 是否懒执行
---@field private _staticDeps boolean 是否依赖关系固定
---@field private _dirty boolean 是否脏数据
---@field private _getter function 获取值的函数, 仅计算属性需要
---@field private _vm table 实例对象
local _Watcher = Class(
    function(self, name)
        self.name = name
        self._value = nil
        self._deps = {}
        self._newDeps = {}
        self._subs = {}
        self._lazy = true
        self._staticDeps = true
        self._dirty = false
        self._getter = nil
        self._vm = nil
    end
)
Watcher = _Watcher

--- 活跃 watcher 栈
---@type Watcher[]
local watcherStack = {}

local function pushWatcher(watcher)
    table.insert(watcherStack, watcher)
end

local function popWatcher()
    return table.remove(watcherStack)
end

function GetCurrentWatcher()
    return watcherStack[#watcherStack]
end

--- ====================================================================================== ---
---                                    public methods                                     ---
--- ====================================================================================== ---

---初始化观察者（仅计算属性需要）
---@param userDef function|table
---@param vm table 实例对象
---@param name string 属性名, 用于调试
function _Watcher:Init(userDef, vm, name)
    self.name = name
    if type(userDef) == "function" then
        self._getter = userDef
    elseif type(userDef) == "table" then
        self._getter = userDef.get
        self._lazy = userDef.lazy == nil or userDef.lazy -- 默认懒执行
    end
    self._dirty = true
    self._vm = vm
end

---添加依赖者
---@param dep Watcher
function _Watcher:AddDep(dep)
    pprint(string.format("   * <Watcher: %s> add Dep <Watcher: %s>, current deps:", self.name, dep.name))
    -- 防止重复添加
    local hasDep = false
    for i, depWatcher in ipairs(self._newDeps) do
        if depWatcher == dep then
            hasDep = true
            break
        end
    end
    if not hasDep then
        table.insert(self._newDeps, dep)
    end
    for i, depWatcher in ipairs(self._newDeps) do
        pprint(string.format("    -  <Watcher: %s>", depWatcher.name))
    end

    --- 依赖项添加订阅者
    dep:AddSub(self)

    --- 本属性的订阅者也依赖 dep
    -- for i, subWatcher in ipairs(self._subs) do
    --     subWatcher:AddDep(dep)
    -- end
end

---添加订阅者
---@param sub Watcher
function _Watcher:AddSub(sub)
    pprint(string.format("   * <Watcher: %s> add Sub <Watcher: %s>, current subs:", self.name, sub.name))
    -- 防止重复添加
    local hasSub = false
    for i, subWatcher in ipairs(self._subs) do
        if subWatcher == sub then
            hasSub = true
            break
        end
    end
    if not hasSub then
        table.insert(self._subs, sub)
    end
    for i, subWatcher in ipairs(self._subs) do
        pprint(string.format("    -  <Watcher: %s>", subWatcher.name))
    end
end

---移除订阅者
---@param sub Watcher
function _Watcher:RemoveSub(sub)
    pprint(string.format("   * <Watcher: %s> remove Sub <Watcher: %s>, current subs:", self.name, sub.name))

    if not self._subs then
        return
    end
    for i, subWatcher in ipairs(self._subs) do
        if subWatcher == sub then
            table.remove(self._subs, i)
            break
        end
    end
    for i, subWatcher in ipairs(self._subs) do
        pprint(string.format("     -  <Watcher: %s>", subWatcher.name))
    end
end

---通知订阅者更新
function _Watcher:Notify()
    pprint(string.format("   * <Watcher: %s> notify subs ...", self.name))
    for _, subWatcher in ipairs(self._subs) do
        if subWatcher.Update then
            pprint(string.format("     - <Watcher: %s> update", subWatcher.name))
            subWatcher:Update()
        end
    end
end

---观察者更新
function _Watcher:Update()
    self._dirty = true
    if not self._lazy then
        self:Run()
    end
    -- 本属性更新了，也应通知订阅者更新
    self:Notify()
end

---判断观察者是否脏数据
---@return boolean
function _Watcher:IsDirty()
    return self._dirty
end

---获取观察者值
---@return any
function _Watcher:Get()
    pprint(string.format("   * <Watcher: %s> get", self.name))
    if self:IsDirty() then
        self:pushTarget()
        local value = self._getter(self._vm) -- 计算新值 & 收集依赖
        self:popTarget()
        self:cleanupDeps()
        self._value = value
    end
    return self._value
end

---设置观察者值（一般不常用）
function _Watcher:Set(value)
    pprint(string.format("   * <Watcher: %s> set", self.name))
    self._value = value
end

function _Watcher:Run()
    return self:Get()
end

function _Watcher:Execute()
    return self:Get()
end

--- 析构
function _Watcher:Destroy()
    pprint(string.format("   * <Watcher: %s> destroy", self.name))
    for i, depWatcher in ipairs(self._deps) do
        depWatcher:RemoveSub(self)
    end
    for i, depWatcher in ipairs(self._newDeps) do
        depWatcher:RemoveSub(self)
    end
    self._deps = nil
    self._newDeps = nil
    self._subs = nil
    self._getter = nil
    self._vm = nil
end

--- ====================================================================================== ---
---                                    private methods                                     ---
--- ====================================================================================== ---

function _Watcher:pushTarget()
    if self._deps and #self._deps > 0 then -- 旧依赖关系
        for i, depWatcher in ipairs(self._deps) do
            depWatcher:RemoveSub(self)
        end
    end
    pushWatcher(self)
    pprint(string.format("   * <Watcher: %s> set as active watcher", self.name))
end

function _Watcher:popTarget()
    pprint(string.format("   * <Watcher: %s> remove active watcher", self.name))
    popWatcher()
end

function _Watcher:cleanupDeps()
    pprint(string.format("   * <Watcher: %s> cleanup deps", self.name))

    self._deps, self._newDeps = self._newDeps, self._deps

    for dep in pairs(self._newDeps) do
        self._newDeps[dep] = nil
    end

    self._dirty = false
end

return _Watcher
