require("init")
require("utils")
local Class = require("class")
local Base = require("reactive.base")
local Watcher = require("reactive.watcher")

---@class Entity : Base
---@field name string
---@field position table
---@param self Entity
local Entity = Class(Base, function(self, name)
    self:Observe()
    self:AddField("name", name)
    self:AddField("position", { x = 0, y = 0 })
end)

---@class Creature : Entity
---@field maxHealth number
---@field currentHealth number
---@field attack number
---@field defense number
---@field effects table
---@field status string
---@param self Creature
local Creature = Class(Entity, function(self, name, health, attack, defense)
    Entity._ctor(self, name)
    self:AddField("maxHealth", health)
    self:AddField("currentHealth", health)
    self:AddField("attack", attack)
    self:AddField("defense", defense)
    self:AddField("effects", {})
    self:AddComputedField("status", {
        get = function(self)
            local healthPercentage = self:GetterCurrentHealth() / self:GetterMaxHealth() * 100
            if healthPercentage > 75 then
                return "Healthy"
            elseif healthPercentage > 25 then
                return "Injured"
            else
                return "Critical"
            end
        end
    })
end)

---让生物受到伤害
---@param damage number 伤害值
function Creature:TakeDamage(damage)
    local newHealth = self:GetterCurrentHealth() - math.max(1, damage - self:GetterDefense())
    self:SetterCurrentHealth(math.max(0, newHealth))
end

---治疗生物
---@param amount number 治疗量
function Creature:Heal(amount)
    local newHealth = math.min(self:GetterCurrentHealth() + amount, self:GetterMaxHealth())
    self:SetterCurrentHealth(newHealth)
end

---添加效果到生物
---@param effect Effect 要添加的效果
function Creature:AddEffect(effect)
    local effects = self:GetterEffects()
    table.insert(effects, effect)
    self:SetterEffects(effects)
end

---@class Character : Creature
---@field class string
---@field experience number
---@field level number
---@field equipment table
---@field totalAttack number
---@field totalDefense number
local Character = Class(Creature, function(self, name, health, attack, defense, class)
    Creature._ctor(self, name, health, attack, defense)
    self:AddField("class", class)
    self:AddField("experience", 0)
    self:AddField("level", 1)
    self:AddField("equipment", {})
    self:AddComputedField("totalAttack", {
        get = function(self)
            local total = self:GetterAttack()
            for _, item in ipairs(self:GetterEquipment()) do
                total = total + item:GetterAttackBonus()
            end
            return total
        end
    })
    self:AddComputedField("totalDefense", {
        get = function(self)
            local total = self:GetterDefense()
            for _, item in ipairs(self:GetterEquipment()) do
                total = total + item:GetterDefenseBonus()
            end
            return total
        end
    })
end)

function Character:Equip(item)
    local equipment = self:GetterEquipment()
    table.insert(equipment, item)
    self:SetterEquipment(equipment)
end

function Character:GainExperience(amount)
    local newExp = self:GetterExperience() + amount
    self:SetterExperience(newExp)
    while newExp >= 100 * self:GetterLevel() do
        self:LevelUp()
        newExp = newExp - 100 * self:GetterLevel()
    end
    self:SetterExperience(newExp)
end

function Character:LevelUp()
    self:SetterLevel(self:GetterLevel() + 1)
    self:SetterMaxHealth(self:GetterMaxHealth() + 10)
    self:SetterAttack(self:GetterAttack() + 2)
    self:SetterDefense(self:GetterDefense() + 1)
    self:SetterCurrentHealth(self:GetterMaxHealth()) -- 满血
end

---@class Equipment : Base
---@field name string
---@field attackBonus number
---@field defenseBonus number
local Equipment = Class(Base, function(self, name, attackBonus, defenseBonus)
    self:Observe()
    self:AddField("name", name)
    self:AddField("attackBonus", attackBonus)
    self:AddField("defenseBonus", defenseBonus)
end)

