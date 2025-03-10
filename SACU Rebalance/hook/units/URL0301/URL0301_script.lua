local OverchargeWeapon = import("/lua/sim/weapons/OverchargeWeapon.lua").OverchargeWeapon
local CDFHeavyMicrowaveLaserGeneratorCom = import("/lua/sim/weapons/cybran/CDFHeavyMicrowaveLaserGeneratorCom.lua").CDFHeavyMicrowaveLaserGeneratorCom
local CANTorpedoLauncherWeapon = import("/lua/sim/weapons/cybran/CANTorpedoLauncherWeapon.lua").CANTorpedoLauncherWeapon

local oldURL0301 = URL0301 --[[@as URL0301]]
local oldWeapons = oldURL0301.Weapons

---@class URL0301_new : URL0301
---@field NormalRange number # caches gun range to adjust the unit AI controller dummy weapon's range on layer change depending on active enhancements
---@field TorpRange number # caches torpedo range to adjust the unit AI controller dummy weapon's range on layer change depending on active enhancements
---@field BuildRate number
URL0301 = ClassUnit(oldURL0301) {
    Weapons = table.merged(oldWeapons, {
        OverCharge = ClassWeapon(OverchargeWeapon) {
            DesiredWeaponLabel = "RightDisintegrator",
        },
        AutoOverCharge = ClassWeapon(OverchargeWeapon) {
            DesiredWeaponLabel = "RightDisintegrator",
        },
        ---@class URL0301_MLG : CDFHeavyMicrowaveLaserGeneratorCom
        MLG = ClassWeapon(CDFHeavyMicrowaveLaserGeneratorCom) {
            DisabledFiringBones = {
                "Right_Elbow",
            },
        },
        NTorpedo = ClassWeapon(CANTorpedoLauncherWeapon) {},
    }),

    ---@param self URL0301_new
    OnCreate = function(self)
        oldURL0301.OnCreate(self)
        self:GetWeaponByLabel("OverCharge").NeedsUpgrade = true
        self:GetWeaponByLabel("AutoOverCharge").NeedsUpgrade = true

        self:SetWeaponEnabledByLabel("MLG", false)

        self.NormalRange = self:GetWeaponByLabel("RightDisintegrator").Blueprint.MaxRadius or 25
        self.TorpRange = self:GetWeaponByLabel("NTorpedo").Blueprint.MaxRadius or 60
    end,

    ---@param self URL0301_new
    ---@param rate number
    AddBuildRate = function(self, rate)
        self:SetBuildRate(self.BuildRate + rate)
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEMPCharge = function(self, bp)
        self:AddCommandCap("RULEUCC_Overcharge")
        self:GetWeaponByLabel("OverCharge").NeedsUpgrade = false
        self:GetWeaponByLabel("AutoOverCharge").NeedsUpgrade = false
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEMPChargeRemove = function(self, bp)
        self:RemoveCommandCap("RULEUCC_Overcharge")
        self:SetWeaponEnabledByLabel("OverCharge", false)
        self:SetWeaponEnabledByLabel("AutoOverCharge", false)
        self:GetWeaponByLabel("OverCharge").NeedsUpgrade = true
        self:GetWeaponByLabel("AutoOverCharge").NeedsUpgrade = true
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFocusConvertor = function(self, bp)
        local newMaxRadius = bp.NewMaxRadius or 35
        local dummy = self:GetWeaponByLabel("DummyWeapon") --[[@as Weapon]]
        local wep = self:GetWeaponByLabel("RightDisintegrator") --[[@as Weapon]]
        local oc = self:GetWeaponByLabel("OverCharge") --[[@as Weapon]]
        local aoc = self:GetWeaponByLabel("AutoOverCharge") --[[@as Weapon]]
        local mlg = self:GetWeaponByLabel("MLG") --[[@as Weapon]]
        dummy:ChangeMaxRadius(newMaxRadius)
        self.NormalRange = newMaxRadius
        wep:ChangeMaxRadius(newMaxRadius)
        oc:ChangeMaxRadius(newMaxRadius)
        aoc:ChangeMaxRadius(newMaxRadius)
        mlg:ChangeMaxRadius(newMaxRadius)

        wep:AddDamageMod(bp.NewDamageMod or 0)
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFocusConvertorRemove = function(self, bp)
        local dummy = self:GetWeaponByLabel("DummyWeapon") --[[@as Weapon]]
        local wep = self:GetWeaponByLabel("RightDisintegrator") --[[@as Weapon]]
        local oc = self:GetWeaponByLabel("OverCharge") --[[@as Weapon]]
        local aoc = self:GetWeaponByLabel("AutoOverCharge") --[[@as Weapon]]
        local mlg = self:GetWeaponByLabel("MLG") --[[@as Weapon]]

        local newMaxRadius = wep.Blueprint.MaxRadius

        dummy:ChangeMaxRadius(newMaxRadius)
        self.NormalRange = newMaxRadius
        wep:ChangeMaxRadius(newMaxRadius)
        oc:ChangeMaxRadius(newMaxRadius)
        aoc:ChangeMaxRadius(newMaxRadius)
        mlg:ChangeMaxRadius(newMaxRadius)
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementMicrowaveLaserGenerator = function(self, bp)
        self:SetWeaponEnabledByLabel("MLG", true)
        self:SetWeaponEnabledByLabel("RightDisintegrator", false)
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementMicrowaveLaserGeneratorRemove = function(self, bp)
        self:SetWeaponEnabledByLabel("MLG", false)
        self:SetWeaponEnabledByLabel("RightDisintegrator", true)
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementNaniteMissileSystem = function(self, bp)
        self:ShowBone("AA_Gun", true)
        self:SetWeaponEnabledByLabel("NMissile", true)
        self:SetWeaponEnabledByLabel("NTorpedo", true)

        if self.Layer == "Seabed" then
            self:GetWeaponByLabel("DummyWeapon"):ChangeMaxRadius(self.TorpRange)
        end
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementNaniteMissileSystemRemove = function(self, bp)
        self:HideBone("AA_Gun", true)
        self:SetWeaponEnabledByLabel("NMissile", false)
        self:SetWeaponEnabledByLabel("NTorpedo", false)

        if self.Layer == "Seabed" then
            self:GetWeaponByLabel("DummyWeapon"):ChangeMaxRadius(self.NormalRange)
        end
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthGenerator = function(self, bp)
        self:AddToggleCap('RULEUTC_StealthToggle')
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        self.HasStealthEnh = true
        self:EnableUnitIntel('Enhancement', 'RadarStealth')
        self:EnableUnitIntel('Enhancement', 'SonarStealth')

        if not Buffs['CybranSCUStealthBonus'] then
            BuffBlueprint {
                Name = 'CybranSCUStealthBonus',
                DisplayName = 'CybranSCUStealthBonus',
                BuffType = 'SCUSTEALTHBONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.NewHealth,
                        Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end
        Buff.ApplyBuff(self, 'CybranSCUStealthBonus')
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSelfRepairSystem = function(self, bp)
        if not Buffs['CybranSCURegenerateBonus'] then
            BuffBlueprint {
                Name = 'CybranSCURegenerateBonus',
                DisplayName = 'CybranSCURegenerateBonus',
                BuffType = 'SCUREGENERATEBONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    Regen = {
                        Add = bp.NewRegenRate,
                        Mult = 1.0,
                    },
                    MaxHealth = {
                        Add = bp.NewHealth,
                        Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
            Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
        end
        Buff.ApplyBuff(self, 'CybranSCURegenerateBonus')
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthGeneratorRemove = function(self, bp)
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self.HasStealthEnh = false
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end
    end,

    ---@param self URL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSelfRepairSystemRemove = function(self, bp)
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self.HasStealthEnh = false
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end

        if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
            Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCloakingGeneratorRemove = function(self, bp)
        -- remove prerequisites
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end

        if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
            Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
        end

        -- remove cloak
        self:DisableUnitIntel('Enhancement', 'Cloak')
        self.HasCloakEnh = false
        self:RemoveToggleCap('RULEUTC_CloakToggle')
        if Buff.HasBuff(self, 'CybranSCUCloakBonus') then
            Buff.RemoveBuff(self, 'CybranSCUCloakBonus')
        end
    end,

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

    --- Makes sure the SACU walks into the correct range for the target when it has/doesn't have the torpedo enhancement.
    ---@param self URL0301_new
    ---@param new Layer
    ---@param old Layer
    OnLayerChange = function(self, new, old)
        oldURL0301.OnLayerChange(self, new, old)
        if self:GetWeaponByLabel('DummyWeapon') == nil then return end
        if new == "Seabed" and self:HasEnhancement('NaniteMissileSystem') then
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.TorpRange)
        else
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.NormalRange)
        end
    end,

        ---@param self URL0301
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CCommandUnit.OnIntelEnabled(self, intel)
        if self.HasCloakEnh and self:IsIntelEnabled('Cloak') then
            local bpEnh = self.Blueprint.Enhancements
            -- the construction UI interprets enhancement costs as stacked up
            local combinedCost = (bpEnh['CloakingGenerator'].MaintenanceConsumptionPerSecondEnergy or 0)
                + (bpEnh['StealthGenerator'].MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetEnergyMaintenanceConsumptionOverride(combinedCost)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        elseif self.HasStealthEnh and self:IsIntelEnabled('RadarStealth') and self:IsIntelEnabled('SonarStealth') then
            self:SetEnergyMaintenanceConsumptionOverride(self.Blueprint.Enhancements['StealthGenerator'].MaintenanceConsumptionPerSecondEnergy
                or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Field, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        end
    end,

}

TypeClass = URL0301

__moduleinfo.OnReload = function()
    -- Buffs are stored globally and only created once so they need to be reset on reload
    Buffs['CybranSCUStealthBonus'] = nil
    Buffs['CybranSCUCloakBonus'] = nil
    Buffs['CybranSCUBuildRate'] = nil
    Buffs['CybranSCURegenerateBonus'] = nil
end
