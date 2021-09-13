local _, core = ...
local _G = _G
local MonDKP = core.MonDKP
local L = core.L

local moveTimerToggle = 0
local validating = false

-- To fix taint issues
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local Options = {}
local function DrawPercFrame(box)
	--Draw % signs if set to percent
	MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetFontObject("MonDKPNormalLeft")
	MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box], "RIGHT", -15, 0)
	MonDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetText("%")
end

local itemList = {
	"Head", "Neck", "Shoulders", "Cloak", "Chest", "Bracers", "Hands",
	"Belt", "Legs", "Boots", "Ring", "Trinket", "OneHanded", "TwoHanded",
	"OffHand", "Range", "Other"
}

--[[
local curInstance = "Molten Core"
-- The stupid API returns a different name for certain raids than expected..
local nameToRealInstance = {
	["Molten Core"] = "Molten Core",
	["Blackwing Lair"] = "Blackwing Lair",
	["Ahn'Qiraj Temple"] = "Temple of Ahn'Qiraj",
	["Naxxramas"] = "Naxxramas"
}
local indexedTab = {
	-- Order they appear in the drop down
	"Molten Core", "Blackwing Lair", "Temple of Ahn'Qiraj", "Naxxramas"
}
-- Made this global so we can access it via AdjustDKP.lua
presetOptions = {
	["Molten Core"] = {
		BossKillBonus = 0,
		MinimumBid = 10,
		MinimumOSBid = 5
	},
	["Blackwing Lair"] = {
		BossKillBonus = 3,
		MinimumBid = 30,
		MinimumOSBid = 15
	},
	["Temple of Ahn'Qiraj"] = {
		BossKillBonus = 5,
		MinimumBid = 40,
		MinimumOSBid = 20
	},
	["Naxxramas"] = {
		BossKillBonus = 5,
		MinimumBid = 40,
		MinimumOSBid = 20
	}
}
]]

-- The stupid API returns a different name for certain raids than expected..
local curInstance = "Karazhan"
local nameToRealInstance = {
	["Karazhan"] = "Karazhan",
	["Gruul's Lair"] = "Gruul's Lair",
	["Magtheridon's Lair"] = "Magtheridon's Lair",
	["Serpentshrine Cavern"] = "Serpentshrine Cavern",
	["Tempest Keep"] = "Tempest Keep"
}
local indexedTab = {
	-- Order they appear in the drop down
	"Karazhan",
	"Gruul's Lair",
	"Magtheridon's Lair",
	"Serpentshrine Cavern",
	"Tempest Keep"
}
-- Made this global so we can access it via AdjustDKP.lua
presetOptions = {
	["Karazhan"] = {
		BossKillBonus = 3,
		MinimumBid = 40,
		MinimumOSBid = 20
	},
	["Gruul's Lair"] = {
		BossKillBonus = 3,
		MinimumBid = 40,
		MinimumOSBid = 20
	},
	["Magtheridon's Lair"] = {
		BossKillBonus = 3,
		MinimumBid = 40,
		MinimumOSBid = 20
	},
	["Serpentshrine Cavern"] = {
		BossKillBonus = 10,
		MinimumBid = 40,
		MinimumOSBid = 20
	},
	["Tempest Keep"] = {
		BossKillBonus = 10,
		MinimumBid = 40,
		MinimumOSBid = 20
	}
}

-- Copy our original table
local function copy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
	return res
end

originalPresetOptions = copy(presetOptions)

local function SaveSettings(settingUp)
	if MonDKP.ConfigTab4.default[1] then
		local bossKillBonus = MonDKP.ConfigTab4.default[2]:GetNumber()
		MonDKP_DB.DKPBonus.OnTimeBonus = MonDKP.ConfigTab4.default[1]:GetNumber()
		MonDKP_DB.DKPBonus.BossKillBonus = bossKillBonus
		MonDKP_DB.DKPBonus.CompletionBonus = MonDKP.ConfigTab4.default[3]:GetNumber()
		MonDKP_DB.DKPBonus.NewBossKillBonus = MonDKP.ConfigTab4.default[4]:GetNumber()
		MonDKP_DB.DKPBonus.UnexcusedAbsence = MonDKP.ConfigTab4.default[5]:GetNumber()
		if MonDKP.ConfigTab4.default[6]:GetNumber() < 0 then
			MonDKP_DB.DKPBonus.DecayPercentage = 0 - MonDKP.ConfigTab4.default[6]:GetNumber()
		else
			MonDKP_DB.DKPBonus.DecayPercentage = MonDKP.ConfigTab4.default[6]:GetNumber()
		end
		MonDKP.ConfigTab2.decayDKP:SetNumber(MonDKP_DB.DKPBonus.DecayPercentage)
		MonDKP.ConfigTab4.default[6]:SetNumber(MonDKP_DB.DKPBonus.DecayPercentage)
		MonDKP_DB.DKPBonus.BidTimer = MonDKP.ConfigTab4.bidTimer:GetNumber()


		local minBid = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:GetNumber()
		local minOSBid = MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:GetNumber()

		-- Old system of saving all 17 variables
		for _, name in pairs(itemList) do
			MonDKP_DB.MinBidBySlot[name] = minBid
		end
		MonDKP_DB.MinOSBid = minOSBid

		-- Override the table so we can save this table later
		if (not setingUp) then
			presetOptions[curInstance].MinimumBid = minBid
			presetOptions[curInstance].MinimumOSBid = minOSBid
			presetOptions[curInstance].BossKillBonus = bossKillBonus
		end

		-- Force the button to update if we have it up
		if (MonDKP.ConfigTab2.reasonDropDown.lastReason and MonDKP.ConfigTab2.reasonDropDown.lastReason == L["BOSSKILLBONUS"]) then
			if MonDKP.ConfigTab2.addDKP then
				local currentRaid = MonDKP.ConfigTab2.addDKP.CurrentRaid
				if (currentRaid == instance) then
					MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.BossKillBonus)
				end
			end
		end

		MonDKP_DB.BidInstances = {
			LastInstance = curInstance,
			InstanceValues = presetOptions -- Copy the table directly since we've been modifying it
		}
	end

	core.MonDKPUI:SetScale(MonDKP_DB.defaults.MonDKPScaleSize)
	MonDKP_DB.defaults.HistoryLimit = MonDKP.ConfigTab4.history:GetNumber()
	MonDKP_DB.defaults.DKPHistoryLimit = MonDKP.ConfigTab4.DKPHistory:GetNumber()
	MonDKP_DB.defaults.TooltipHistoryCount = MonDKP.ConfigTab4.TooltipHistory:GetNumber()
	DKPTable_Update()
end

