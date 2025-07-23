---@alias UEFSCUEnhancementBuffName
---| "UEFSCUBuildRate"
---| "UEFSCUMovementBonus"
---| "UEFSCUPersonalShieldMaint"
---| "UEFSCUBubbleShieldMaint"
---| "UEFSCUSensorRange"
---| "UEFSCUSensorMaint"

---@alias UEFSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUMOVEMENTBONUS"
---| "SCUSHIELDMAINT"
---| "SCUSENSORRANGE"
---| "SCUSENSORMAINT"

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

---@type UEL0301
local oldUEL0301 = UEL0301

---@class UEL0301_new : UEL0301
UEL0301 = ClassUnit(oldUEL0301) {
    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        if not Buffs['UEFSCUPersonalShieldMaint'] then
            BuffBlueprint {
                Name = 'UEFSCUPersonalShieldMaint',
                DisplayName = 'UEFSCUPersonalShieldMaint',
                BuffType = 'SCUSHIELDMAINT',
                Stacks = 'IGNORE',
                Duration = -1,
                Affects = {
                    EnergyMaintenanceOverride = {
                        Add = bp.MaintenanceConsumptionPerSecondEnergy,
                        Mult = 1,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'UEFSCUPersonalShieldMaint')
        self:AddToggleCap('RULEUTC_ShieldToggle')
        -- Create shield after toggle cap so it can set the script bit
        self:CreateShield(bp)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function(self, bp)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
        self:DestroyShield()

        Buff.RemoveBuff(self, 'UEFSCUPersonalShieldMaint')
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorField = function(self, bp)
        if not Buffs['UEFSCUBubbleShieldMaint'] then
            BuffBlueprint {
                Name = 'UEFSCUBubbleShieldMaint',
                DisplayName = 'UEFSCUBubbleShieldMaint',
                BuffType = 'SCUSHIELDMAINT',
                Stacks = 'IGNORE',
                Duration = -1,
                Affects = {
                    EnergyMaintenanceOverride = {
                        Add = bp.MaintenanceConsumptionPerSecondEnergy,
                        Mult = 1,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'UEFSCUBubbleShieldMaint')
        self:AddToggleCap('RULEUTC_ShieldToggle')
        -- Create shield after toggle cap so it can set the script bit
        self:CreateShield(bp)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldGeneratorFieldRemove = function(self, bp)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
        self:DestroyShield()

        Buff.RemoveBuff(self, 'UEFSCUBubbleShieldMaint')
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        if not Buffs['UEFSCUSensorRange'] then
            local bpIntel = self.Blueprint.Intel
            BuffBlueprint {
                Name = 'UEFSCUSensorRange',
                DisplayName = 'UEFSCUSensorRange',
                BuffType = 'SCUSENSORRANGE',
                Stacks = 'IGNORE',
                Duration = -1,
                Affects = {
                    VisionRadius = {
                        Add = bp.NewVisionRadius - bpIntel.VisionRadius,
                        Mult = 1,
                    },
                    OmniRadius = {
                        Add = bp.NewOmniRadius - bpIntel.OmniRadius,
                        Mult = 1,
                    },
                },
            }
        end
        if not Buffs['UEFSCUSensorMaint'] then
            BuffBlueprint {
                Name = 'UEFSCUSensorMaint',
                DisplayName = 'UEFSCUSensorMaint',
                BuffType = 'SCUSENSORMAINT',
                Stacks = 'IGNORE',
                Duration = -1,
                Affects = {
                    EnergyMaintenanceOverride = {
                        Add = bp.MaintenanceConsumptionPerSecondEnergy,
                        Mult = 1,
                    },
                },
            }
        end

        -- For normal units maintenance comes first, then intel becomes enabled
        Buff.ApplyBuff(self, 'UEFSCUSensorMaint')
        -- enable flag before intel
        self.RadarJammerEnh = true
        -- this function will use the range buff
        self:EnableUnitIntel('Enhancement', 'Jammer')
        -- Add toggle after creating buff since it will set the script bit
        self:AddToggleCap('RULEUTC_JammingToggle')
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancerRemove = function(self, bp)
        self:DisableUnitIntel('Enhancement', 'Jammer')
        -- remove fx and range buff before disabling enhancement flag
        self:RemoveToggleCap('RULEUTC_JammingToggle')
        self.RadarJammerEnh = false

        Buff.RemoveBuff(self, 'UEFSCUSensorMaint')
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
        wep:AddDamageMod(bp.NewDamageMod)
    end,

    ---@param self UEL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnanceRemove = function(self, bp)
        local enhBp = self.Blueprint.Enhancements['HighExplosiveOrdnance']
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageMod(-enhBp.NewDamageMod)
    end,

    -- Override the shield and jamming toggles so that maintenance energy can be handled with Buffs
    ---@param self UEL0301_new
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 0 then -- Shield toggle on
            self:PlayUnitAmbientSound('ActiveLoop')
            self:EnableShield()
            if self:HasEnhancement('ShieldGeneratorField') then
                Buff.ApplyBuff(self, 'UEFSCUBubbleShieldMaint')
            else
                Buff.ApplyBuff(self, 'UEFSCUPersonalShieldMaint')
            end
        elseif bit == 2 then -- Jamming toggle off
            self:StopUnitAmbientSound('ActiveLoop')
            Buff.RemoveBuff(self, 'UEFSCUSensorMaint')
            -- Intel range upgrade handled in jammer intel disabling
            self:DisableUnitIntel('ToggleBit2', 'Jammer')
        else
            oldUEL0301.OnScriptBitSet(self, bit)
        end
    end,

    -- Override the shield and jamming toggles so that maintenance energy can be handled with Buffs
    ---@param self UEL0301_new
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 0 then -- Shield toggle off
            self:StopUnitAmbientSound('ActiveLoop')
            self:DisableShield()
            if self:HasEnhancement('ShieldGeneratorField') then
                Buff.RemoveBuff(self, 'UEFSCUBubbleShieldMaint')
            else
                Buff.RemoveBuff(self, 'UEFSCUPersonalShieldMaint')
            end
        elseif bit == 2 then -- Jamming toggle on
            self:PlayUnitAmbientSound('ActiveLoop')
            Buff.ApplyBuff(self, 'UEFSCUSensorMaint')
            -- Intel range upgrade handled in jammer intel enabling
            self:EnableUnitIntel('ToggleBit2', 'Jammer')
        else
            oldUEL0301.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self UEL0301_new
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CommandUnit.OnIntelEnabled(self, intel)
        -- check if we have jammer enh because jammer is enabled in OnStopBeingBuilt
        if intel == 'Jammer' and self.RadarJammerEnh then
            if self.IntelEffects then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end

            Buff.ApplyBuff(self, 'UEFSCUSensorRange')
        end
    end,

    ---@param self UEL0301_new
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CommandUnit.OnIntelDisabled(self, intel)
        -- check if we have jammer enh because jammer is disabled in OnStopBeingBuilt
        if intel == 'Jammer' and self.RadarJammerEnh then
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            end

            Buff.RemoveBuff(self, 'UEFSCUSensorRange')
        end
    end,
}

TypeClass = UEL0301

__moduleinfo.OnReload = function()
    -- Buffs are stored globally and only created once so they need to be reset on reload
    Buffs['UEFSCUBuildRate'] = nil
    Buffs['UEFSCUMovementBonus'] = nil
    Buffs['UEFSCUSensorRange'] = nil
    Buffs['UEFSCUSensorMaint'] = nil
end
