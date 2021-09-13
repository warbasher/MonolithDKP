local _, core = ...
local _G = _G
local MonDKP = core.MonDKP
local L = core.L

MonDKP.util = {}

local util = MonDKP.util

function util.AddPreviewSupport(frame, item)
	frame:SetScript("OnClick", function(self)
		local itemName, itemLink = GetItemInfo(item)
		if IsControlKeyDown() then
			DressUpItemLink(itemName)
		elseif IsShiftKeyDown() then
			--DEFAULT_CHAT_FRAME:AddMessage(itemLink)
			ChatFrame1EditBox:Show()
			ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..itemLink)
			ChatFrame1EditBox:SetFocus()
		end
	end)
end