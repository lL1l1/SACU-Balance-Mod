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
