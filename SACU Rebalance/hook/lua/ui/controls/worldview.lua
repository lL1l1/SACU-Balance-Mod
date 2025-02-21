--- Change it to use the OverChargeWeapon flag instead of checking the damagetype
--- because we no longer always use overcharge damage type for overcharge weapons
--- A decal texture / size computation function for `RULEUCC_Overcharge`
---@return WorldViewDecalData[]
local function OverchargeDecalFunc()
    return RadiusDecalFunction(
        function(w)
            return w.OverChargeWeapon
        end
    )
end

-- override the class's function to reference the new function...
-- thinking about it, it should originally be done in a library file outside of the class's file
-- so that this trick isn't needed

WorldView.OnCursorOvercharge =
--- Called when the order `RULEUCC_Overcharge` is being applied
---@param self WorldView
---@param identifier 'RULEUCC_Overcharge'
---@param enabled boolean
---@param changed boolean
function(self, identifier, enabled, changed, commandData)
    if enabled then
        local canKill = OverchargeCanKill()
        if canKill == true then
            local cursor = self.Cursor
            cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
        elseif canKill == false then
            local cursor = self.Cursor
            cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor("OVERCHARGE_ORANGE")
        else
            local cursor = self.Cursor
            cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor("OVERCHARGE_GREY")
        end

        self:ApplyCursor()
    end

    self:OnCursorDecals(identifier, enabled, changed, OverchargeDecalFunc)
end
