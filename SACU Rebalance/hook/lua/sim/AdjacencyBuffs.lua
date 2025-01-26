---@diagnostic disable: undefined-global
do
    local sizeCatToSizeStr = {
        ["SIZE20"] = "Size20",
        ["SIZE16"] = "Size16",
        ["SIZE12"] = "Size12",
        ["SIZE8"]  = "Size8",
        ["SIZE4"]  = "Size4",
    }

    local hookAdj = {
    }

    -- annoying file to hook that needs custom code to replace the global buff definitions

    for providerCategory, buff in pairs(hookAdj) do
        local adjacencyBpName = providerCategory .. "AdjacencyBuffs"
        local oldBuff = _G[adjacencyBpName]
        for buffType, buffSizes in pairs(buff) do
            for sizeCat, amount in pairs(buffSizes) do
                local displayName = providerCategory .. buffType

                local category = "STRUCTURE " .. sizeCat
                if buffType == "RateOfFire" and sizeCat == "SIZE4" then
                    category = category .. " ARTILLERY"
                end

                BuffBlueprint {
                    Name = displayName .. sizeCatToSizeStr[sizeCat],
                    DisplayName = displayName,
                    BuffType = string.upper(buffType) .. "BONUS",
                    Stacks = "ALWAYS",
                    Duration = -1,
                    EntityCategory = category,
                    BuffCheckFunction = AdjBuffFuncs[buffType .. "BuffCheck"],
                    OnBuffAffect = AdjBuffFuncs.DefaultBuffAffect,
                    OnBuffRemove = AdjBuffFuncs.DefaultBuffRemove,
                    Affects = { [buffType] = { Add = amount } },
                }
                --[[Example result:
                {
                    Name = "T1PowerGeneratorEnergyActiveSize20",
                    DisplayName = "T1PowerGeneratorEnergyActive",
                    BuffType = "ENERGYACTIVEBONUS",
                    Stacks = "ALWAYS",
                    Duration = 1,
                    EntityCategory = "STRUCTURE SIZE20",
                    BuffCheckFunction = <function>,
                    OnBuffAffect = <function>,
                    OnBuffRemove = <function>,
                    Affects = { EnergyActive = { Add = -0.01563 } }
                }
                ]]
            end
        end
    end
end
