local Class = require("class")

---@class Dep
local _Dep = Class(
    function(self, name)
        self.name = name
        self.subs = {}
    end
)
Dep = _Dep

function _Dep:AddSub(watcher)
    pprint(string.format(" * <Dep: %s> add <Watcher: %s>, current watchers:", self.name, watcher.name))
    table.insert(self.subs, watcher)
    for i, w in ipairs(self.subs) do
        pprint(string.format("   -  <Watcher: %s>", w.name))
    end
end

function _Dep:RemoveSub(depTarget)
    pprint(string.format(" * <Dep: %s> remove <Watcher: %s>, current watchers:", self.name, depTarget.name))
    for i, w in ipairs(self.subs) do
        if w == depTarget then
            table.remove(self.subs, i)
            break
        end
    end
    for i, w in ipairs(self.subs) do
        pprint(string.format("   -  <Watcher: %s>", w.name))
    end
end

function _Dep:Notify()
    pprint(string.format(" * <Dep: %s> notify watchers ...", self.name))
    for i, w in ipairs(self.subs) do
        if w.Update then
            pprint(string.format("   - <Dep: %s> notify <Watcher: %s> update", self.name, w.name))
            w:Update()
        end
    end
end

return _Dep
