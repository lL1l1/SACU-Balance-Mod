local oldUEL0301 = UEL0301

---@param self Unit
---@param amount number
local function AddToEnergyMaintOverride(self, amount)
    if not amount then return end
    local newEnergy = (self.EnergyMaintenanceConsumptionOverride or 0) + amount
    self:SetEnergyMaintenanceConsumptionOverride(newEnergy)
    if newEnergy > 0 then
        if self.MaintenanceConsumption then
            self:UpdateConsumptionValues()
        else
            self:SetMaintenanceConsumptionActive()
        end
    else
        self:SetMaintenanceConsumptionInactive()
    end
end

---@class UEL0301_new : UEL0301
UEL0301 = ClassUnit(oldUEL0301) {
    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        AddToEnergyMaintOverride(self, bp.MaintenanceConsumptionPerSecondEnergy)
        self:CreateShield(bp)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function(self, bp)
        RemoveUnitEnhancement(self, 'Shield')
        self:DestroyShield()
        AddToEnergyMaintOverride(self, -self.Blueprint.Enhancements["Shield"].MaintenanceConsumptionPerSecondEnergy)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorField = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        AddToEnergyMaintOverride(self, bp.MaintenanceConsumptionPerSecondEnergy)
        self:CreateShield(bp)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldGeneratorFieldRemove = function(self, bp)
        self:DestroyShield()
        AddToEnergyMaintOverride(self, -self.Blueprint.Enhancements["ShieldGeneratorField"].MaintenanceConsumptionPerSecondEnergy)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        oldUEL0301.ProcessEnhancementSensorRangeEnhancer(self, bp)
        self:SetIntelRadius('Jammer', bp.NewJammerRadius or 26)
        self:EnableUnitIntel('Enhancement', 'Jammer')
        self:AddToggleCap('RULEUTC_JammingToggle')
        AddToEnergyMaintOverride(self, bp.MaintenanceConsumptionPerSecondEnergy)
        if self.IntelEffects then
            self.IntelEffectsBag = {}
            self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
        end
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancerRemove = function(self, bp)
        oldUEL0301.ProcessEnhancementSensorRangeEnhancerRemove(self, bp)

        self.RadarJammerEnh = false
        self:SetIntelRadius('Jammer', 0)
        self:DisableUnitIntel('Enhancement', 'Jammer')
        self:RemoveToggleCap('RULEUTC_JammingToggle')
        AddToEnergyMaintOverride(self, -self.Blueprint.Enhancements["SensorRangeEnhancer"].MaintenanceConsumptionPerSecondEnergy)
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        end
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        oldUEL0301.ProcessEnhancementResourceAllocation(self, bp)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        deathNuke:AddDamageMod(bp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(bp.DeathWeaponRadiusAdd)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        oldUEL0301.ProcessEnhancementResourceAllocationRemove(self, bp)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        local baseBp = self.Blueprint.Enhancements["ResourceAllocation"]
        deathNuke:AddDamageMod(baseBp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(baseBp.DeathWeaponRadiusAdd)
    end,
}

TypeClass = UEL0301