local searchDropdown
local function SelectedInstance(instance)
	curInstance = instance

	-- I changed this to force load the instance variable, so we can select it when we haven't been in the raid
	local instanceTab = presetOptions[curInstance]
	-- Failsafe if this tries to load when the officer doesn't have the table set in their DKP table yet
	if (not instanceTab) then
		Options.LoadInstanceVariables(instance)
		return
	end

	local minBid = instanceTab.MinimumBid
	if minBid then
		for _, name in pairs(itemList) do
			MonDKP_DB.MinBidBySlot[name] = minBid
		end

		if MonDKP.ConfigTab4 and MonDKP.ConfigTab4.DefaultMinBids and MonDKP.ConfigTab4.DefaultMinBids.SlotBox then
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetNumber(minBid)
		end
	end

	local minOSBid = instanceTab.MinimumOSBid
	if minOSBid then
		MonDKP_DB.MinOSBid = minOSBid

		if MonDKP.ConfigTab4 and MonDKP.ConfigTab4.DefaultMinBids and MonDKP.ConfigTab4.DefaultMinBids.SlotBox then
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetNumber(minOSBid)
		end
	end

	local bossKillVal = instanceTab.BossKillBonus
	if bossKillVal then
		if MonDKP.ConfigTab4 and MonDKP.ConfigTab4.default and MonDKP.ConfigTab4.default[2] then
			MonDKP.ConfigTab4.default[2]:SetNumber(bossKillVal)
			-- Force this to update whenever we pick a dropdown, makes it work on AdjustDKP tab
			MonDKP_DB.DKPBonus.BossKillBonus = bossKillVal
		end

		if MonDKP.ConfigTab2 and MonDKP.ConfigTab2.reasonDropDown and MonDKP.ConfigTab2.reasonDropDown.lastReason and (MonDKP.ConfigTab2.reasonDropDown.lastReason == L["BOSSKILLBONUS"]) then
			if MonDKP.ConfigTab2.addDKP then
				local currentRaid = MonDKP.ConfigTab2.addDKP.CurrentRaid
				if (currentRaid == instance) then
					MonDKP.ConfigTab2.addDKP:SetNumber(MonDKP_DB.DKPBonus.BossKillBonus)
				end
			end
		end
	end

	LibDD:UIDropDownMenu_SetText(searchDropdown, instance)
end

function Options.LoadInstanceVariables(overrideZone)
	curInstance = overrideZone or (MonDKP_DB.BidInstances and MonDKP_DB.BidInstances.LastInstance) or curInstance

	-- Should make the 'reset instances' button obsolete
	if MonDKP_DB.BidInstances then
		if MonDKP_DB.BidInstances.InstanceValues then
			if (not MonDKP_DB.BidInstances.InstanceValues[curInstance]) then
				MonDKP:Print("Adding "..curInstance.." to the auto-detection table.")
				MonDKP_DB.BidInstances.InstanceValues[curInstance] = originalPresetOptions[curInstance]
				SaveSettings(true)
			else
				local added
				local instanceTab = MonDKP_DB.BidInstances.InstanceValues[curInstance]

				-- Safety check in case we remove old raids (like molten core)
				if presetOptions[curInstance] then
					for key, val in pairs(presetOptions[curInstance]) do
						if (not instanceTab[key]) then
							print("Missing : "..key)
							instanceTab[key] = val
							added = true
						end
					end
				end

				if added then
					MonDKP:Print("Adding a missing variable to your auto-detection table for "..curInstance..".")
					SaveSettings()
				end
			end
		else
			MonDKP:Print("Auto-detection table was blank - setting it up.")
			SaveSettings(true)
		end
	else
		MonDKP:Print("Setting up your auto-detection tables.")
		SaveSettings(true)
	end

	-- Set this afterwards
	presetOptions = (MonDKP_DB.BidInstances and MonDKP_DB.BidInstances.InstanceValues) or presetOptions

	-- Backup code to select the proper values
	SelectedInstance(curInstance)
end

-- Auto-detect the current zone every time the menu opens
function MonDKP:DetectCurrentInstance()
	local overrideZone
	local name, type, difficultyIndex, difficultyName, maxPlayers,
	dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()

	for nameToCheck, instanceName in pairs(nameToRealInstance) do
		if (string.lower(nameToCheck) == string.lower(name)) then
			if (core.LastInstance ~= instanceName) then
				core.LastInstance = instanceName
				MonDKP:Print("Zone Detected: "..instanceName)
			end
			overrideZone = instanceName

			break
		end
	end

	if overrideZone then
		Options.LoadInstanceVariables(overrideZone)
	end
end

