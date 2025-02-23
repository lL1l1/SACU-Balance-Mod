local oldXSL0301 = XSL0301 --[[@as XSL0301]]

---@class XSL0301_new : XSL0301
XSL0301 = ClassUnit(oldXSL0301) {
    ---@param self XSL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        deathNuke:AddDamageMod(bp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(bp.DeathWeaponRadiusAdd)
    end,

    ---@param self XSL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)

        local deathNuke = self:GetWeaponByLabel("DeathWeapon") --[[@as SCUDeathWeapon]]
        local baseBp = self.Blueprint.Enhancements["ResourceAllocation"]
        deathNuke:AddDamageMod(baseBp.DeathWeaponDamageAdd)
        deathNuke:AddDamageRadiusMod(baseBp.DeathWeaponRadiusAdd)
    end,

    ---@param self XSL0301_new
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementEnhancedSensors = function(self, bp)
        oldXSL0301.ProcessEnhancementEnhancedSensors(self, bp)
        local wep = self:GetWeaponByLabel('LightChronatronCannon')
        wep:AddDamageMod(bp.NewDamageMod)
    end,

    ---@param self XSL0301_new
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementEnhancedSensorsRemove = function(self, bp)
        oldXSL0301.ProcessEnhancementEnhancedSensorsRemove(self, bp)
        local enhBp = self.Blueprint.Enhancements['EnhancedSensors']
        local wep = self:GetWeaponByLabel('LightChronatronCannon')
        wep:AddDamageMod(-enhBp.NewDamageMod)
    end,

}

TypeClass = XSL0301
