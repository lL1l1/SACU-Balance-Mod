---@diagnostic disable-next-line: duplicate-doc-alias
---@alias BuffAffectName
---| 'EnergyMaintenanceOverride'

--- Calculates regen for a unit using mults as a multiplier of the unit's HP that is then added to the final regen value.
---@param unit Unit
---@param buffName BuffName
---@param affectState BlueprintBuffAffectState
---@param buffsForAffect table<BuffName, BlueprintBuffAffectState> | { regenAuraTotalRegen: number }
---@return number add
---@return number mult
local function regenAuraAffectCalculate(unit, buffName, affectState, buffsForAffect)
    local adds = 0

    if affectState.Add and affectState.Add ~= 0 then
        adds = adds + (affectState.Add * affectState.Count)
    end

    local mult = affectState.Mult
    if mult then
        local maxHealth = unit.Blueprint.Defense.MaxHealth
        adds = adds + mult * maxHealth * affectState.Count
    end

    return adds, 1
end

--- A function that calculates buff add and mult values for a buff contributing to an "affect".
---@alias AffectCalculation fun(unit: Unit, affectBuffName: BuffName, affectBp: BlueprintBuffAffectState, buffsForAffect: table<BuffName, BlueprintBuffAffectState>): add: number, mult: number

---@type table<BuffName, table<BuffName, AffectCalculation>>
UniqueAffectCalculation = {
    SeraphimACURegenAura = { Regen = regenAuraAffectCalculate },
    SeraphimACUAdvancedRegenAura = { Regen = regenAuraAffectCalculate },
    SeraphimSCURegenAura = { Regen = regenAuraAffectCalculate },
}

-- Dynamic ceilings with fallback values for sera regen field
local regenAuraDefaultCeilings = {
    TECH1 = 10,
    TECH2 = 15,
    TECH3 = 25,
    EXPERIMENTAL = 40,
    SUBCOMMANDER = 30
}

local regenAuraBuffs = {
    SeraphimACURegenAura = true,
    SeraphimACUAdvancedRegenAura = true,
    SeraphimSCURegenAura = true,
}

--- Calculates the affect values from all the buffs a unit has for a given affect type.
---@param unit Unit
---@param buffName string
---@param affectType string
---@param initialVal number
---@param initialBool? boolean
---@return number, boolean
local function regenAuraBuffCalculate(unit, buffName, affectType, initialVal, initialBool)
    local buffsForAffect = unit.Buffs.Affects[affectType]
    local bool = initialBool or false
    if not buffsForAffect then return initialVal, bool end
    local adds = 0
    local mults = 1.0
    local floor = 0
    ---@type RegenAuraData[]
    local regenAuraData = {}

    for originBuffName, affectState in pairs(buffsForAffect) do
        if affectState.Floor then
            floor = affectState.Floor
        end

        if not affectState.Bool then
            bool = false
        else
            bool = true
        end

        local buffAdd = 0
        local uniqueCalculation = UniqueAffectCalculation[originBuffName][affectType]
        if uniqueCalculation then
            local mult
            buffAdd, mult  = uniqueCalculation(unit, originBuffName, affectState, buffsForAffect)
            mults = mults * mult
        else
            local add = affectState.Add
            if add and add ~= 0 then
                buffAdd = add * affectState.Count
            end

            local mult = affectState.Mult
            if mult then
                for i = 1, affectState.Count do
                    mults = mults * mult
                end
            end
        end

        if regenAuraBuffs[originBuffName] then
            local techCategory = unit.Blueprint.TechCategory
            table.insert(regenAuraData,
            ---@class RegenAuraData
            {
                add = buffAdd,
                ceil = affectState.BPCeilings[techCategory] or regenAuraDefaultCeilings[techCategory],
                buffName = originBuffName,
                count = affectState.Count,
            })
        else
            adds = adds + buffAdd
        end
    end

    table.sort(regenAuraData, function (a, b)
        return a.ceil < b.ceil
    end)
    local regenAuraAdd = 0
    ---@param t RegenAuraData
    for _, t in ipairs(regenAuraData) do
        local ceil = t.ceil - regenAuraAdd
        if ceil <= 0 then continue end
        local add = t.add
        if add > ceil then
            regenAuraAdd = regenAuraAdd + ceil
        else
            regenAuraAdd = regenAuraAdd + add
        end
    end
    adds = adds + regenAuraAdd

    -- Adds are calculated first, then the mults.
    local returnVal = math.max((initialVal + adds) * mults, floor)

    return returnVal, bool
