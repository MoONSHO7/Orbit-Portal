local _, addon = ...
local IconWindow = addon.PortalIconWindow
local math_floor = math.floor
local IsShiftKeyDown = IsShiftKeyDown

local Wheel = {}
addon.PortalWheel = Wheel

function Wheel.Install(ctx, keepSearchAlive)
	local frame, state = ctx.frame, ctx.state
	local Combat = addon.PortalCombat
	local NormalizeMaxVisible = addon.PortalLayout.NormalizeMaxVisible

	local function OnMouseWheel(_, delta)
		if not Combat.CanInteract() then
			return
		end
		local filter = state.searchFilter
		if filter and #filter > 0 then
			keepSearchAlive()
			state.scrollOffset = (state.scrollOffset - delta) % #filter
			IconWindow.Repaint(ctx)
			return
		end
		local portalList = state.portalList
		local totalIcons = #portalList
		if totalIcons == 0 then
			return
		end

		if IsShiftKeyDown() then
			local maxVisible = NormalizeMaxVisible(ctx.plugin:GetSetting(1, "MaxVisible"), totalIcons)
			local centerSlot = math_floor(maxVisible / 2)
			local scrollOffset = state.scrollOffset
			local currentCenterIndex = ((scrollOffset + centerSlot) % totalIcons) + 1
			local currentCategory = portalList[currentCenterIndex] and portalList[currentCenterIndex].displayGroup

			if delta > 0 then
				local firstIndexMap = state.firstIndexOfCategory
				for offset = 1, totalIcons - 1 do
					local checkIndex = ((currentCenterIndex - 1 - offset) % totalIcons) + 1
					local item = portalList[checkIndex]
					if item and item.displayGroup ~= currentCategory then
						local target = firstIndexMap and firstIndexMap[item.displayGroup] or checkIndex
						state.scrollOffset = (target - 1 - centerSlot + totalIcons) % totalIcons
						break
					end
				end
			else
				for offset = 1, totalIcons - 1 do
					local checkIndex = ((currentCenterIndex - 1 + offset) % totalIcons) + 1
					local item = portalList[checkIndex]
					if item and item.displayGroup ~= currentCategory then
						state.scrollOffset = (checkIndex - 1 - centerSlot + totalIcons) % totalIcons
						break
					end
				end
			end
		else
			state.scrollOffset = (state.scrollOffset - delta) % totalIcons
		end

		IconWindow.Repaint(ctx)
	end

	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", OnMouseWheel)
	ctx.HandleWheel = OnMouseWheel
end
