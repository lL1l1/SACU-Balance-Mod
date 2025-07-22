local modPath = "/mods/SACU Rebalance"
local ADFChronoDampener02 = import(modPath .. "/ADFChronoDampener02.lua").ADFChronoDampener02

local oldUAL0301 = UAL0301
local oldWeapons = oldUAL0301.Weapons

---@class UAL0301_new : UAL0301
UAL0301 = ClassUnit(oldUAL0301) {
    Weapons = table.merged(oldWeapons, {
        ChronoDampener = ClassWeapon(ADFChronoDampener02) {},
    }),

    ---@param self UAL0301_new
    OnCreate = function(self)
        oldUAL0301.OnCreate(self)
        self:SetWeaponEnabledByLabel("ChronoDampener", false)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldHeavy = function(self, bp)
        ForkThread(function()
            WaitTicks(1)
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        end)
    end,


    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementChronoDampener = function (self, bp)
        self:SetWeaponEnabledByLabel("ChronoDampener", true)
    end,

    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementChronoDampenerRemove = function (self, bp)
        self:SetWeaponEnabledByLabel("ChronoDampener", false)
    end,

    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStabilitySuppressant = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:AddDamageMod(bp.NewDamageMod or 0)
        wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
    end,

    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStabilitySuppressantRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        local enhBp = self.Blueprint.Enhancements["StabilitySuppressant"]
        wep:AddDamageMod(-enhBp.NewDamageMod or 0)
        wep:AddDamageRadiusMod(-enhBp.NewDamageRadiusMod or 0)
    end,

    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementGunRange = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:ChangeMaxRadius(bp.NewMaxRadius)
    end,

    ---@param self UAL0301_new
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementGunRangeRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:ChangeMaxRadius(wep.Blueprint.MaxRadius)
    end,

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
