---@alias SeraphimSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUUPGRADEDMG"
---| "SCUREGENAURA"
---| "SCUMAXHEALTHAURA"

---@alias SeraphimSCUEnhancementBuffName      # BuffType
---| "SeraphimSCUDamageStabilization"         # SCUUPGRADEDMG
---| "SeraphimSCUBuildRate"                   # SCUBUILDRATE
---| "SeraphimSCURegenAura"                   # SCUREGENAURA
---| "SeraphimSCUMaxHealthAura"               # SCUMAXHEALTHAURA

local oldXSL0301 = XSL0301 --[[@as XSL0301]]

---@class XSL0301_new : XSL0301
---@field RegenAuraEffectsBag moho.IEffect[]
---@field RegenAuraThreadHandle? thread
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

    ---@param self XSL0301_new
    RegenAuraThread = function(self)
        local brain = self.Brain
        local bp = self.Blueprint.Enhancements['RegenAura']
        local buffCategories = ParseEntityCategory(bp.UnitCategory)
        local buffRadius = bp.Radius
        local posReused = {}

        while not self.Dead do
            posReused[1], posReused[2], posReused[3] = self:GetPositionXYZ()
            local units = brain:GetUnitsAroundPoint(buffCategories, posReused, buffRadius, 'Ally')
            for _, unit in units do
                if unit.Dead or not unit.isFinishedUnit then continue end
                Buff.ApplyBuff(unit, "SeraphimSCURegenAura")
                Buff.ApplyBuff(unit, "SeraphimSCUMaxHealthAura")
                unit:RequestRefreshUI()
            end
            WaitTicks(51)
        end
    end,

    ---@param self XSL0301_new
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementRegenAura = function(self, bp)
        if not Buffs['SeraphimSCURegenAura'] then
            BuffBlueprint {
                Name = 'SeraphimSCURegenAura',
                DisplayName = 'SeraphimSCURegenAura',
                BuffType = 'SACUREGENAURA',
                Stacks = 'ALWAYS',
                Duration = 5,
                Affects = {
                    Regen = {
                        Add = bp.RegenAdd,
                        BPCeilings = {
                            TECH1 = bp.RegenCeilingT1,
                            TECH2 = bp.RegenCeilingT2,
                            TECH3 = bp.RegenCeilingT3,
                            EXPERIMENTAL = bp.RegenCeilingT4,
                            SUBCOMMANDER = bp.RegenCeilingSCU,
                        },
                    },
                },
            }
        end
        if not Buffs['SeraphimSCUMaxHealthAura'] then
            BuffBlueprint {
                Name = 'SeraphimSCUMaxHealthAura',
                DisplayName = 'SeraphimSCUMaxHealthAura',
                BuffType = 'SACUMAXHEALTHAURA',
                Stacks = 'REPLACE',
                Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
                Duration = 5,
                Affects = {
                    MaxHealth = {
                        Add = 0,
                        Mult = bp.MaxHealthFactor,
                        DoNotFill = true,
                    },
                },
            }
        end
        self.RegenAuraThreadHandle = self:ForkThread(self.RegenAuraThread)

        if not self.RegenAuraEffectsBag then self.RegenAuraEffectsBag = {} end
        table.insert(self.RegenAuraEffectsBag, CreateAttachedEmitter(self, 'XSL0301', self.Army, '/effects/emitters/seraphim_regenerative_aura_01_emit.bp'))
    end,

    ---@param self XSL0301_new
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementRegenAuraRemove = function(self, bp)
        for _, effect in self.RegenAuraEffectsBag do
            effect:Destroy()
        end

        KillThread(self.RegenAuraThreadHandle)
        self.RegenAuraThreadHandle = nil
    end,

    ---@param self XSL0301_new
    DestroyAllTrashBags = function (self)
        if self.RegenAuraEffectsBag then
            for _, effect in self.RegenAuraEffectsBag do
                effect:Destroy()
            end
        end
        oldXSL0301.DestroyAllTrashBags(self)
    end
}

TypeClass = XSL0301

__moduleinfo.OnReload = function()
    -- Buffs are stored globally and only created once so they need to be reset on reload
    Buffs['SeraphimSCURegenAura'] = nil
    Buffs['SeraphimSCUMaxHealthAura'] = nil
end