function MonDKP:Options()
	local default = {}
	MonDKP.ConfigTab4.default = default

	MonDKP.ConfigTab4.header = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.header:SetFontObject("MonDKPLargeCenter")
	MonDKP.ConfigTab4.header:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 15, -10)
	MonDKP.ConfigTab4.header:SetText(L["DEFAULTSETTINGS"])
	MonDKP.ConfigTab4.header:SetScale(1.2)

	-- Add the dropdown for the search button
	if core.IsOfficer == true then
		searchDropdown = LibDD:Create_UIDropDownMenu("MonDKPInstanceDropDown", MonDKP.ConfigTab4)

		LibDD:UIDropDownMenu_Initialize(searchDropdown, function(self, level, menuList)
			for i=1, #indexedTab do
				local instance = indexedTab[i]
				local tab = presetOptions[instance]
				local filterName = LibDD:UIDropDownMenu_CreateInfo()
				filterName.func = self.FilterSetValue
				filterName.text = instance
				filterName.arg1 = instance
				filterName.checked = (instance == curInstance)
				filterName.isNotRadio = true
				LibDD:UIDropDownMenu_AddButton(filterName)
			end
		end)

		searchDropdown:SetPoint("TOPRIGHT", MonDKP.ConfigTab4, "TOPRIGHT", -24, -45)
		LibDD:UIDropDownMenu_SetWidth(searchDropdown, 120)
		LibDD:UIDropDownMenu_SetText(searchDropdown, curInstance or "Karazhan")

		-- Dropdown Menu Function
		function searchDropdown:FilterSetValue(newValue)
			SelectedInstance(newValue)
			LibDD:CloseDropDownMenus()
		end
	end



	if core.IsOfficer == true then
		MonDKP.ConfigTab4.description = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.description:SetFontObject("MonDKPNormalLeft")
		MonDKP.ConfigTab4.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -15)
		MonDKP.ConfigTab4.description:SetText("|CFFcca600"..L["DEFAULTDKPAWARDVALUES"].."|r")
	
		for i=1, 6 do
			MonDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
			MonDKP.ConfigTab4.default[i]:SetAutoFocus(false)
			MonDKP.ConfigTab4.default[i]:SetMultiLine(false)
			MonDKP.ConfigTab4.default[i]:SetSize(80, 24)
			MonDKP.ConfigTab4.default[i]:SetBackdrop({
				bgFile   = "Textures\\white.blp", tile = true,
				edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
			})
			MonDKP.ConfigTab4.default[i]:SetBackdropColor(0,0,0,0.9)
			MonDKP.ConfigTab4.default[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
			MonDKP.ConfigTab4.default[i]:SetMaxLetters(6)
			MonDKP.ConfigTab4.default[i]:SetTextColor(1, 1, 1, 1)
			MonDKP.ConfigTab4.default[i]:SetFontObject("MonDKPSmallRight")
			MonDKP.ConfigTab4.default[i]:SetTextInsets(10, 10, 5, 5)
			MonDKP.ConfigTab4.default[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
				self:HighlightText(0,0)
				SaveSettings()
				self:ClearFocus()
			end)
			MonDKP.ConfigTab4.default[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
				self:HighlightText(0,0)
				SaveSettings()
				self:ClearFocus()
			end)
			MonDKP.ConfigTab4.default[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
				SaveSettings()
				if i == 6 then
					self:HighlightText(0,0)
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetFocus()
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:HighlightText()
				else
					self:HighlightText(0,0)
					MonDKP.ConfigTab4.default[i+1]:SetFocus()
					MonDKP.ConfigTab4.default[i+1]:HighlightText()
				end
			end)
			MonDKP.ConfigTab4.default[i]:SetScript("OnEnter", function(self)
				if (self.tooltipText) then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true)
				end
				if (self.tooltipDescription) then
					GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true)
					GameTooltip:Show()
				end
				if (self.tooltipWarning) then
					GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true)
					GameTooltip:Show()
				end
			end)
			MonDKP.ConfigTab4.default[i]:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			if i==1 then
				MonDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4, "TOPLEFT", 144, -84)
			elseif i==4 then
				MonDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.default[1], "TOPLEFT", 212, 0)
			else
				MonDKP.ConfigTab4.default[i]:SetPoint("TOP", MonDKP.ConfigTab4.default[i-1], "BOTTOM", 0, -22)
			end
		end

		-- Modes Button
		MonDKP.ConfigTab4.ModesButton = self:CreateButton("TOPRIGHT", MonDKP.ConfigTab4, "TOPRIGHT", -40, -20, L["DKPMODES"])
		MonDKP.ConfigTab4.ModesButton:SetSize(110,25)
		MonDKP.ConfigTab4.ModesButton:SetScript("OnClick", function()
			MonDKP:ToggleDKPModesWindow()
		end)
		MonDKP.ConfigTab4.ModesButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true)
			GameTooltip:AddLine(L["DKPMODESTTDESC2"], 1.0, 1.0, 1.0, true)
			GameTooltip:AddLine(L["DKPMODESTTWARN"], 1.0, 0, 0, true)
			GameTooltip:Show()
		end)
		MonDKP.ConfigTab4.ModesButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
		end)
		if not core.IsOfficer then
			MonDKP.ConfigTab4.ModesButton:Hide()
		end

		MonDKP.ConfigTab4.default[1]:SetText(MonDKP_DB.DKPBonus.OnTimeBonus)
		MonDKP.ConfigTab4.default[1].tooltipText = L["ONTIMEBONUS"]
		MonDKP.ConfigTab4.default[1].tooltipDescription = L["ONTIMEBONUSTTDESC"]
			
		MonDKP.ConfigTab4.default[2]:SetText(MonDKP_DB.DKPBonus.BossKillBonus)
		MonDKP.ConfigTab4.default[2].tooltipText = L["BOSSKILLBONUS"]
		MonDKP.ConfigTab4.default[2].tooltipDescription = L["BOSSKILLBONUSTTDESC"]
			 
		MonDKP.ConfigTab4.default[3]:SetText(MonDKP_DB.DKPBonus.CompletionBonus)
		MonDKP.ConfigTab4.default[3].tooltipText = L["RAIDCOMPLETIONBONUS"]
		MonDKP.ConfigTab4.default[3].tooltipDescription = L["RAIDCOMPLETEBONUSTT"]
			
		MonDKP.ConfigTab4.default[4]:SetText(MonDKP_DB.DKPBonus.NewBossKillBonus)
		MonDKP.ConfigTab4.default[4].tooltipText = L["NEWBOSSKILLBONUS"]
		MonDKP.ConfigTab4.default[4].tooltipDescription = L["NEWBOSSKILLTTDESC"]

		MonDKP.ConfigTab4.default[5]:SetText(MonDKP_DB.DKPBonus.UnexcusedAbsence)
		MonDKP.ConfigTab4.default[5]:SetNumeric(false)
		MonDKP.ConfigTab4.default[5].tooltipText = L["UNEXCUSEDABSENCE"]
		MonDKP.ConfigTab4.default[5].tooltipDescription = L["UNEXCUSEDTTDESC"]
		MonDKP.ConfigTab4.default[5].tooltipWarning = L["UNEXCUSEDTTWARN"]

		MonDKP.ConfigTab4.default[6]:SetText(MonDKP_DB.DKPBonus.DecayPercentage)
		MonDKP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
		MonDKP.ConfigTab4.default[6].tooltipText = L["DECAYPERCENTAGE"]
		MonDKP.ConfigTab4.default[6].tooltipDescription = L["DECAYPERCENTAGETTDESC"]
		MonDKP.ConfigTab4.default[6].tooltipWarning = L["DECAYPERCENTAGETTWARN"]

		--OnTimeBonus Header
		MonDKP.ConfigTab4.OnTimeHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.OnTimeHeader:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[1], "LEFT", 0, 0)
		MonDKP.ConfigTab4.OnTimeHeader:SetText(L["ONTIMEBONUS"]..": ")

		--BossKillBonus Header
		MonDKP.ConfigTab4.BossKillHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.BossKillHeader:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[2], "LEFT", 0, 0)
		MonDKP.ConfigTab4.BossKillHeader:SetText(L["BOSSKILLBONUS"]..": ")

		--CompletionBonus Header
		MonDKP.ConfigTab4.CompleteHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.CompleteHeader:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[3], "LEFT", 0, 0)
		MonDKP.ConfigTab4.CompleteHeader:SetText(L["RAIDCOMPLETIONBONUS"]..": ")

		--NewBossKillBonus Header
		MonDKP.ConfigTab4.NewBossHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.NewBossHeader:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[4], "LEFT", 0, 0)
		MonDKP.ConfigTab4.NewBossHeader:SetText(L["NEWBOSSKILLBONUS"]..": ")

		--UnexcusedAbsence Header
		MonDKP.ConfigTab4.UnexcusedHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.UnexcusedHeader:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[5], "LEFT", 0, 0)
		MonDKP.ConfigTab4.UnexcusedHeader:SetText(L["UNEXCUSEDABSENCE"]..": ")

		--DKP Decay Header
		MonDKP.ConfigTab4.DecayHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.DecayHeader:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.DecayHeader:SetPoint("RIGHT", MonDKP.ConfigTab4.default[6], "LEFT", 0, 0)
		MonDKP.ConfigTab4.DecayHeader:SetText(L["DECAYAMOUNT"]..": ")

		MonDKP.ConfigTab4.DecayFooter = MonDKP.ConfigTab4.default[6]:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.DecayFooter:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.DecayFooter:SetPoint("LEFT", MonDKP.ConfigTab4.default[6], "RIGHT", -15, -1)
		MonDKP.ConfigTab4.DecayFooter:SetText("%")

		-- Default Minimum Bids Container Frame
		MonDKP.ConfigTab4.DefaultMinBids = CreateFrame("Frame", nil, MonDKP.ConfigTab4)
		MonDKP.ConfigTab4.DefaultMinBids:SetPoint("TOPLEFT", MonDKP.ConfigTab4.default[3], "BOTTOMLEFT", -130, -52)
		--MonDKP.ConfigTab4.DefaultMinBids:SetSize(420, 410)
		MonDKP.ConfigTab4.DefaultMinBids:SetSize(420, 80)

		MonDKP.ConfigTab4.DefaultMinBids.description = MonDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.DefaultMinBids.description:SetFontObject("MonDKPSmallRight")
		MonDKP.ConfigTab4.DefaultMinBids.description:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 15, 15)

			-- DEFAULT min bids Create EditBoxes
			local SlotBox = {}
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox = SlotBox

			for i=1, 2 do
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i] = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetAutoFocus(false)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMultiLine(false)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetSize(60, 24)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdrop({
					bgFile   = "Textures\\white.blp", tile = true,
					edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
				})
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMaxLetters(6)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetFontObject("MonDKPSmallRight")
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					SaveSettings()
					self:ClearFocus()
				end)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					SaveSettings()
					self:ClearFocus()
				end)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
					SaveSettings()
				end)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnter", function(self)
					if (self.tooltipText) then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true)
					end
					if (self.tooltipDescription) then
						GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true)
						GameTooltip:Show()
					end
					if (self.tooltipWarning) then
						GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true)
						GameTooltip:Show()
					end
				end)
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)

				-- Slot Headers
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header = MonDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
				MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetFontObject("MonDKPNormalLeft")
				if i == 1 then
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetPoint("RIGHT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i], "LEFT", 0, 0)
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 100, -10)
				elseif i == 2 then
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetPoint("RIGHT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i], "LEFT", 0, 0)
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i-1], "BOTTOM", 0, -22)
				end
			end

			local prefix

			if MonDKP_DB.modes.mode == "Minimum Bid Values" then
				prefix = L["MINIMUMBID"]
				MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTMINBIDVALUES"].."|r")
			elseif MonDKP_DB.modes.mode == "Static Item Values" then
				MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r")
				if MonDKP_DB.modes.costvalue == "Integer" then
					prefix = L["DKPPRICE"]
				elseif MonDKP_DB.modes.costvalue == "Percent" then
					prefix = L["PERCENTCOST"]
				end
			elseif MonDKP_DB.modes.mode == "Roll Based Bidding" then
				MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r")
				if MonDKP_DB.modes.costvalue == "Integer" then
					prefix = L["DKPPRICE"]
				elseif MonDKP_DB.modes.costvalue == "Percent" then
					prefix = L["PERCENTCOST"]
				end
			elseif MonDKP_DB.modes.mode == "Zero Sum" then
				MonDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r")
				if MonDKP_DB.modes.costvalue == "Integer" then
					prefix = L["DKPPRICE"]
				elseif MonDKP_DB.modes.costvalue == "Percent" then
					prefix = L["PERCENTCOST"]
				end
			end

			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].Header:SetText("Items: ")
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetText(MonDKP_DB.MinBidBySlot.Head)
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipText = "Minimum Bid"
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipDescription = "Minimum bid for items in the instance"

			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].Header:SetText("Off spec items: ")
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetText(MonDKP_DB.MinOSBid)
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipText = "Minimum OS Bid"
			MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipDescription = "Minimum bid for off spec items in the instance"


			if MonDKP_DB.modes.costvalue == "Percent" then
				for i=1, #MonDKP.ConfigTab4.DefaultMinBids.SlotBox do
					DrawPercFrame(i)
					MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
				end
			end

			-- Broadcast Minimum Bids Button
			MonDKP.ConfigTab4.BroadcastMinBids = self:CreateButton("TOP", MonDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"])
			MonDKP.ConfigTab4.BroadcastMinBids:ClearAllPoints()
			MonDKP.ConfigTab4.BroadcastMinBids:SetPoint("LEFT", MonDKP.ConfigTab4.DefaultMinBids.SlotBox[2], "RIGHT", 41, 0)
			MonDKP.ConfigTab4.BroadcastMinBids:SetSize(110,25)
			MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnClick", function()
				StaticPopupDialogs["SEND_MINBIDS"] = {
					text = L["BCASTMINBIDCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						local temptable = {}
						table.insert(temptable, MonDKP_DB.MinBidBySlot)
						table.insert(temptable, MonDKP_MinBids)
						table.insert(temptable, MonDKP_DB.BidInstances)
						MonDKP.Sync:SendData("MonDKPMinBid", temptable)
						MonDKP:Print(L["MINBIDVALUESSENT"])
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("SEND_MINBIDS")
			end)
			MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
				GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true)
				GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true)
				GameTooltip:Show()
			end)
			MonDKP.ConfigTab4.BroadcastMinBids:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			-- To reset your instance values
			MonDKP.ConfigTab4.ResetInstances = self:CreateButton("TOP", MonDKP.ConfigTab4, "BOTTOM", 30, 30, "Reset Instances")
			MonDKP.ConfigTab4.ResetInstances:ClearAllPoints()
			MonDKP.ConfigTab4.ResetInstances:SetPoint("LEFT", MonDKP.ConfigTab4.BroadcastMinBids, "RIGHT", 5, 0)
			MonDKP.ConfigTab4.ResetInstances:SetSize(110,25)
			MonDKP.ConfigTab4.ResetInstances:SetScript("OnClick", function()
				StaticPopupDialogs["RESET_INSTANCES"] = {
					text = "Are you sure you want to reset your instance values?",
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						presetOptions = copy(originalPresetOptions)
						SelectedInstance(curInstance)
						SaveSettings()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show("RESET_INSTANCES")
			end)
			MonDKP.ConfigTab4.ResetInstances:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText("Reset Instance Values", 0.25, 0.75, 0.90, 1, true)
				GameTooltip:AddLine("Resets your current instance values. Only do this if your instance values aren't saving or auto-detection isn't working properly.", 1.0, 1.0, 1.0, true)
				GameTooltip:Show()
			end)
			MonDKP.ConfigTab4.ResetInstances:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)


		-- Bid Timer Slider
		MonDKP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate")
		MonDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 54, -40)
		MonDKP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 90)
		MonDKP.ConfigTab4.bidTimerSlider:SetValue(MonDKP_DB.DKPBonus.BidTimer)
		MonDKP.ConfigTab4.bidTimerSlider:SetValueStep(1)
		MonDKP.ConfigTab4.bidTimerSlider.tooltipText = L["BIDTIMER"]
		MonDKP.ConfigTab4.bidTimerSlider.tooltipRequirement = L["BIDTIMERDEFAULTTTDESC"]
		MonDKP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true)
		getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
		getglobal(MonDKP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("90")
		MonDKP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
			MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())
		end)

		MonDKP.ConfigTab4.bidTimerHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		MonDKP.ConfigTab4.bidTimerHeader:SetFontObject("MonDKPTinyCenter")
		MonDKP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.bidTimerSlider, "TOP", 0, 3)
		MonDKP.ConfigTab4.bidTimerHeader:SetText(L["BIDTIMER"])

		MonDKP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
		MonDKP.ConfigTab4.bidTimer:SetAutoFocus(false)
		MonDKP.ConfigTab4.bidTimer:SetMultiLine(false)
		MonDKP.ConfigTab4.bidTimer:SetSize(50, 18)
		MonDKP.ConfigTab4.bidTimer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		})
		MonDKP.ConfigTab4.bidTimer:SetBackdropColor(0,0,0,0.9)
		MonDKP.ConfigTab4.bidTimer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
		MonDKP.ConfigTab4.bidTimer:SetMaxLetters(4)
		MonDKP.ConfigTab4.bidTimer:SetTextColor(1, 1, 1, 1)
		MonDKP.ConfigTab4.bidTimer:SetFontObject("MonDKPTinyCenter")
		MonDKP.ConfigTab4.bidTimer:SetTextInsets(10, 10, 5, 5)
		MonDKP.ConfigTab4.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:ClearFocus()
		end)
		MonDKP.ConfigTab4.bidTimer:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:ClearFocus()
		end)
		MonDKP.ConfigTab4.bidTimer:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
			MonDKP.ConfigTab4.bidTimerSlider:SetValue(MonDKP.ConfigTab4.bidTimer:GetNumber())
		end)
		MonDKP.ConfigTab4.bidTimer:SetPoint("TOP", MonDKP.ConfigTab4.bidTimerSlider, "BOTTOM", 0, -3)     
		MonDKP.ConfigTab4.bidTimer:SetText(MonDKP.ConfigTab4.bidTimerSlider:GetValue())
	end

	-- Tooltip History Slider
	MonDKP.ConfigTab4.TooltipHistorySlider = CreateFrame("SLIDER", "$parentTooltipHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate")
	if MonDKP.ConfigTab4.bidTimer then
		MonDKP.ConfigTab4.TooltipHistorySlider:SetPoint("LEFT", MonDKP.ConfigTab4.bidTimerSlider, "RIGHT", 30, 0)
	else
		MonDKP.ConfigTab4.TooltipHistorySlider:SetPoint("TOP", MonDKP.ConfigTab4, "TOP", 1, -107)
	end
	MonDKP.ConfigTab4.TooltipHistorySlider:SetMinMaxValues(5, 35)
	MonDKP.ConfigTab4.TooltipHistorySlider:SetValue(MonDKP_DB.defaults.TooltipHistoryCount)
	MonDKP.ConfigTab4.TooltipHistorySlider:SetValueStep(1)
	MonDKP.ConfigTab4.TooltipHistorySlider.tooltipText = L["TTHISTORYCOUNT"]
	MonDKP.ConfigTab4.TooltipHistorySlider.tooltipRequirement = L["TTHISTORYCOUNTTTDESC"]
	MonDKP.ConfigTab4.TooltipHistorySlider:SetObeyStepOnDrag(true)
	getglobal(MonDKP.ConfigTab4.TooltipHistorySlider:GetName().."Low"):SetText("5")
	getglobal(MonDKP.ConfigTab4.TooltipHistorySlider:GetName().."High"):SetText("35")
	MonDKP.ConfigTab4.TooltipHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.TooltipHistory:SetText(MonDKP.ConfigTab4.TooltipHistorySlider:GetValue())
	end)

	MonDKP.ConfigTab4.TooltipHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.TooltipHistoryHeader:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.TooltipHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.TooltipHistorySlider, "TOP", 0, 3)
	MonDKP.ConfigTab4.TooltipHistoryHeader:SetText(L["TTHISTORYCOUNT"])

	MonDKP.ConfigTab4.TooltipHistory = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
	MonDKP.ConfigTab4.TooltipHistory:SetAutoFocus(false)
	MonDKP.ConfigTab4.TooltipHistory:SetMultiLine(false)
	MonDKP.ConfigTab4.TooltipHistory:SetSize(50, 18)
	MonDKP.ConfigTab4.TooltipHistory:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	})
	MonDKP.ConfigTab4.TooltipHistory:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab4.TooltipHistory:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
	MonDKP.ConfigTab4.TooltipHistory:SetMaxLetters(4)
	MonDKP.ConfigTab4.TooltipHistory:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab4.TooltipHistory:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.TooltipHistory:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab4.TooltipHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.TooltipHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.TooltipHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.TooltipHistorySlider:SetValue(MonDKP.ConfigTab4.TooltipHistory:GetNumber())
	end)
	MonDKP.ConfigTab4.TooltipHistory:SetPoint("TOP", MonDKP.ConfigTab4.TooltipHistorySlider, "BOTTOM", 0, -3)     
	MonDKP.ConfigTab4.TooltipHistory:SetText(MonDKP.ConfigTab4.TooltipHistorySlider:GetValue())


	-- Loot History Limit Slider
	MonDKP.ConfigTab4.historySlider = CreateFrame("SLIDER", "$parentHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate")
	if MonDKP.ConfigTab4.bidTimer then
		MonDKP.ConfigTab4.historySlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.bidTimerSlider, "BOTTOMLEFT", 0, -50)
	else
		MonDKP.ConfigTab4.historySlider:SetPoint("TOPRIGHT", MonDKP.ConfigTab4.TooltipHistorySlider, "BOTTOMLEFT", 56, -49)
	end
	MonDKP.ConfigTab4.historySlider:SetMinMaxValues(500, 2500)
	MonDKP.ConfigTab4.historySlider:SetValue(MonDKP_DB.defaults.HistoryLimit)
	MonDKP.ConfigTab4.historySlider:SetValueStep(25)
	MonDKP.ConfigTab4.historySlider.tooltipText = L["LOOTHISTORYLIMIT"]
	MonDKP.ConfigTab4.historySlider.tooltipRequirement = L["LOOTHISTLIMITTTDESC"]
	MonDKP.ConfigTab4.historySlider.tooltipWarning = L["LOOTHISTLIMITTTWARN"]
	MonDKP.ConfigTab4.historySlider:SetObeyStepOnDrag(true)
	getglobal(MonDKP.ConfigTab4.historySlider:GetName().."Low"):SetText("500")
	getglobal(MonDKP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
	MonDKP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())
	end)

	MonDKP.ConfigTab4.HistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.HistoryHeader:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.historySlider, "TOP", 0, 3)
	MonDKP.ConfigTab4.HistoryHeader:SetText(L["LOOTHISTORYLIMIT"])

	MonDKP.ConfigTab4.history = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
	MonDKP.ConfigTab4.history:SetAutoFocus(false)
	MonDKP.ConfigTab4.history:SetMultiLine(false)
	MonDKP.ConfigTab4.history:SetSize(50, 18)
	MonDKP.ConfigTab4.history:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	})
	MonDKP.ConfigTab4.history:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab4.history:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
	MonDKP.ConfigTab4.history:SetMaxLetters(4)
	MonDKP.ConfigTab4.history:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab4.history:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.history:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab4.history:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.history:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.history:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.historySlider:SetValue(MonDKP.ConfigTab4.history:GetNumber())
	end)
	MonDKP.ConfigTab4.history:SetPoint("TOP", MonDKP.ConfigTab4.historySlider, "BOTTOM", 0, -3)     
	MonDKP.ConfigTab4.history:SetText(MonDKP.ConfigTab4.historySlider:GetValue())

	-- DKP History Limit Slider
	MonDKP.ConfigTab4.DKPHistorySlider = CreateFrame("SLIDER", "$parentDKPHistorySlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate")
	MonDKP.ConfigTab4.DKPHistorySlider:SetPoint("LEFT", MonDKP.ConfigTab4.historySlider, "RIGHT", 30, 0)
	MonDKP.ConfigTab4.DKPHistorySlider:SetMinMaxValues(500, 2500)
	MonDKP.ConfigTab4.DKPHistorySlider:SetValue(MonDKP_DB.defaults.DKPHistoryLimit)
	MonDKP.ConfigTab4.DKPHistorySlider:SetValueStep(25)
	MonDKP.ConfigTab4.DKPHistorySlider.tooltipText = L["DKPHISTORYLIMIT"]
	MonDKP.ConfigTab4.DKPHistorySlider.tooltipRequirement = L["DKPHISTLIMITTTDESC"]
	MonDKP.ConfigTab4.DKPHistorySlider.tooltipWarning = L["DKPHISTLIMITTTWARN"]
	MonDKP.ConfigTab4.DKPHistorySlider:SetObeyStepOnDrag(true)
	getglobal(MonDKP.ConfigTab4.DKPHistorySlider:GetName().."Low"):SetText("500")
	getglobal(MonDKP.ConfigTab4.DKPHistorySlider:GetName().."High"):SetText("2500")
	MonDKP.ConfigTab4.DKPHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.DKPHistory:SetText(MonDKP.ConfigTab4.DKPHistorySlider:GetValue())
	end)

	MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.DKPHistorySlider, "TOP", 0, 3)
	MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["DKPHISTORYLIMIT"])

	MonDKP.ConfigTab4.DKPHistory = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
	MonDKP.ConfigTab4.DKPHistory:SetAutoFocus(false)
	MonDKP.ConfigTab4.DKPHistory:SetMultiLine(false)
	MonDKP.ConfigTab4.DKPHistory:SetSize(50, 18)
	MonDKP.ConfigTab4.DKPHistory:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	})
	MonDKP.ConfigTab4.DKPHistory:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab4.DKPHistory:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	MonDKP.ConfigTab4.DKPHistory:SetMaxLetters(4)
	MonDKP.ConfigTab4.DKPHistory:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab4.DKPHistory:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.DKPHistory:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab4.DKPHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.DKPHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.DKPHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.DKPHistorySlider:SetValue(MonDKP.ConfigTab4.history:GetNumber())
	end)
	MonDKP.ConfigTab4.DKPHistory:SetPoint("TOP", MonDKP.ConfigTab4.DKPHistorySlider, "BOTTOM", 0, -3)     
	MonDKP.ConfigTab4.DKPHistory:SetText(MonDKP.ConfigTab4.DKPHistorySlider:GetValue())

	-- Bid Timer Size Slider
	MonDKP.ConfigTab4.TimerSizeSlider = CreateFrame("SLIDER", "$parentBidTimerSizeSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate")
	MonDKP.ConfigTab4.TimerSizeSlider:SetPoint("TOPLEFT", MonDKP.ConfigTab4.historySlider, "BOTTOMLEFT", 0, -50)
	MonDKP.ConfigTab4.TimerSizeSlider:SetMinMaxValues(0.5, 2.0)
	MonDKP.ConfigTab4.TimerSizeSlider:SetValue(MonDKP_DB.defaults.BidTimerSize)
	MonDKP.ConfigTab4.TimerSizeSlider:SetValueStep(0.05)
	MonDKP.ConfigTab4.TimerSizeSlider.tooltipText = L["TIMERSIZE"]
	MonDKP.ConfigTab4.TimerSizeSlider.tooltipRequirement = L["TIMERSIZETTDESC"]
	MonDKP.ConfigTab4.TimerSizeSlider.tooltipWarning = L["TIMERSIZETTWARN"]
	MonDKP.ConfigTab4.TimerSizeSlider:SetObeyStepOnDrag(true)
	getglobal(MonDKP.ConfigTab4.TimerSizeSlider:GetName().."Low"):SetText("50%")
	getglobal(MonDKP.ConfigTab4.TimerSizeSlider:GetName().."High"):SetText("200%")
	MonDKP.ConfigTab4.TimerSizeSlider:SetScript("OnValueChanged", function(self)   
		MonDKP.ConfigTab4.TimerSize:SetText(MonDKP.ConfigTab4.TimerSizeSlider:GetValue())
		MonDKP_DB.defaults.BidTimerSize = MonDKP.ConfigTab4.TimerSizeSlider:GetValue()
		MonDKP.BidTimer:SetScale(MonDKP_DB.defaults.BidTimerSize)
	end)

	MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.TimerSizeSlider, "TOP", 0, 3)
	MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["TIMERSIZE"])

	MonDKP.ConfigTab4.TimerSize = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
	MonDKP.ConfigTab4.TimerSize:SetAutoFocus(false)
	MonDKP.ConfigTab4.TimerSize:SetMultiLine(false)
	MonDKP.ConfigTab4.TimerSize:SetSize(50, 18)
	MonDKP.ConfigTab4.TimerSize:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	})
	MonDKP.ConfigTab4.TimerSize:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab4.TimerSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	MonDKP.ConfigTab4.TimerSize:SetMaxLetters(4)
	MonDKP.ConfigTab4.TimerSize:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab4.TimerSize:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.TimerSize:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab4.TimerSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.TimerSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.TimerSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.TimerSizeSlider:SetValue(MonDKP.ConfigTab4.TimerSize:GetNumber())
	end)
	MonDKP.ConfigTab4.TimerSize:SetPoint("TOP", MonDKP.ConfigTab4.TimerSizeSlider, "BOTTOM", 0, -3)     
	MonDKP.ConfigTab4.TimerSize:SetText(MonDKP.ConfigTab4.TimerSizeSlider:GetValue())

	-- UI Scale Size Slider
	MonDKP.ConfigTab4.MonDKPScaleSize = CreateFrame("SLIDER", "$parentMonDKPScaleSizeSlider", MonDKP.ConfigTab4, "MonDKPOptionsSliderTemplate")
	MonDKP.ConfigTab4.MonDKPScaleSize:SetPoint("TOPLEFT", MonDKP.ConfigTab4.DKPHistorySlider, "BOTTOMLEFT", 0, -50)
	MonDKP.ConfigTab4.MonDKPScaleSize:SetMinMaxValues(0.5, 2.0)
	MonDKP.ConfigTab4.MonDKPScaleSize:SetValue(MonDKP_DB.defaults.MonDKPScaleSize)
	MonDKP.ConfigTab4.MonDKPScaleSize:SetValueStep(0.05)
	MonDKP.ConfigTab4.MonDKPScaleSize.tooltipText = L["MONDKPSCALESIZE"]
	MonDKP.ConfigTab4.MonDKPScaleSize.tooltipRequirement = L["MONDKPSCALESIZETTDESC"]
	MonDKP.ConfigTab4.MonDKPScaleSize.tooltipWarning = L["MONDKPSCALESIZETTWARN"]
	MonDKP.ConfigTab4.MonDKPScaleSize:SetObeyStepOnDrag(true)
	getglobal(MonDKP.ConfigTab4.MonDKPScaleSize:GetName().."Low"):SetText("50%")
	getglobal(MonDKP.ConfigTab4.MonDKPScaleSize:GetName().."High"):SetText("200%")
	MonDKP.ConfigTab4.MonDKPScaleSize:SetScript("OnValueChanged", function(self)   
		MonDKP.ConfigTab4.UIScaleSize:SetText(MonDKP.ConfigTab4.MonDKPScaleSize:GetValue())
		MonDKP_DB.defaults.MonDKPScaleSize = MonDKP.ConfigTab4.MonDKPScaleSize:GetValue()
	end)

	MonDKP.ConfigTab4.DKPHistoryHeader = MonDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", MonDKP.ConfigTab4.MonDKPScaleSize, "TOP", 0, 3)
	MonDKP.ConfigTab4.DKPHistoryHeader:SetText(L["MAINGUISIZE"])

	MonDKP.ConfigTab4.UIScaleSize = CreateFrame("EditBox", nil, MonDKP.ConfigTab4, "BackdropTemplate")
	MonDKP.ConfigTab4.UIScaleSize:SetAutoFocus(false)
	MonDKP.ConfigTab4.UIScaleSize:SetMultiLine(false)
	MonDKP.ConfigTab4.UIScaleSize:SetSize(50, 18)
	MonDKP.ConfigTab4.UIScaleSize:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	})
	MonDKP.ConfigTab4.UIScaleSize:SetBackdropColor(0,0,0,0.9)
	MonDKP.ConfigTab4.UIScaleSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	MonDKP.ConfigTab4.UIScaleSize:SetMaxLetters(4)
	MonDKP.ConfigTab4.UIScaleSize:SetTextColor(1, 1, 1, 1)
	MonDKP.ConfigTab4.UIScaleSize:SetFontObject("MonDKPTinyCenter")
	MonDKP.ConfigTab4.UIScaleSize:SetTextInsets(10, 10, 5, 5)
	MonDKP.ConfigTab4.UIScaleSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.UIScaleSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	MonDKP.ConfigTab4.UIScaleSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		MonDKP.ConfigTab4.MonDKPScaleSize:SetValue(MonDKP.ConfigTab4.UIScaleSize:GetNumber())
	end)
	MonDKP.ConfigTab4.UIScaleSize:SetPoint("TOP", MonDKP.ConfigTab4.MonDKPScaleSize, "BOTTOM", 0, -3)     
	MonDKP.ConfigTab4.UIScaleSize:SetText(MonDKP.ConfigTab4.MonDKPScaleSize:GetValue())

	-- Supress Broadcast Notifications checkbox
	MonDKP.ConfigTab4.supressNotifications = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate")
	MonDKP.ConfigTab4.supressNotifications:SetPoint("TOP", MonDKP.ConfigTab4.TimerSizeSlider, "BOTTOMLEFT", 0, -35)
	MonDKP.ConfigTab4.supressNotifications:SetChecked(MonDKP_DB.defaults.supressNotifications)
	MonDKP.ConfigTab4.supressNotifications:SetScale(0.8)
	MonDKP.ConfigTab4.supressNotifications.text:SetText("|cff5151de"..L["SUPPRESSNOTIFICATIONS"].."|r")
	MonDKP.ConfigTab4.supressNotifications.text:SetFontObject("MonDKPSmall")
	MonDKP.ConfigTab4.supressNotifications:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SUPPRESSNOTIFICATIONS"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["SUPPRESSNOTIFYTTDESC"], 1.0, 1.0, 1.0, true)
		GameTooltip:AddLine(L["SUPPRESSNOTIFYTTWARN"], 1.0, 0, 0, true)
		GameTooltip:Show()
	end)
	MonDKP.ConfigTab4.supressNotifications:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab4.supressNotifications:SetScript("OnClick", function()
		if MonDKP.ConfigTab4.supressNotifications:GetChecked() then
			MonDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cffff0000"..L["HIDDEN"].."|r.")
			MonDKP_DB["defaults"]["supressNotifications"] = true
		else
			MonDKP_DB["defaults"]["supressNotifications"] = false
			MonDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cff00ff00"..L["VISIBLE"].."|r.")
		end
		PlaySound(808)
	end)

	-- Combat Logging checkbox
	MonDKP.ConfigTab4.CombatLogging = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate")
	MonDKP.ConfigTab4.CombatLogging:SetPoint("TOP", MonDKP.ConfigTab4.supressNotifications, "BOTTOM", 0, 0)
	MonDKP.ConfigTab4.CombatLogging:SetChecked(MonDKP_DB.defaults.AutoLog)
	MonDKP.ConfigTab4.CombatLogging:SetScale(0.8)
	MonDKP.ConfigTab4.CombatLogging.text:SetText("|cff5151de"..L["AUTOCOMBATLOG"].."|r")
	MonDKP.ConfigTab4.CombatLogging.text:SetFontObject("MonDKPSmall")
	MonDKP.ConfigTab4.CombatLogging:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["AUTOCOMBATLOG"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["AUTOCOMBATLOGTTDESC"], 1.0, 1.0, 1.0, true)
		GameTooltip:AddLine(L["AUTOCOMBATLOGTTWARN"], 1.0, 0, 0, true)
		GameTooltip:Show()
	end)
	MonDKP.ConfigTab4.CombatLogging:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab4.CombatLogging:SetScript("OnClick", function(self)
		MonDKP_DB.defaults.AutoLog = self:GetChecked()
		PlaySound(808)
	end)

	if MonDKP_DB.defaults.AutoOpenBid == nil then
		MonDKP_DB.defaults.AutoOpenBid = true
	end

	MonDKP.ConfigTab4.AutoOpenCheckbox = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate")
	MonDKP.ConfigTab4.AutoOpenCheckbox:SetChecked(MonDKP_DB.defaults.AutoOpenBid)
	MonDKP.ConfigTab4.AutoOpenCheckbox:SetScale(0.8)
	MonDKP.ConfigTab4.AutoOpenCheckbox.text:SetText("|cff5151de"..L["AUTOOPEN"].."|r")
	MonDKP.ConfigTab4.AutoOpenCheckbox.text:SetScale(1)
	MonDKP.ConfigTab4.AutoOpenCheckbox.text:SetFontObject("MonDKPSmallLeft")
	MonDKP.ConfigTab4.AutoOpenCheckbox:SetPoint("TOP", MonDKP.ConfigTab4.CombatLogging, "BOTTOM", 0, 0)
	MonDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnClick", function(self)
		MonDKP_DB.defaults.AutoOpenBid = self:GetChecked()
	end)
	MonDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true)
		GameTooltip:Show()
	end)
	MonDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	if core.IsOfficer == true then
		-- Supress Broadcast Notifications checkbox
		MonDKP.ConfigTab4.supressTells = CreateFrame("CheckButton", nil, MonDKP.ConfigTab4, "UICheckButtonTemplate")
		MonDKP.ConfigTab4.supressTells:SetPoint("LEFT", MonDKP.ConfigTab4.supressNotifications, "RIGHT", 200, 0)
		MonDKP.ConfigTab4.supressTells:SetChecked(MonDKP_DB.defaults.SupressTells)
		MonDKP.ConfigTab4.supressTells:SetScale(0.8)
		MonDKP.ConfigTab4.supressTells.text:SetText("|cff5151de"..L["SUPPRESSBIDWHISP"].."|r")
		MonDKP.ConfigTab4.supressTells.text:SetFontObject("MonDKPSmall")
		MonDKP.ConfigTab4.supressTells:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["SUPPRESSBIDWHISP"], 0.25, 0.75, 0.90, 1, true)
			GameTooltip:AddLine(L["SUPRESSBIDWHISPTTDESC"], 1.0, 1.0, 1.0, true)
			GameTooltip:AddLine(L["SUPRESSBIDWHISPTTWARN"], 1.0, 0, 0, true)
			GameTooltip:Show()
		end)
		MonDKP.ConfigTab4.supressTells:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		MonDKP.ConfigTab4.supressTells:SetScript("OnClick", function()
			if MonDKP.ConfigTab4.supressTells:GetChecked() then
				MonDKP:Print(L["BIDWHISPARENOW"].." |cffff0000"..L["HIDDEN"].."|r.")
				MonDKP_DB["defaults"]["SupressTells"] = true
			else
				MonDKP_DB["defaults"]["SupressTells"] = false
				MonDKP:Print(L["BIDWHISPARENOW"].." |cff00ff00"..L["VISIBLE"].."|r.")
			end
			PlaySound(808)
		end)
	end

	-- Save Settings Button
	MonDKP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", MonDKP.ConfigTab4, "BOTTOMLEFT", 30, 30, L["SAVESETTINGS"])
	MonDKP.ConfigTab4.submitSettings:ClearAllPoints()
	MonDKP.ConfigTab4.submitSettings:SetPoint("TOP", MonDKP.ConfigTab4.AutoOpenCheckbox, "BOTTOMLEFT", 20, -40)
	MonDKP.ConfigTab4.submitSettings:SetSize(90,25)
	MonDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
		if core.IsOfficer == true then
			for i=1, 6 do
				if not tonumber(MonDKP.ConfigTab4.default[i]:GetText()) then
					StaticPopupDialogs["OPTIONS_VALIDATION"] = {
						text = L["INVALIDOPTIONENTRY"].." "..MonDKP.ConfigTab4.default[i].tooltipText..". "..L["PLEASEUSENUMS"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("OPTIONS_VALIDATION")

				return
				end
			end

			for i=1, 1 do
				if not tonumber(MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:GetText()) then
					StaticPopupDialogs["OPTIONS_VALIDATION"] = {
						text = L["INVALIDMINBIDENTRY"].." "..MonDKP.ConfigTab4.DefaultMinBids.SlotBox[i].tooltipText..". "..L["PLEASEUSENUMS"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("OPTIONS_VALIDATION")

				return
				end
			end
		end
		
		SaveSettings()
		MonDKP:Print(L["DEFAULTSETSAVED"])
	end)

	-- Chatframe Selection 
	MonDKP.ConfigTab4.ChatFrame = LibDD:Create_UIDropDownMenu("MonDKPChatFrameSelectDropDown", MonDKP.ConfigTab4)

	if not MonDKP_DB.defaults.ChatFrames then MonDKP_DB.defaults.ChatFrames = {} end

	LibDD:UIDropDownMenu_Initialize(MonDKP.ConfigTab4.ChatFrame, function(self, level, menuList)
	local SelectedFrame = LibDD:UIDropDownMenu_CreateInfo()
		SelectedFrame.func = self.SetValue
		SelectedFrame.fontObject = "MonDKPSmallCenter"
		SelectedFrame.keepShownOnClick = true
		SelectedFrame.isNotRadio = true

		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i)
			if name ~= "" then
				SelectedFrame.text, SelectedFrame.arg1, SelectedFrame.checked = name, name, MonDKP_DB.defaults.ChatFrames[name]
				LibDD:UIDropDownMenu_AddButton(SelectedFrame)
			end
		end
	end)

	MonDKP.ConfigTab4.ChatFrame:SetPoint("LEFT", MonDKP.ConfigTab4.CombatLogging, "RIGHT", 130, 0)
	LibDD:UIDropDownMenu_SetWidth(MonDKP.ConfigTab4.ChatFrame, 150)
	LibDD:UIDropDownMenu_SetText(MonDKP.ConfigTab4.ChatFrame, "Addon Notifications")

	function MonDKP.ConfigTab4.ChatFrame:SetValue(arg1)
		MonDKP_DB.defaults.ChatFrames[arg1] = not MonDKP_DB.defaults.ChatFrames[arg1]
		LibDD:CloseDropDownMenus()
	end



	-- Position Bid Timer Button
	MonDKP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["MOVEBIDTIMER"])
	MonDKP.ConfigTab4.moveTimer:ClearAllPoints()
	MonDKP.ConfigTab4.moveTimer:SetPoint("LEFT", MonDKP.ConfigTab4.submitSettings, "RIGHT", 200, 0)
	MonDKP.ConfigTab4.moveTimer:SetSize(110,25)
	MonDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
		if moveTimerToggle == 0 then
			MonDKP:StartTimer(120, L["MOVEME"])
			MonDKP.ConfigTab4.moveTimer:SetText(L["HIDEBIDTIMER"])
			moveTimerToggle = 1
		else
			MonDKP.BidTimer:SetScript("OnUpdate", nil)
			MonDKP.BidTimer:Hide()
			MonDKP.ConfigTab4.moveTimer:SetText(L["MOVEBIDTIMER"])
			moveTimerToggle = 0
		end
	end)

	-- wipe tables button
	MonDKP.ConfigTab4.WipeTables = self:CreateButton("BOTTOMRIGHT", MonDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["WIPETABLES"])
	MonDKP.ConfigTab4.WipeTables:ClearAllPoints()
	MonDKP.ConfigTab4.WipeTables:SetPoint("RIGHT", MonDKP.ConfigTab4.moveTimer, "LEFT", -40, 0)
	MonDKP.ConfigTab4.WipeTables:SetSize(110,25)
	MonDKP.ConfigTab4.WipeTables:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["WIPETABLES"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["WIPETABLESTTDESC"], 1.0, 1.0, 1.0, true)
		GameTooltip:Show()
	end)
	MonDKP.ConfigTab4.WipeTables:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	MonDKP.ConfigTab4.WipeTables:SetScript("OnClick", function()

		StaticPopupDialogs["WIPE_TABLES"] = {
			text = L["WIPETABLESCONF"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				MonDKP_Whitelist = nil
				MonDKP_DKPTable = nil
				MonDKP_Loot = nil
				MonDKP_DKPHistory = nil
				MonDKP_Archive = nil
				MonDKP_Standby = nil
				MonDKP_MinBids = nil

				MonDKP_DKPTable = {}
				MonDKP_Loot = {}
				MonDKP_DKPHistory = {}
				MonDKP_Archive = {}
				MonDKP_Whitelist = {}
				MonDKP_Standby = {}
				MonDKP_MinBids = {}
				MonDKP:LootHistory_Reset()
				MonDKP:FilterDKPTable(core.currentSort, "reset")
				MonDKP:StatusVerify_Update()
			end,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("WIPE_TABLES")
	end)

	-- Options Footer (empty frame to push bottom of scrollframe down)
	MonDKP.ConfigTab4.OptionsFooterFrame = CreateFrame("Frame", nil, MonDKP.ConfigTab4)
	MonDKP.ConfigTab4.OptionsFooterFrame:SetPoint("TOPLEFT", MonDKP.ConfigTab4.moveTimer, "BOTTOMLEFT")
	MonDKP.ConfigTab4.OptionsFooterFrame:SetSize(420, 50)



	-- Load the custom instance variables - make sure this gets called last
	if core.IsOfficer == true then
		Options.LoadInstanceVariables()
	end
end