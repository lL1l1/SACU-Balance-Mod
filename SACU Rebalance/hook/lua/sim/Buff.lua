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
