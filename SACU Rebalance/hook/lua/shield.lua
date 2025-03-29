-- very annoying way of overriding because all shield classes are in the same file,
-- so I can't override just once in the base class and then have the other classes 
-- inherit the override since they would be loaded after the hook
-- for example:
-- Single file for multiple classes:
-- Shield = Class() Shield2 = Class(Shield) hookCode
-- Separate files per class:
-- Shield = Class() hookCode Shield2 = Class(Shield)

do
    ---@diagnostic disable-next-line: circle-doc-class
    ---@class Shield : Shield
    ---@field ScriptedEnergyMaintenanceToggle boolean

    -- Every shield calls this function in their own OnCreate, so we only change it once

    --- Override to allow manual toggling of owner active maintenance
    ---@param self Shield
    ---@param spec unknown is this Entity?
    Shield.OnCreate = function(self, spec)
        -- cache information that is used frequently
        self.Army = EntityGetArmy(self)
        self.EntityId = EntityGetEntityId(self)
        self.Brain = spec.Owner:GetAIBrain()

        -- copy over information from specifiaction
        self.Size = spec.Size
        self.Owner = spec.Owner
        self.MeshBp = spec.Mesh
        self.MeshZBp = spec.MeshZ
        self.SpillOverDmgMod = spec.ShieldSpillOverDamageMod or 0.15
        self.ShieldRechargeTime = spec.ShieldRechargeTime or 5
        self.ShieldEnergyDrainRechargeTime = spec.ShieldEnergyDrainRechargeTime
        self.ShieldVerticalOffset = spec.ShieldVerticalOffset
        self.RegenRate = spec.ShieldRegenRate
        self.RegenStartTime = spec.ShieldRegenStartTime
        self.PassOverkillDamage = spec.PassOverkillDamage
        self.ImpactMeshBp = spec.ImpactMesh
        self.SkipAttachmentCheck = spec.SkipAttachmentCheck
        self.DisallowCollisions = false

        if spec.ImpactEffects ~= '' then
            self.ImpactEffects = EffectTemplate[spec.ImpactEffects]
        else
            self.ImpactEffects = {}
        end

        -- set some internal state related to shields
        self._IsUp = false
        self.ShieldType = 'Bubble'

        -- set our health
        EntitySetMaxHealth(self, spec.ShieldMaxHealth)
        EntitySetHealth(self, self, spec.ShieldMaxHealth)

        -- show our 'lifebar'
        self:UpdateShieldRatio(1.0)

        -- tell the engine when we should be visible
        EntitySetVizToFocusPlayer(self, 'Always')
        EntitySetVizToEnemies(self, 'Intel')
        EntitySetVizToAllies(self, 'Always')
        EntitySetVizToNeutrals(self, 'Intel')

        -- attach us to the owner
        EntityAttachBoneTo(self, -1, spec.Owner, -1)


        -- lookup whether we're a static shield for absorbing deathnukes with modded shields that don't have the value set
        local absorptionType = spec.AbsorptionType
        -- lookup whether we're a static or a commander shield for overcharge's fixed damage
        local ownerBp = self.Owner.Blueprint
        local ownerCategories = ownerBp.CategoriesHash
        if ownerCategories.STRUCTURE then
            self.StaticShield = true
            if not absorptionType then
                absorptionType = "StaticShield"
            end
        elseif ownerCategories.COMMAND then
            self.CommandShield = true
        end

        -- lookup our damage absorption type's table
        self.AbsorptionTypeDamageTypeToMulti = shieldAbsorptionValues[absorptionType or "Default"]

        -- use trashbag of the unit that owns us
        self.Trash = self.Owner.Trash

        -- manage impact entities
        self.LiveImpactEntities = 0
        self.ImpactEntitySpecs = { Owner = self.Owner }

        -- manage overlapping shields
        self.OverlappingShields = {}
        self.OverlappingShieldsCount = 0
        self.OverlappingShieldsTick = -1

        -- manage overspill
        self.DamagedTick = {}
        self.DamagedRegular = {}
        self.DamagedOverspill = {}

        -- manage regeneration thread
        self.RegenThreadSuspended = true
        self.RegenThreadState = "On"
        self.RegenThread = ForkThread(self.RegenThread, self)
        TrashAdd(self.Trash, self.RegenThread)

        -- manage the loss of shield when energy is depleted
        self.Brain:AddEnergyDependingEntity(self)

        -- by default, turn on maintenance and the toggle for the owner
        self.Enabled = true
        self.Recharged = true
        self.RolledFromFactory = false

        --#region Changes
        if not spec.ScriptedEnergyMaintenanceToggle then
            self.Owner:SetMaintenanceConsumptionActive()
        else
            self.ScriptedEnergyMaintenanceToggle = true
        end
        --#endregion

        UnitSetScriptBit(self.Owner, 'RULEUTC_ShieldToggle', true)

        -- then check if we can actually turn it on
        if not self.Brain.EnergyDepleted then
            self:OnEnergyViable()
        else
            self:OnEnergyDepleted()
        end
    end

    -- States are unchanged for these 4 so they need to be set manually
    -- 2 other shields call their base class properly
    for _, class in {
        Shield,
        PersonalShield,
        AntiArtilleryShield,
        CzarShield
    } do
        --- Override to allow manual toggling of owner active maintenance
        class.OnState.Main = function(self)

            -- always start consuming energy at this point
            self.Enabled = true

            --#region Changes
            if not self.ScriptedEnergyMaintenanceToggle then
                self.Owner:SetMaintenanceConsumptionActive()
            end
            --#endregion

            -- if we're attached to a transport then our shield should be off
            if (not self.SkipAttachmentCheck) and (UnitIsUnitState(self.Owner, 'Attached') and self.RolledFromFactory) then
                ChangeState(self, self.OffState)

                -- if we're still out of energy, go wait for that to fix itself
            elseif self.NoEnergyToSustain then
                ChangeState(self, self.EnergyDrainedState)

                -- if we are depleted for some reason, go fix that first
            elseif self.DepletedByEnergy or self.DepletedByDamage or not self.Recharged then
                ChangeState(self, self.RechargeState)

                -- we're all good, go shield things
            else

                -- unsuspend the regeneration thread
                if self.RegenThreadSuspended then
                    ResumeThread(self.RegenThread)
                end

                -- introduce the shield bar
                self:UpdateShieldRatio(-1)
                self:CreateShieldMesh()

                -- inform owner that the shield is enabled
                self.Owner:OnShieldEnabled()
                self.Owner:PlayUnitSound('ShieldOn')
            end

            -- mobile shields are 'attached' to the factory when they are build, this allows
            -- us to skip the first check of whether we're attached to a transport
            self.RolledFromFactory = true
        end
        --- Override to allow manual toggling of owner active maintenance
        class.OffState.Main = function(self)

            -- update internal state
            self.Enabled = false
            self.Recharged = false

            --#region Changes
            if not self.ScriptedEnergyMaintenanceToggle then
                self.Owner:SetMaintenanceConsumptionInactive()
            end
            --#endregion

            -- remove the shield and the shield bar
            self:RemoveShield()
            self:UpdateShieldRatio(0)

            -- inform the owner that the shield is disabled
            self.Owner:OnShieldDisabled()
            self.Owner:PlayUnitSound('ShieldOff')
        end
    end
end