---@class Effect : Base
---@field name string
---@field duration number
---@field attackModifier number
---@field defenseModifier number
local Effect = Class(Base, function(self, name, duration, attackMod, defenseMod)
    self:Observe()
    self:AddField("name", name)
    self:AddField("duration", duration)
    self:AddField("attackModifier", attackMod)
    self:AddField("defenseModifier", defenseMod)
end)

---@class BattleLogger : Watcher
local BattleLogger = Class(Watcher)
BattleLogger.name = "BattleLogger"
function BattleLogger:Update()
    -- pprint("BattleLogger:Update", subject)
    -- pprint(string.format("[Battle Log] %s's health changed to %d (%s)", subject:GetterName(),
    --     subject:GetterCurrentHealth(), subject:GetterStatus()))
    -- pprint(string.format("[Battle Log] %s leveled up to level %d!", subject:GetterName(), subject:GetterLevel()))
end

---@class AnimationSystem : Watcher
local AnimationSystem = Class(Watcher)
AnimationSystem.name = "AnimationSystem"

function AnimationSystem:Update()
    -- pprint("AnimationSystem:Update", subject)
    -- pprint(string.format("[Animation] Playing hurt animation for %s", subject:GetterName()))
    -- pprint(string.format("[Animation] Playing level up effect for %s", subject:GetterName()))
    -- pprint(string.format("[Animation] Moving %s to position (%d, %d)", subject:GetterName(), subject:GetterPosition().x,
    --     subject:GetterPosition().y))
end

---@class GameSystem
---@field characters Character[]
local GameSystem = {
    characters = {},

    ---添加角色到游戏系统
    ---@param character Character
    AddCharacter = function(self, character)
        table.insert(self.characters, character)
        -- 添加观察者
        -- character.deps["currentHealth"]:AddSub(BattleLogger)
        -- character.deps["level"]:AddSub(BattleLogger)
        -- character.deps["currentHealth"]:AddSub(AnimationSystem)
        -- character.deps["level"]:AddSub(AnimationSystem)
        -- character.deps["position"]:AddSub(AnimationSystem)
    end,

    ---模拟战斗
    ---@param char1 Character
    ---@param char2 Character
    SimulateBattle = function(self, char1, char2)
        pprint("\nBattle starts between " .. char1:GetterName() .. " and " .. char2:GetterName())
        while char1:GetterCurrentHealth() > 0 and char2:GetterCurrentHealth() > 0 do
            char2:TakeDamage(char1:GetterTotalAttack())
            if char2:GetterCurrentHealth() > 0 then
                char1:TakeDamage(char2:GetterTotalAttack())
            end
        end
        local winner = char1:GetterCurrentHealth() > 0 and char1 or char2
        pprint("Battle ends. " .. winner:GetterName() .. " wins!")
        winner:GainExperience(50)
    end
}

-- 创建角色和装备
local hero = Character("Hero", 100, 15, 10, "Warrior") ---@type Character
local enemy = Character("Enemy", 80, 12, 8, "Rogue") ---@type Character

local sword = Equipment("Sword", 5, 0)
local shield = Equipment("Shield", 0, 3)
local potion = Effect("Strength Potion", 3, 5, 0)

-- 将角色添加到游戏系统
GameSystem:AddCharacter(hero)
GameSystem:AddCharacter(enemy)

-- 模拟游戏流程
pprint("Initial state:")
pprint(string.format("%s - Health: %d, Attack: %d, Defense: %d",
    hero:GetterName(), hero:GetterCurrentHealth(), hero:GetterTotalAttack(), hero:GetterTotalDefense()))

hero:Equip(sword)
hero:Equip(shield)
hero:AddEffect(potion)

pprint("\nAfter equipping items and using potion:")
pprint(string.format("%s - Health: %d, Attack: %d, Defense: %d",
    hero:GetterName(), hero:GetterCurrentHealth(), hero:GetterTotalAttack(), hero:GetterTotalDefense()))

hero:SetterPosition({ x = 10, y = 20 })

GameSystem:SimulateBattle(hero, enemy)
