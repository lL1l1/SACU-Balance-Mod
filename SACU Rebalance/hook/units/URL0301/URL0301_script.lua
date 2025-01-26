local oldURL0301 = URL0301

---@class URL0301_new : URL0301
URL0301 = ClassUnit(oldURL0301) {
    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        oldURL0301.ProcessEnhancementResourceAllocation(self, bp)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        deathNuke:AddDamageMod(bp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(bp.DeathWeaponRadiusAdd)
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        oldURL0301.ProcessEnhancementResourceAllocationRemove(self, bp)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        local baseBp = self.Blueprint.Enhancements["ResourceAllocation"]
        deathNuke:AddDamageMod(baseBp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(baseBp.DeathWeaponRadiusAdd)
    end,
}

TypeClass = URL0301
