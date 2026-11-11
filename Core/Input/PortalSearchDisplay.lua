local _, addon = ...
local Services = addon.PortalServices
local InCombatLockdown = InCombatLockdown

local DISPLAY_HOLD = 0.8
local DISPLAY_FADE = 0.35
local DISPLAY_FONT_SIZE = 20
local DISPLAY_GAP = 6
local DISPLAY_LEVEL_OFFSET = 10
local DISPLAY_MATCH_COLOR = { 1, 1, 1 }
local DISPLAY_NOMATCH_COLOR = { 1, 0.25, 0.25 }

local SearchDisplay = {}
addon.PortalSearchDisplay = SearchDisplay

function SearchDisplay.Create()
	local display = CreateFrame("Frame", nil, UIParent)
	display:Hide()
	return display
end

function SearchDisplay.Install(display, frame, onFinished)
	local fontPath = Services.GetSearchFontPath()
	display:SetParent(frame)
	display:SetFrameLevel(frame:GetFrameLevel() + DISPLAY_LEVEL_OFFSET)
	display:SetSize(1, 1)
	display:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", DISPLAY_GAP, 0)
	display:Hide()

	display.bufferText = display:CreateFontString(nil, "OVERLAY")
	display.bufferText:SetPoint("BOTTOMLEFT")
	Services.SetFont(display.bufferText, fontPath, DISPLAY_FONT_SIZE, "OUTLINE")
	display.bufferText:SetTextColor(1, 1, 1)

	display.fade = display:CreateAnimationGroup()
	display.fade:SetToFinalAlpha(true)
	local fade = display.fade:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetStartDelay(DISPLAY_HOLD)
	fade:SetDuration(DISPLAY_FADE)
	display.fade:SetScript("OnFinished", onFinished)
end

function SearchDisplay.Clear(display)
	local fade = display.fade
	if fade and fade:IsPlaying() then
		fade:Stop()
	end
	display:SetAlpha(InCombatLockdown() and 0 or 1)
	if not InCombatLockdown() then
		display:Hide()
	end
end

function SearchDisplay.Show(display, buffer, hasMatch)
	display.bufferText:SetText(buffer:upper())
	local color = hasMatch and DISPLAY_MATCH_COLOR or DISPLAY_NOMATCH_COLOR
	display.bufferText:SetTextColor(color[1], color[2], color[3])
	local fade = display.fade
	if fade then
		fade:Stop()
	end
	display:SetAlpha(1)
	display:Show()
	if fade then
		fade:Play()
	end
end

function SearchDisplay.KeepAlive(display)
	local fade = display.fade
	if display:IsShown() and fade then
		fade:Stop()
		display:SetAlpha(1)
		fade:Play()
	end
end
