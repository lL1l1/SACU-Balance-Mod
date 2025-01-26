local oldUEL0301 = UEL0301

---@class UEL0301_new : UEL0301
UEL0301 = ClassUnit(oldUEL0301) {
    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorField = function(self, bp)
        self:DestroyShield()
        self:ForkThread(function()
            WaitTicks(1)
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        end)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldGeneratorFieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
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
