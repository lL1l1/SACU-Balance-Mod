--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

--- kept for mod backwards compatibility
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

local EffectTemplate = import("/lua/effecttemplates.lua")
local utilities = import('/lua/utilities.lua')
local ApplyBuff = import('/lua/sim/Buff.lua').ApplyBuff

local SACUChronoBuffName = "AeonSACUChronoDampener"

---@alias AeonSCUEnhancementBuffName
---| "AeonSACUChronoDampener"

---@alias AeonSCUEnhancementBuffType
---| "TimeDilationDebuff"

---@class ADFChronoDampener02 : DefaultProjectileWeapon
---@field OriginalFxMuzzleFlashScale number
---@field CategoriesToStun EntityCategory
---@field Blueprint WeaponBlueprint | { ChronoDampenerParams: ChronoDampenerParams }
---@field ChronoBuffName string
ADFChronoDampener02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AChronoDampenerLarge,
    FxMuzzleFlashScale = 0.5,
    FxUnitStun = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleCharge,
    FxUnitStunFlash = EffectTemplate.Aeon_HeavyDisruptorCannonUnitHit,

    ---@param self ADFChronoDampener02
    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)
        -- Stores the original FX scale so it can be adjusted by range changes
        self.OriginalFxMuzzleFlashScale = self.FxMuzzleFlashScale

        local params = self.Blueprint.ChronoDampenerParams
        self.CategoriesToStun = ParseEntityCategory(params.TargetAllow) - ParseEntityCategory(params.TargetDisallow)
        self.ChronoBuffName = SACUChronoBuffName
        if not Buffs[SACUChronoBuffName] then
            BuffBlueprint {
                Name = SACUChronoBuffName,
                DisplayName = "SACU Chrono Dampening",
                BuffType = 'TimeDilationDebuff',
                Stacks = 'ALWAYS',
                Duration = params.Duration,
                Affects = table.deepcopy(params.Affects)
            }
        end
    end,

    ---@param self ADFChronoDampener02
    ---@param muzzle string
    CreateProjectileAtMuzzle = function(self, muzzle)
        local bp = self.Blueprint

        if bp.Audio.Fire then
            self:PlaySound(bp.Audio.Fire)
        end

        self.Trash:Add(ForkThread(self.ExpandingStunThread, self))
    end,

    --- EFfect to play as a unit is stunned
    ---@param self ADFChronoDampener02
    ---@param target Unit
    PlayStunEffect = function(self, target)
        local count = target:GetBoneCount()
        for k, effect in self.FxUnitStun do
            local emit = CreateEmitterAtBone(
                target, Random(0, count - 1), target.Army, effect
            )

            -- scale the effect a bit
            emit:ScaleEmitter(0.5)

            -- change lod to match outer lod of unit
            local lods = target.Blueprint.Display.Mesh.LODs
            if lods then
                emit:SetEmitterParam("LODCUTOFF", lods[table.getn(lods)].LODCutoff)
            end
        end
    end,

    --- Effect to play once per unit
    ---@param self ADFChronoDampener02
    ---@param target Unit
    ---@param scale number
    PlayInitialStunEffect = function(self, target, scale)
        -- add initial flash effect
        for _, effect in self.FxUnitStunFlash do
            local emit = CreateEmitterOnEntity(target, target.Army, effect)
            emit:ScaleEmitter(scale * math.max(target.Blueprint.SizeX, target.Blueprint.SizeZ))
        end

        -- add initial stun effect on target
        local count = target:GetBoneCount()
        for _, effect in self.FxUnitStun do
            local emit = CreateEmitterAtBone(
                target, Random(0, count - 1), target.Army, effect
            )

            -- scale the effect a bit
            emit:ScaleEmitter(0.5)

            -- change lod to match outer lod of unit
            local lods = target.Blueprint.Display.Mesh.LODs
            if lods then
                emit:SetEmitterParam("LODCUTOFF", lods[table.getn(lods)].LODCutoff)
            end
        end
    end,

    ---@param self ADFChronoDampener02
    ---@param target Unit
    ---@return boolean
    ApplyUnitDebuff = function(self, target)
        if not target or target.Dead or IsDestroyed(target) then
            return false
        end

        ApplyBuff(target, self.ChronoBuffName)

        return true
    end,

    --- Thread to avoid waiting in the firing cycle and stalling the main cannon.
    ---@param self ADFChronoDampener02
    ExpandingStunThread = function(self)
        local bp = self.Blueprint
        local reloadTimeTicks = MATH_IRound(10 / bp.RateOfFire)
        local params = bp.ChronoDampenerParams
        local stunDuration = params.ExpandDuration
        local maxRadius = self:GetMaxRadius()
        local slices = 10
        local radiusPerSlice = maxRadius / slices
        local sliceTime = stunDuration * 10 / slices + 1
        local debuffApplied = {}

        for i = 1, slices do
            local radius = i * radiusPerSlice

            local targets = utilities.GetTrueEnemyUnitsInSphere(
            ---@diagnostic disable-next-line: param-type-mismatch
                self,
                self.unit:GetPosition(),
                radius,
                self.CategoriesToStun
            )
            local fxUnitStunFlashScale = (0.5 + (slices - i) / (slices - 1) * 1.5)

            for _, target in targets do
                -- add stun effect only on targets our Chrono Dampener stunned
                if debuffApplied[target] then
                    self:PlayStunEffect(target)
                    continue
                end

                local buffApplied = self:ApplyUnitDebuff(target)

                if buffApplied then
                    self:PlayInitialStunEffect(target, fxUnitStunFlashScale)
                    debuffApplied[target] = true
                end
            end

            WaitTicks(sliceTime)
        end
    end,

    ---@param self ADFChronoDampener02
    ---@param radius number
    ChangeMaxRadius = function(self, radius)
        DefaultProjectileWeapon.ChangeMaxRadius(self, radius)
        self.FxMuzzleFlashScale = self.OriginalFxMuzzleFlashScale * radius / self.Blueprint.MaxRadius
    end,
}

__moduleinfo.OnReload = function()
    Buffs[SACUChronoBuffName] = nil
end
