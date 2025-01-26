local oldUAL0301 = UAL0301

---@class UAL0301_new : UAL0301
UAL0301 = ClassUnit(oldUAL0301) {
    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        oldUAL0301.ProcessEnhancementResourceAllocation(self, bp)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        deathNuke:AddDamageMod(bp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(bp.DeathWeaponRadiusAdd)
    end,

    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        oldUAL0301.ProcessEnhancementResourceAllocationRemove(self, bp)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        local baseBp = self.Blueprint.Enhancements["ResourceAllocation"]
        deathNuke:AddDamageMod(baseBp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(baseBp.DeathWeaponRadiusAdd)
    end,

}

TypeClass = UAL0301
