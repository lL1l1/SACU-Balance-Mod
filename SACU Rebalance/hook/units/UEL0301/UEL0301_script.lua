---@alias UEFSCUEnhancementBuffName
---| "UEFSCUBuildRate"
---| "UEFSCUMovementBonus"

---@alias UEFSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUMOVEMENTBONUS"

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias SCUEnhancementBuffType
---| AeonSCUEnhancementBuffType
---| CybranSCUEnhancementBuffType
---| UEFSCUEnhancementBuffType
---| SeraphimSCUEnhancementBuffType

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias SCUEnhancementBuffName
---| AeonSCUEnhancementBuffName
---| CybranSCUEnhancementBuffName
---| UEFSCUEnhancementBuffName
---| SeraphimSCUEnhancementBuffName

local Buff = import("/lua/sim/buff.lua")

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

local oldUEL0301 = UEL0301

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

        self.RadarJammerEnh = true
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
    --- Drone Upgrade
    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementPod = function(self, bp)
        if not Buffs['UEFSCUBuildRate'] then
            BuffBlueprint {
                Name = 'UEFSCUBuildRate',
                DisplayName = 'UEFSCUBuildRate',
                BuffType = 'SCUBUILDRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    BuildRate = {
                        Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
                        Mult = 1,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'UEFSCUBuildRate')

        oldUEL0301.ProcessEnhancementPod(self, bp)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementPodRemove = function(self, bp)
        if Buff.HasBuff(self, 'UEFSCUBuildRate') then
            Buff.RemoveBuff(self, 'UEFSCUBuildRate')
        end

        oldUEL0301.ProcessEnhancementPodRemove(self, bp)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedCoolingUpgrade = function(self, bp)
        if not Buffs['UEFSCUMovementBonus'] then
            BuffBlueprint {
                Name = 'UEFSCUMovementBonus',
                DisplayName = 'UEFSCUMovementBonus',
                BuffType = 'SCUMOVEMENTBONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MoveMult = {
                        Mult = bp.NewSpeedMult,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'UEFSCUMovementBonus') then
            Buff.RemoveBuff(self, 'UEFSCUMovementBonus')
        end
        Buff.ApplyBuff(self, 'UEFSCUMovementBonus')

        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:SetTurretYawSpeed(wep.Blueprint.TurretYawSpeed * bp.NewSpeedMult)

        oldUEL0301.ProcessEnhancementAdvancedCoolingUpgrade(self, bp)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedCoolingUpgradeRemove = function(self, bp)
        if Buff.HasBuff(self, 'UEFSCUMovementBonus') then
            Buff.RemoveBuff(self, 'UEFSCUMovementBonus')
        end

        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:SetTurretYawSpeed(wep.Blueprint.TurretYawSpeed)

        oldUEL0301.ProcessEnhancementAdvancedCoolingUpgradeRemove(self, bp)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnance = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius)
        wep:AddDamageMod(bp.NewDamageMod)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnanceRemove = function(self, bp)
        local enhBp = self.Blueprint.Enhancements['HighExplosiveOrdnance']
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageRadiusMod(-enhBp.NewDamageRadius)
        wep:AddDamageMod(-enhBp.NewDamageMod)
    end,
}

TypeClass = UEL0301

__moduleinfo.OnReload = function()
    -- Buffs are stored globally and only created once so they need to be reset on reload
    Buffs['UEFSCUBuildRate'] = nil
    Buffs['UEFSCUMovementBonus'] = nil
end
