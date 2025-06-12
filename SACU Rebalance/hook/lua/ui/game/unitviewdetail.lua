-- Have to overwrite this unhookable beast to fix nil enhancement display

---@param bp UnitBlueprint
---@param builder UserUnit
---@param descID string
---@param control Control
function WrapAndPlaceText(bp, builder, descID, control)
    local lines = {}
    local blocks = {}
    --Unit description
    local text = LOC(UnitDescriptions[descID])
    if text and text ~='' then
        table.insert(blocks, {color = UIUtil.fontColor,
            lines = WrapText(text, control.Value[1].Width(), function(text)
                return control.Value[1]:GetStringAdvance(text)
            end)})
        table.insert(blocks, {color = UIUtil.bodyColor, lines = {''}})
    end

    if builder and bp.EnhancementPresetAssigned then
        table.insert(lines, LOC('<LOC uvd_upgrades>')..':')
        for _, v in bp.EnhancementPresetAssigned.Enhancements do
--#region Fix starts here
            local enhName = LOC(bp.Enhancements[v].Name)
            if enhName then
                table.insert(lines, '    ' .. enhName)
            end
--#endregion
        end
        table.insert(blocks, {color = 'FFB0FFB0', lines = lines})
    elseif bp then
        --Get not autodetected abilities
        if bp.Display.Abilities then
            for _, id in bp.Display.Abilities do
                local ability = ExtractAbilityFromString(id)
                if not IsAbilityExist[ability] then
                    table.insert(lines, LOC(id))
                end
            end
        end
        --Autodetect abilities exclude engineering
        for id, func in IsAbilityExist do
            if (id ~= 'ability_engineeringsuite') and (id ~= 'ability_building') and
               (id ~= 'ability_repairs') and (id ~= 'ability_reclaim') and (id ~= 'ability_capture') and func(bp) then
                local ability = LOC('<LOC '..id..'>')
                if GetAbilityDesc[id] then
                    local desc = GetAbilityDesc[id](bp)
                    if desc ~= '' then
                        ability = ability..' - '..desc
                    end
                end
                table.insert(lines, ability)
            end
        end
        if not table.empty(lines) then
            table.insert(lines, '')
        end
        table.insert(blocks, {color = 'FF7FCFCF', lines = lines})
        --Autodetect engineering abilities
        if IsAbilityExist.ability_engineeringsuite(bp) then
            lines = {}
            table.insert(lines, LOC('<LOC '..'ability_engineeringsuite'..'>')
                ..' - '..LOCF('<LOC uvd_BuildRate>', bp.Economy.BuildRate)
                ..', '..LOCF('<LOC uvd_Radius>', bp.Economy.MaxBuildDistance))
            local orders = LOC('<LOC order_0011>')
            if IsAbilityExist.ability_building(bp) then
                orders = orders..', '..LOC('<LOC order_0001>')
            end
            if IsAbilityExist.ability_repairs(bp) then
                orders = orders..', '..LOC('<LOC order_0005>')
            end
            if IsAbilityExist.ability_reclaim(bp) then
                orders = orders..', '..LOC('<LOC order_0006>')
            end
            if IsAbilityExist.ability_capture(bp) then
                orders = orders..', '..LOC('<LOC order_0007>')
            end
            table.insert(lines, orders)
            table.insert(lines, '')
            table.insert(blocks, {color = 'FFFFFFB0', lines = lines})
        end

        if options.gui_render_armament_detail == 1 then
            --Armor values
            lines = {}
            local armorType = bp.Defense.ArmorType
            if armorType and armorType ~= '' then
                local spaceWidth = control.Value[1]:GetStringAdvance(' ')
                local headerString = LOC('<LOC uvd_ArmorType>')..LOC('<LOC at_'..armorType..'>')
                local spaceCount = (195 - control.Value[1]:GetStringAdvance(headerString)) / spaceWidth
                local takesAdjustedDamage = false
                for _, armor in armorDefinition do
                    if armor[1] == armorType then
                        local row = 0
                        local armorDetails = ''
                        local elemCount = table.getsize(armor)
                        for i = 2, elemCount do
                            if string.find(armor[i], '1.0') > 0 then continue end
                            takesAdjustedDamage = true
                            local armorName = armor[i]
                            armorName = string.sub(armorName, 1, string.find(armorName, ' ') - 1)
                            armorName = LOC('<LOC an_'..armorName..'>')..' - '..string.format('%0.1f', tonumber(armor[i]:sub(armorName:len() + 2, armor[i]:len())) * 100)
                            if row < 1 then
                                armorDetails = armorName
                                row = 1
                            else
                                local spaceCount = (195 - control.Value[1]:GetStringAdvance(armorDetails)) / spaceWidth
                                armorDetails = armorDetails..string.rep(' ', spaceCount)..armorName
                                table.insert(lines, armorDetails)
                                armorDetails = ''
                                row = 0
                            end
                        end
                        if armorDetails ~= '' then
                            table.insert(lines, armorDetails)
                        end
                    end
                end
                table.insert(lines, '')

                if takesAdjustedDamage then
                    headerString = headerString..string.rep(' ', spaceCount)..LOC('<LOC uvd_DamageTaken>')
                end
                table.insert(lines, 1, headerString)

                table.insert(blocks, {color = 'FF7FCFCF', lines = lines})
            end
            --Weapons
            if not table.empty(bp.Weapon) then
                local weapons = {upgrades = {normal = {}, death = {}},
                                    basic = {normal = {}, death = {}}}
                local totalWeaponCount = 0
                for _, weapon in bp.Weapon do
                    if not weapon.WeaponCategory then continue end
                    local dest = weapons.basic
                    if weapon.EnabledByEnhancement then
                        dest = weapons.upgrades
                    end
                    if (weapon.FireOnDeath) or (weapon.WeaponCategory == 'Death') then
                        dest = dest.death
                    else
                        dest = dest.normal
                    end
                    if dest[weapon.DisplayName] then
                        dest[weapon.DisplayName].count = dest[weapon.DisplayName].count + 1
                    else
                        dest[weapon.DisplayName] = {info = weapon, count = 1}
                    end
                    if not dest.death then
                        totalWeaponCount = totalWeaponCount + 1
                    end
                end
                for k, v in weapons do
                    if not table.empty(v.normal) or not table.empty(v.death) then
                        table.insert(blocks, {color = UIUtil.fontColor, lines = {LOC('<LOC uvd_'..k..'>')..':'}})
                    end
                    local totalDirectFireDPS = 0
                    local totalIndirectFireDPS = 0
                    local totalNavalDPS = 0
                    local totalAADPS = 0
                    for name, weapon in v.normal do
                        local info = weapon.info
                        local weaponDetails1 = LOCStr(name)..' ('..LOCStr(info.WeaponCategory)..') '
                        if info.ManualFire then
                            weaponDetails1 = weaponDetails1..LOC('<LOC uvd_ManualFire>')
                        end
                        local weaponDetails2
                        if info.NukeInnerRingDamage then
                            weaponDetails2 = string.format(LOC('<LOC uvd_0014>Damage: %.8g - %.8g, Splash: %.3g - %.3g')..', '..LOC('<LOC uvd_Range>'),
                                info.NukeInnerRingDamage + info.NukeOuterRingDamage, info.NukeOuterRingDamage,
                                info.NukeInnerRingRadius, info.NukeOuterRingRadius, info.MinRadius, info.MaxRadius)
                        else
                            --DPS Calculations
                            local Damage = info.Damage
                            if info.DamageToShields then
                                Damage = Damage + info.DamageToShields
                            end
                            if info.BeamLifetime > 0 then
                                Damage = Damage * (1 + MathFloor(MATH_IRound(info.BeamLifetime*10)/(MATH_IRound(info.BeamCollisionDelay*10)+1)))
                            else
                                Damage = Damage * (info.DoTPulses or 1) + (info.InitialDamage or 0)
                                local ProjectilePhysics = __blueprints[info.ProjectileId].Physics
                                while ProjectilePhysics do
                                    Damage = Damage * (ProjectilePhysics.Fragments or 1)
                                    ProjectilePhysics = __blueprints[string.lower(ProjectilePhysics.FragmentId or '')].Physics
                                end
                            end

                            --Simulate the firing cycle to get the reload time.
                            local CycleProjs = 0 --Projectiles fired per cycle
                            local CycleTime = 0

                            --Various delays need to be adapted to game tick format.
                            local FiringCooldown = math.max(0.1, MATH_IRound(10 / info.RateOfFire) / 10)
                            local ChargeTime = info.RackSalvoChargeTime or 0
                            if ChargeTime > 0 then
                                ChargeTime = math.max(0.1, MATH_IRound(10 * ChargeTime) / 10)
                            end
                            local MuzzleDelays = info.MuzzleSalvoDelay or 0
                            if MuzzleDelays > 0 then
                                MuzzleDelays = math.max(0.1, MATH_IRound(10 * MuzzleDelays) / 10)
                            end
                            local MuzzleChargeDelay = info.MuzzleChargeDelay or 0
                            if MuzzleChargeDelay and MuzzleChargeDelay > 0 then
                                MuzzleDelays = MuzzleDelays + math.max(0.1, MATH_IRound(10 * MuzzleChargeDelay) / 10)
                            end
                            local ReloadTime = info.RackSalvoReloadTime or 0
                            if ReloadTime > 0 then
                                ReloadTime = math.max(0.1, MATH_IRound(10 * ReloadTime) / 10)
                            end

                            -- Keep track that the firing cycle has a constant rate
                            local singleShot = true
                            --OnFire is called from FireReadyState at this point, so we need to track time
                            --to know how much the fire rate cooldown has progressed during our fire cycle.
                            local SubCycleTime = 0
                            local RackBones = info.RackBones
                            if RackBones then --Teleport damage will not have a rack bone
                                --Save the rack count so we can correctly calculate the final rack's fire cooldown
                                local RackCount = table.getsize(RackBones)
                                for index, Rack in RackBones do
                                    local MuzzleCount = info.MuzzleSalvoSize
                                    if info.MuzzleSalvoDelay == 0 then
                                        MuzzleCount = table.getsize(Rack.MuzzleBones)
                                    end
                                    if MuzzleCount > 1 or info.RackFireTogether and RackCount > 1 then singleShot = false end
                                    CycleProjs = CycleProjs + MuzzleCount

                                    SubCycleTime = SubCycleTime + MuzzleCount * MuzzleDelays
                                    if not info.RackFireTogether and index ~= RackCount then
                                        if FiringCooldown <= SubCycleTime + ChargeTime then
                                            CycleTime = CycleTime + SubCycleTime + ChargeTime + math.max(0.1, FiringCooldown - SubCycleTime - ChargeTime)
                                        else
                                            CycleTime = CycleTime + FiringCooldown
                                        end
                                        SubCycleTime = 0
                                    end
                                end
                            end
                            if FiringCooldown <= (SubCycleTime + ChargeTime + ReloadTime) then
                                CycleTime = CycleTime + SubCycleTime + ReloadTime + ChargeTime + math.max(0.1, FiringCooldown - SubCycleTime - ChargeTime - ReloadTime)
                            else
                                CycleTime = CycleTime + FiringCooldown
                            end

                            local DPS = 0
                            if not info.ManualFire and info.WeaponCategory ~= 'Kamikaze' and info.WeaponCategory ~= 'Defense' then
                                --Round DPS, or else it gets floored in string.format.
                                DPS = MATH_IRound(Damage * CycleProjs / CycleTime)
                                weaponDetails1 = weaponDetails1..LOCF('<LOC uvd_DPS>', DPS)
                                -- Do not calulcate the DPS total if the unit only has one valid weapon.
                                if totalWeaponCount > 1 then
                                    if (info.WeaponCategory == 'Direct Fire' or info.WeaponCategory == 'Direct Fire Naval' or info.WeaponCategory == 'Direct Fire Experimental') and not info.IgnoreIfDisabled then
                                        totalDirectFireDPS = totalDirectFireDPS + DPS * weapon.count
                                    elseif info.WeaponCategory == 'Indirect Fire' or info.WeaponCategory == 'Missile' or info.WeaponCategory == 'Artillery' or info.WeaponCategory == 'Bomb' then
                                        totalIndirectFireDPS = totalIndirectFireDPS + DPS * weapon.count
                                    elseif info.WeaponCategory == 'Anti Navy' then
                                        totalNavalDPS = totalNavalDPS + DPS * weapon.count
                                    elseif info.WeaponCategory == 'Anti Air' then
                                        totalAADPS = totalAADPS + DPS * weapon.count
                                    end
                                end
                            end

                            -- Avoid saying a unit fires a salvo when it in fact has a constant rate of fire
                            if singleShot and ReloadTime == 0 and CycleProjs > 1 then
                                CycleTime = CycleTime / CycleProjs
                                CycleProjs = 1
                            end

                            if CycleProjs > 1 then
                                weaponDetails2 = string.format(LOC('<LOC uvd_0015>Damage: %.8g x%d, Splash: %.3g')..', '..LOC('<LOC uvd_Range>')..', '..LOC('<LOC uvd_Reload>'),
                                Damage, CycleProjs, info.DamageRadius, info.MinRadius, info.MaxRadius, CycleTime)
                            -- Do not display Reload stats for Kamikaze weapons
                            elseif info.WeaponCategory == 'Kamikaze' then
                                weaponDetails2 = string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g')..', '..LOC('<LOC uvd_Range>'),
                                Damage, info.DamageRadius, info.MinRadius, info.MaxRadius)
                            -- Do not display 'Range' and Reload stats for 'Teleport in' weapons
                            elseif info.WeaponCategory == 'Teleport' then
                                weaponDetails2 = string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g'),
                                Damage, info.DamageRadius)
                            else
                                weaponDetails2 = string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g')..', '..LOC('<LOC uvd_Range>')..', '..LOC('<LOC uvd_Reload>'),
                                Damage, info.DamageRadius, info.MinRadius, info.MaxRadius, CycleTime)
                            end

                        end
                        if weapon.count > 1 then
                            weaponDetails1 = weaponDetails1..' x'..weapon.count
                        end
                        table.insert(blocks, {color = UIUtil.fontColor, lines = {weaponDetails1}})

                        if info.DamageType == 'Overcharge' then
                            table.insert(blocks, {color = 'FF5AB34B', lines = {weaponDetails2}}) -- Same color as auto-overcharge highlight (autocast_green.dds)
                        elseif info.WeaponCategory == 'Kamikaze' then
                            table.insert(blocks, {color = 'FFFF2C2C', lines = {weaponDetails2}})
                        else
                            table.insert(blocks, {color = 'FFFFB0B0', lines = {weaponDetails2}})
                        end

                        if info.EnergyRequired > 0 and info.EnergyDrainPerSecond > 0 then
                            local weaponDetails3 = string.format('Charge Cost: -%d E (-%d E/s)', info.EnergyRequired, info.EnergyDrainPerSecond)
                            table.insert(blocks, {color = 'FFFF9595', lines = {weaponDetails3}})
                        end

                        local ProjectileEco = __blueprints[info.ProjectileId].Economy
                        if ProjectileEco and (ProjectileEco.BuildCostMass > 0 or ProjectileEco.BuildCostEnergy > 0) and ProjectileEco.BuildTime > 0 then
                            local weaponDetails4 = string.format('Missile Cost: %d M, %d E, %d BT', ProjectileEco.BuildCostMass, ProjectileEco.BuildCostEnergy, ProjectileEco.BuildTime)
                            table.insert(blocks, {color = 'FFFF9595', lines = {weaponDetails4}})
                        end
                    end
                    lines = {}
                    for name, weapon in v.death do
                        local info = weapon.info
                        local weaponDetails = LOCStr(name)..' ('..LOCStr(info.WeaponCategory)..') '
                        if info.NukeInnerRingDamage then
                            weaponDetails = weaponDetails..LOCF('<LOC uvd_0014>Damage: %.8g - %.8g, Splash: %.3g - %.3g',
                                info.NukeInnerRingDamage + info.NukeOuterRingDamage, info.NukeOuterRingDamage,
                                info.NukeInnerRingRadius, info.NukeOuterRingRadius)
                        else
                            weaponDetails = weaponDetails..LOCF('<LOC uvd_0010>Damage: %.7g, Splash: %.3g',
                                info.Damage, info.DamageRadius)
                        end
                        if weapon.count > 1 then
                            weaponDetails = weaponDetails..' x'..weapon.count
                        end
                        table.insert(lines, weaponDetails)
                        table.insert(blocks, {color = 'FFFF0000', lines = lines})
                    end
                    
                    -- Only display the totalDPS stats if they are greater than 0.
                    -- Prevent the totalDPS stats from being displayed under the 'Upgrades' tab and avoid the doubling of empty lines.
                    local upgradesAvailable = not table.empty(weapons.upgrades.normal) or not table.empty(weapons.upgrades.death)
                    if k == 'basic' then
                        if totalDirectFireDPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0018>', totalDirectFireDPS)}})
                        end
                        if totalIndirectFireDPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0019>', totalIndirectFireDPS)}})
                        end
                        if totalNavalDPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0020>', totalNavalDPS)}})
                        end
                        if totalAADPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0021>', totalAADPS)}})
                        end
                        if not upgradesAvailable then
                            table.insert(blocks, {color = UIUtil.fontColor, lines = {''}}) -- Empty line
                        end
                    end
                    -- Avoid the doubling of empty lines when the unit has upgrades.
                    if upgradesAvailable then
                        table.insert(blocks, {color = UIUtil.fontColor, lines = {''}}) -- Empty line
                    end
                end
            end
        end
        --Other parameters
        lines = {}
        table.insert(lines, LOCF("<LOC uvd_0013>Vision: %d, Underwater Vision: %d, Regen: %.3g, Cap Cost: %.3g",
            bp.Intel.VisionRadius, bp.Intel.WaterVisionRadius, bp.Defense.RegenRate, bp.General.CapCost))

        if (bp.Physics.MotionType ~= 'RULEUMT_Air' and bp.Physics.MotionType ~= 'RULEUMT_None')
        or (bp.Physics.AltMotionType ~= 'RULEUMT_Air' and bp.Physics.AltMotionType ~= 'RULEUMT_None') then
            table.insert(lines, LOCF("<LOC uvd_0012>Speed: %.3g, Reverse: %.3g, Acceleration: %.3g, Turning: %d",
                bp.Physics.MaxSpeed, bp.Physics.MaxSpeedReverse, bp.Physics.MaxAcceleration, bp.Physics.TurnRate))
        end
        
        -- Display the TransportSpeedReduction stat in the UI.
        -- Naval units and land experimentals also have this stat, but it since it is not relevant for non-modded games, we do not display it by default.
        -- If a mod wants to display the TransportSpeedReduction stat for naval units or experimentals, this file can be hooked.
        if bp.Physics.TransportSpeedReduction and not (bp.CategoriesHash.NAVAL or bp.CategoriesHash.EXPERIMENTAL) then
            table.insert(lines, LOCF("<LOC uvd_0017>Transport Speed Reduction: %.3g",
            bp.Physics.TransportSpeedReduction))
        end

        table.insert(blocks, {color = 'FFB0FFB0', lines = lines})
    end
    CreateLines(control, blocks)
end
