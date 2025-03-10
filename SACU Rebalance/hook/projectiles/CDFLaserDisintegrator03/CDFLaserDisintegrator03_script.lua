local oldProj = CDFLaserDisintegrator03
--- Cybran Disintegrator Laser
---@class CDFLaserDisintegrator03_new : CDFLaserDisintegrator03
CDFLaserDisintegrator03 = ClassProjectile(oldProj) {

    ---@param self CDFLaserDisintegrator03_new
    ---@param army number
    ---@param EffectTable table
    ---@param EffectScale number
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local launcher = self.Launcher
        if launcher and launcher:HasEnhancement('FocusConvertor') then -- check for focus convertor instead of emp charge
            -- remove red circle light particle
            -- keep red light emitter
            CreateEmitterAtEntity(self, self.Army,'/effects/emitters/cybran_empgrenade_hit_03_emit.bp')
        end
        CDisintegratorLaserProjectile.CreateImpactEffects(self, army, EffectTable, EffectScale)
    end,
}

TypeClass = CDFLaserDisintegrator03

