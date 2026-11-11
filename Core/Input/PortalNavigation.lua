local _, addon = ...
local IconWindow = addon.PortalIconWindow
local SearchDisplay = addon.PortalSearchDisplay
local RankMatches = addon.PortalSearchRanking.Match
local Wheel = addon.PortalWheel

local GetTime = GetTime
local GetCursorPosition = GetCursorPosition
local InCombatLockdown = InCombatLockdown

-- [ CONSTANTS ] -------------------------------------------------------------------------------------------------------
local SEARCH_BUFFER_TIMEOUT = 0.8
local HOVER_POLL_INTERVAL = 0.1

-- [ MODULE ] ----------------------------------------------------------------------------------------------------------
local Navigation = {}
addon.PortalNavigation = Navigation

local searchBuffer = ""
local searchBufferExpiry = 0
local preFilterScroll = 0
local installedCtx
local searchFrame = CreateFrame("Frame", nil, UIParent)
searchFrame:Hide()
local searchDisplay = SearchDisplay.Create()
local keyboardSearchEnabled = true

-- [ SEARCH FILTER ] ---------------------------------------------------------------------------------------------------
local function ApplyFilter(items)
	if not installedCtx then
		return
	end
	local state = installedCtx.state
	if items and #items > 0 then
		if not state.searchFilter then
			preFilterScroll = state.scrollOffset
			state.animatePaint = true
		end
		state.searchFilter = items
		state.scrollOffset = 0
	elseif state.searchFilter then
		state.searchFilter = nil
		state.scrollOffset = preFilterScroll
		state.animatePaint = true
	else
		return
	end
	IconWindow.Repaint(installedCtx)
end

-- [ SEARCH DISPLAY ] --------------------------------------------------------------------------------------------------
function Navigation.ClearSearchBuffer()
	searchBuffer = ""
	searchBufferExpiry = 0
	ApplyFilter(nil)
	SearchDisplay.Clear(searchDisplay)
end

local function KeepSearchAlive()
	searchBufferExpiry = GetTime() + SEARCH_BUFFER_TIMEOUT
	SearchDisplay.KeepAlive(searchDisplay)
end

function Navigation.Install(ctx)
	installedCtx = ctx
	keyboardSearchEnabled = ctx.plugin:GetSetting(1, "EnableKeyboardSearch")
	local frame = ctx.frame
	local state = ctx.state
	local Combat = addon.PortalCombat

	local function PageResults()
		KeepSearchAlive()
		local filter = state.searchFilter
		if filter and #filter > 0 then
			state.scrollOffset = (state.scrollOffset + 1) % #filter
			IconWindow.Repaint(ctx)
		end
	end

	local function OnSearchChar(_, text)
		if not text or text == "" then
			return
		end
		if not state.isMouseOver or state.isEditModeActive then
			return
		end
		if GetCurrentKeyBoardFocus() then
			return
		end
		if not Combat.CanInteract() then
			return
		end

		local now = GetTime()
		if now > searchBufferExpiry then
			searchBuffer = ""
		end
		searchBuffer = searchBuffer .. text:lower()
		searchBufferExpiry = now + SEARCH_BUFFER_TIMEOUT

		local matches = RankMatches(state.portalList, searchBuffer)
		local hasMatch = #matches > 0

		ApplyFilter(hasMatch and matches or nil)
		SearchDisplay.Show(searchDisplay, searchBuffer, hasMatch)
	end

	Wheel.Install(ctx, KeepSearchAlive)

	searchFrame:EnableKeyboard(true)
	if not InCombatLockdown() then
		searchFrame:SetPropagateKeyboardInput(true)
	end
	searchFrame:Hide()

	local function ApplyPropagation(self, key)
		if InCombatLockdown() then
			return
		end
		if GetCurrentKeyBoardFocus() or not (key and #key == 1) then
			self:SetPropagateKeyboardInput(true)
		else
			self:SetPropagateKeyboardInput(false)
		end
	end

	local function OnKeyDown(self, key)
		if InCombatLockdown() then
			return
		end
		if
			key == "TAB"
			and searchBuffer ~= ""
			and state.isMouseOver
			and not state.isEditModeActive
			and not GetCurrentKeyBoardFocus()
			and Combat.CanInteract()
		then
			self:SetPropagateKeyboardInput(false)
			PageResults()
			return
		end
		ApplyPropagation(self, key)
	end

	searchFrame:SetScript("OnKeyDown", OnKeyDown)
	searchFrame:SetScript("OnKeyUp", ApplyPropagation)
	searchFrame:SetScript("OnChar", OnSearchChar)

	-- An icon Hidden mid-hover never fires OnLeave, stranding this keyboard-capturing frame and eating every key.
	searchFrame:SetScript("OnUpdate", function(self, elapsed)
		self.pollElapsed = (self.pollElapsed or 0) + elapsed
		if self.pollElapsed < HOVER_POLL_INTERVAL then
			return
		end
		self.pollElapsed = 0
		if not (ctx.IsCursorOverFrame and ctx.IsCursorOverFrame()) then
			if ctx.HoverExit then
				ctx.HoverExit()
			end
			return
		end
		if searchBuffer ~= "" then
			local x, y = GetCursorPosition()
			if x ~= self.lastCursorX or y ~= self.lastCursorY then
				self.lastCursorX, self.lastCursorY = x, y
				KeepSearchAlive()
			end
		end
	end)

	SearchDisplay.Install(searchDisplay, frame, Navigation.ClearSearchBuffer)
end

function Navigation.ShowSearch()
	if
		installedCtx
		and keyboardSearchEnabled
		and installedCtx.plugin._portalActive
		and not installedCtx.state.isEditModeActive
		and addon.PortalCombat.CanInteract()
	then
		searchFrame:Show()
	end
end

function Navigation.HideSearch()
	if not searchFrame then
		return
	end
	-- Release the key capture before hiding so a lingering frame (or the next show) never eats keyboard input.
	if not InCombatLockdown() then
		searchFrame:SetPropagateKeyboardInput(true)
	end
	searchFrame:Hide()
end

function Navigation.RestorePropagationDefault()
	if searchFrame and not InCombatLockdown() then
		searchFrame:SetPropagateKeyboardInput(true)
	end
end

function Navigation.ApplySettings()
	if not installedCtx then
		return
	end
	keyboardSearchEnabled = installedCtx.plugin:GetSetting(1, "EnableKeyboardSearch")
	if not keyboardSearchEnabled then
		Navigation.HideSearch()
		Navigation.ClearSearchBuffer()
	elseif installedCtx.state.isMouseOver and not installedCtx.state.isEditModeActive then
		Navigation.ShowSearch()
	end
end