end

UniqueBuffs = {
    SeraphimACURegenAura = regenAuraBuffCalculate,
    SeraphimACUAdvancedRegenAura = regenAuraBuffCalculate,
    SeraphimSCURegenAura = regenAuraBuffCalculate,
}

--- Calculates the affect values from all the buffs a unit has for a given affect type.
---@param unit Unit
---@param buffName string
---@param affectType string
---@param initialVal number
---@param initialBool? boolean
---@return number, boolean
function BuffCalculate(unit, buffName, affectType, initialVal, initialBool)
    -- Check if we have a separate buff calculation system
    local uniqueBuff = UniqueBuffs[buffName]
    if uniqueBuff then
        return uniqueBuff(unit, buffName, affectType, initialVal, initialBool)
    end

    -- if not, do the typical buff computation

    local buffsForAffect = unit.Buffs.Affects[affectType]
    local bool = initialBool or false
    if not buffsForAffect then return initialVal, bool end
    local adds = 0
    local mults = 1.0
    local floor = 0

    for originBuffName, affectState in pairs(buffsForAffect) do
        if affectState.Floor then
            floor = affectState.Floor
        end

        if not affectState.Bool then
            bool = false
        else
            bool = true
        end

        local uniqueCalculation = UniqueAffectCalculation[originBuffName][affectType]
        if uniqueCalculation then
            local add, mult = uniqueCalculation(unit, originBuffName, affectState, buffsForAffect)
            adds = adds + add
            mults = mults * mult
        else
            local add = affectState.Add
            if add and add ~= 0 then
                adds = adds + (add * affectState.Count)
            end

            local mult = affectState.Mult
            if mult then
                for i = 1, affectState.Count do
                    mults = mults * mult
                end
            end
        end
    end

    -- Adds are calculated first, then the mults.
    local returnVal = math.max((initialVal + adds) * mults, floor)

    return returnVal, bool
end

BuffEffects = table.merged(BuffEffects, {
    --- Energy maint override buff to keep track of cumulative changes
    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    EnergyMaintenanceOverride = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'EnergyMaintenanceOverride', 0)
        unit:SetEnergyMaintenanceConsumptionOverride(val)
        if val > 0 then
            if unit.MaintenanceConsumption then
                unit:UpdateConsumptionValues()
            else
                unit:SetMaintenanceConsumptionActive()
            end
        else
            unit:SetMaintenanceConsumptionInactive()
        end
    end,

    --- Override regen buff to use better buff calculation
    ---@param buffDefinition BlueprintBuff
    ---@param buffValues BlueprintBuffAffect
    ---@param unit Unit
    ---@param buffName BuffName
    Regen = function(buffDefinition, buffValues, unit, buffName)
        local val = BuffCalculate(unit, buffName, 'Regen', unit.Blueprint.Defense.RegenRate or 0)
        unit:SetRegen(val)
    end,

    -- `IntelComponent` has no interoperability functions with Buffs so I commented this buff out
    -- Useful functions would be:
    --  - `IsUnitIntelEnabled(IntelType): boolean`
    --  - `AddIntelToStatus(IntelType, boolean? MaintenanceFree)`

    -- not like it matters, since jamming is hardcoded in the unit blueprint for the engine,
    -- and the only thing that can be done is jamming turned on/off

    -- ---@param buffDefinition BlueprintBuff
    -- ---@param buffValues BlueprintBuffAffect
    -- ---@param unit Unit
    -- ---@param buffName BuffName
    -- ---@param instigator Unit
    -- ---@param afterRemove boolean
    -- JammerRadius = function(buffDefinition, buffValues, unit, buffName, instigator, afterRemove)
    --     local val = BuffCalculate(unit, buffName, 'JammerRadius', unit.Blueprint.Intel.JamRadius.Max or 0)
    --     if not unit:IsIntelEnabled('Jammer') then
    --         unit:InitIntel(unit.Army, 'Jammer', val)
    --         unit:EnableIntel('Jammer')
    --     else
    --         unit:SetIntelRadius('Jammer', val)
    --     end
    -- end,
})
