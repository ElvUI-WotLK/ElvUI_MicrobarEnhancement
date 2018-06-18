local E, L, V, P, G =  unpack(ElvUI)
local AB = E:GetModule("ActionBars")
local EP = LibStub("LibElvUIPlugin-1.0")
local S = E:GetModule("Skins")
local addon = ...

local _G = _G
local tinsert = tinsert

local HideUIPanel, ShowUIPanel = HideUIPanel, ShowUIPanel
local GameTooltip = GameTooltip
local UnitLevel = UnitLevel
local LoadAddOn = LoadAddOn
local MainMenuBarPerformanceBarFrame_OnEnter = MainMenuBarPerformanceBarFrame_OnEnter
local MicroButtonTooltipText = MicroButtonTooltipText
local ToggleFrame = ToggleFrame
local ToggleAchievementFrame = ToggleAchievementFrame
local TogglePVPFrame = TogglePVPFrame
local ToggleLFDParentFrame = ToggleLFDParentFrame
local ToggleHelpFrame = ToggleHelpFrame
local CHARACTER_INFO, SPELLBOOK_ABILITIES_BUTTON, TALENTS_BUTTON, ACHIEVEMENT_BUTTON, QUESTLOG_BUTTON = CHARACTER_INFO, SPELLBOOK_ABILITIES_BUTTON, TALENTS_BUTTON, ACHIEVEMENT_BUTTON, QUESTLOG_BUTTON
local SOCIAL_BUTTON, PLAYER_V_PLAYER, DUNGEONS_BUTTON, MAINMENU_BUTTON, HELP_BUTTON = SOCIAL_BUTTON, PLAYER_V_PLAYER, DUNGEONS_BUTTON, MAINMENU_BUTTON, HELP_BUTTON
local PERFORMANCEBAR_UPDATE_INTERVAL = PERFORMANCEBAR_UPDATE_INTERVAL
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local COLOR = COLOR

P.actionbar.microbar.symbolic = false
P.actionbar.microbar.backdrop = false
P.actionbar.microbar.transparentBackdrop = false
P.actionbar.microbar.classColor = false
P.actionbar.microbar.xOffset = 0
P.actionbar.microbar.yOffset = 0
P.actionbar.microbar.colorS = {r = 1, g = 1, b = 1}

function AB:GetOptions()
	E.Options.args.actionbar.args.microbar.args.microbarEnhanced = {
		order = 10,
		type = "group",
		name = "Microbar Enhancement",
		guiInline = true,
		args = {
			backdrop = {
				order = 1,
				type = "toggle",
				name = L["Backdrop"],
				disabled = function() return not AB.db.microbar.enabled end,
				get = function(info) return AB.db.microbar.backdrop end,
				set = function(info, value) AB.db.microbar.backdrop = value AB:UpdateMicroPositionDimensions() end
			},
			transparentBackdrop = {
				order = 2,
				type = "toggle",
				name = L["Transparent Backdrop"],
				disabled = function() return not AB.db.microbar.enabled or not AB.db.microbar.backdrop end,
				get = function(info) return AB.db.microbar.transparentBackdrop end,
				set = function(info, value) AB.db.microbar.transparentBackdrop = value AB:UpdateMicroPositionDimensions() end
			},
			spacer1 = {
				order = 3,
				type = "description",
				name = " "
			},
			symbolic = {
				order = 4,
				type = "toggle",
				name = L["As Letters"],
				desc = L["Replace icons with letters"],
				disabled = function() return not AB.db.microbar.enabled end,
				get = function(info) return AB.db.microbar.symbolic end,
				set = function(info, value) AB.db.microbar.symbolic = value AB:MenuShow() end
			},
			classColor = {
				order = 5,
				type = "toggle",
				name = L["Use Class Color"],
				disabled = function() return not AB.db.microbar.enabled or not AB.db.microbar.symbolic end,
				get = function(info) return AB.db.microbar.classColor end,
				set = function(info, value) AB.db.microbar.classColor = value AB:SetSymbloColor() end
			},
			color = {
				order = 6,
				type = "color",
				name = COLOR,
				get = function(info)
					local t = AB.db.microbar.colorS
					local d = P.actionbar.microbar.colorS
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					local t = AB.db.microbar.colorS
					t.r, t.g, t.b = r, g, b
					AB:SetSymbloColor()
				end,
				disabled = function() return not AB.db.microbar.enabled or AB.db.microbar.classColor or not AB.db.microbar.symbolic end
			},
			spacer2 = {
				order = 7,
				type = "description",
				name = " "
			},
			xOffset = {
				order = 8,
				type = "range",
				name = L["X-Offset"],
				min = 0, max = 20, step = 1,
				disabled = function() return not AB.db.microbar.enabled end,
				get = function(info) return AB.db.microbar.xOffset end,
				set = function(info, value) AB.db.microbar.xOffset = value AB:UpdateMicroPositionDimensions() end
			},
			yOffset = {
				order = 9,
				type = "range",
				name = L["Y-Offset"],
				min = 0, max = 20, step = 1,
				disabled = function() return not AB.db.microbar.enabled end,
				get = function(info) return AB.db.microbar.yOffset end,
				set = function(info, value) AB.db.microbar.yOffset = value AB:UpdateMicroPositionDimensions() end
			}
		}
	}
end

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"PVPMicroButton",
	"LFDMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton"
}

local Sbuttons = {}

E.UpdateAllMB = E.UpdateAll
function E:UpdateAll()
    E.UpdateAllMB(self)
	AB:MenuShow()
end

local function onEnter()
	if AB.db.microbar.mouseover then
		E:UIFrameFadeIn(ElvUI_MicroBarS, 0.2, ElvUI_MicroBarS:GetAlpha(), AB.db.microbar.alpha)
	end
end

local function onLeave()
	if AB.db.microbar.mouseover then
		E:UIFrameFadeOut(ElvUI_MicroBarS, 0.2, ElvUI_MicroBarS:GetAlpha(), 0)
	end
end

function AB:CreateSymbolButton(name, text, tooltip, click)
	local button = CreateFrame("Button", name, ElvUI_MicroBarS)
	if click then button:SetScript("OnClick", click) end

	button.tooltip = tooltip
	button.updateInterval = 0

	if tooltip then
		button:SetScript("OnEnter", function(self)
			onEnter()
			button.hover = 1
			button.updateInterval = 0
			GameTooltip:SetOwner(self)
			GameTooltip:AddLine(button.tooltip, 1, 1, 1, 1, 1, 1)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function(self)
			onLeave()
			button.hover = nil
			GameTooltip:Hide()
		end)
	else
		button:HookScript("OnEnter", onEnter)
		button:HookScript("OnEnter", onLeave)
	end

	S:HandleButton(button)

	if text then
		button.text = button:CreateFontString(nil, "OVERLAY", button)
		button.text:FontTemplate()
		button.text:Point("CENTER", button, "CENTER", 0, -1)
		button.text:SetJustifyH("CENTER")
		button.text:SetText(text)
		button:SetFontString(button.text)
	end

	tinsert(Sbuttons, button)
end

function AB:SetSymbloColor()
	local color = AB.db.microbar.classColor and (E.myclass == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass])) or AB.db.microbar.colorS

	for i = 1, #Sbuttons do
		Sbuttons[i].text:SetTextColor(color.r, color.g, color.b)
	end
end

function AB:SetupSymbolBar()
	local frame = CreateFrame("Frame", "ElvUI_MicroBarS", E.UIParent)
	frame:Point("CENTER", ElvUI_MicroBar, 0, 0)
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", onEnter)
	frame:SetScript("OnLeave", onLeave)

	AB:CreateSymbolButton("EMB_Character", L["CHARACTER_SYMBOL"], MicroButtonTooltipText(CHARACTER_INFO, "TOGGLECHARACTER0"), function() ToggleFrame(_G["CharacterFrame"]) end)
	AB:CreateSymbolButton("EMB_Spellbook", L["SPELLBOOK_SYMBOL"], MicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK"), function() ToggleFrame(_G["SpellBookFrame"]) end)
	AB:CreateSymbolButton("EMB_Talents", L["TALENTS_SYMBOL"], MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS"), function()
		if UnitLevel("player") >= 10 then
			if PlayerTalentFrame then
				if PlayerTalentFrame:IsShown() then
					HideUIPanel(PlayerTalentFrame)
				else
					ShowUIPanel(PlayerTalentFrame)
				end
			else
				LoadAddOn("Blizzard_TalentUI")
				ShowUIPanel(PlayerTalentFrame)
			end
		end
	end)
	AB:CreateSymbolButton("EMB_Achievement", L["ACHIEVEMENT_SYMBOL"], MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT"), function() ToggleAchievementFrame() end)
	AB:CreateSymbolButton("EMB_Quest", L["QUEST_SYMBOL"], MicroButtonTooltipText(QUESTLOG_BUTTON, "TOGGLEQUESTLOG"), function()
		if QuestLogFrame:IsShown() then
			HideUIPanel(QuestLogFrame)
		else
			ShowUIPanel(QuestLogFrame)
		end
	end)
	AB:CreateSymbolButton("EMB_Socials", L["SOCIAL_SYMBOL"], MicroButtonTooltipText(SOCIAL_BUTTON, "TOGGLESOCIAL"), function() ToggleFriendsFrame() end)
	AB:CreateSymbolButton("EMB_PVP", L["PVP_SYMBOL"], MicroButtonTooltipText(PLAYER_V_PLAYER, "TOGGLECHARACTER4"), function() TogglePVPFrame() end)
	AB:CreateSymbolButton("EMB_LFD", L["LFD_SYMBOL"], MicroButtonTooltipText(DUNGEONS_BUTTON, "TOGGLELFGPARENT"), function() ToggleLFDParentFrame() end)
	AB:CreateSymbolButton("EMB_MenuSys", L["MENU_SYMBOL"], MicroButtonTooltipText(MAINMENU_BUTTON, "TOGGLEGAMEMENU"), function()
		if GameMenuFrame:IsShown() then
			PlaySound("igMainMenuQuit")
			HideUIPanel(GameMenuFrame)
		else
			PlaySound("igMainMenuOpen")
			ShowUIPanel(GameMenuFrame)
		end
	end)
	AB:CreateSymbolButton("EMB_Help", L["HELP_SYMBOL"], HELP_BUTTON, function() ToggleHelpFrame() end)

	AB:UpdateMicroPositionDimensions()
end

function AB:UpdateMicroPositionDimensions()
	if not ElvUI_MicroBar then return end

	local numRows = 1
	local prevButton = ElvUI_MicroBar
	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + self.db.microbar.buttonSpacing)
	for i = 1, #MICRO_BUTTONS do
		local button = _G[MICRO_BUTTONS[i]]
		local lastColumnButton = i - self.db.microbar.buttonsPerRow
		lastColumnButton = _G[MICRO_BUTTONS[lastColumnButton]]

		button:Size(self.db.microbar.buttonSize, self.db.microbar.buttonSize * 1.4)
		button:ClearAllPoints()

		if prevButton == ElvUI_MicroBar then
			button:Point("TOPLEFT", prevButton, "TOPLEFT", offset, -offset)
		elseif (i - 1) % self.db.microbar.buttonsPerRow == 0 then
			button:Point("TOP", lastColumnButton, "BOTTOM", 0, -spacing - self.db.microbar.yOffset)
			numRows = numRows + 1
		else
			button:Point("LEFT", prevButton, "RIGHT", spacing + self.db.microbar.xOffset, 0)
		end

		prevButton = button
	end

	if AB.db.microbar.mouseover and not ElvUI_MicroBar:IsMouseOver() then
		ElvUI_MicroBar:SetAlpha(0)
	else
		ElvUI_MicroBar:SetAlpha(self.db.microbar.alpha)
	end

	AB.MicroWidth = (((_G["CharacterMicroButton"]:GetWidth() + spacing) * self.db.microbar.buttonsPerRow) - spacing) + (offset * 2 + (self.db.microbar.xOffset * (self.db.microbar.buttonsPerRow - 1)))
	AB.MicroHeight = (((_G["CharacterMicroButton"]:GetHeight() + spacing) * numRows) - spacing) + (offset * 2 + (self.db.microbar.yOffset * (numRows - 1)) + E.Border*2)
	ElvUI_MicroBar:Size(AB.MicroWidth, AB.MicroHeight)

	if not ElvUI_MicroBar.backdrop then
		ElvUI_MicroBar:CreateBackdrop("Transparent")
	end

	local style = self.db.microbar.transparentBackdrop and "Transparent" or "Default"
	if ElvUI_MicroBar then
		ElvUI_MicroBar.backdrop:SetTemplate(style)
		ElvUI_MicroBar.backdrop:Point("BOTTOMLEFT", 0, 1)
	end

	if ElvUI_MicroBar.mover then
		if self.db.microbar.enabled then
			E:EnableMover(ElvUI_MicroBar.mover:GetName())
		else
			E:DisableMover(ElvUI_MicroBar.mover:GetName())
		end
	end

	if not Sbuttons[1] then return end

	AB:MenuShow()

	local numRowsS = 1
	prevButton = ElvUI_MicroBarS
	for i = 1, #Sbuttons do
		local button = Sbuttons[i]
		local lastColumnButton = i - self.db.microbar.buttonsPerRow
		lastColumnButton = Sbuttons[lastColumnButton]

		button:Size(self.db.microbar.buttonSize, self.db.microbar.buttonSize * 1.4)
		button:ClearAllPoints()

		if prevButton == ElvUI_MicroBarS then
			button:Point("TOPLEFT", prevButton, "TOPLEFT", offset, -offset)
		elseif (i - 1) % self.db.microbar.buttonsPerRow == 0 then
			button:Point("TOP", lastColumnButton, "BOTTOM", 0, -spacing - self.db.microbar.yOffset)
			numRowsS = numRowsS + 1
		else
			button:Point("LEFT", prevButton, "RIGHT", spacing + self.db.microbar.xOffset, 0)
		end

		prevButton = button
	end

	ElvUI_MicroBarS:Size(AB.MicroWidth, AB.MicroHeight)

	if not ElvUI_MicroBarS.backdrop then
		ElvUI_MicroBarS:CreateBackdrop("Transparent")
	end

	if ElvUI_MicroBar then
		ElvUI_MicroBarS.backdrop:SetTemplate(style)
		ElvUI_MicroBarS.backdrop:Point("BOTTOMLEFT", 0, 1)
	end

	if AB.db.microbar.backdrop then
		ElvUI_MicroBar.backdrop:Show()
		ElvUI_MicroBarS.backdrop:Show()
	else
		ElvUI_MicroBar.backdrop:Hide()
		ElvUI_MicroBarS.backdrop:Hide()
	end

	if AB.db.microbar.mouseover and not ElvUI_MicroBar:IsMouseOver() then
		ElvUI_MicroBarS:SetAlpha(0)
	elseif not (AB.db.microbar.mouseover and ElvUI_MicroBar:IsMouseOver()) and AB.db.microbar.symbolic then
		ElvUI_MicroBarS:SetAlpha(AB.db.microbar.alpha)
	end

	AB:SetSymbloColor()
end

function AB:MenuShow()
	if AB.db.microbar.symbolic then
		if AB.db.microbar.enabled then
			ElvUI_MicroBar:Hide()
			ElvUI_MicroBarS:Show()
			if not AB.db.microbar.mouseover then
				E:UIFrameFadeIn(ElvUI_MicroBarS, 0.2, ElvUI_MicroBarS:GetAlpha(), AB.db.microbar.alpha)
			end
		else
			ElvUI_MicroBarS:Hide()
		end
	else
		if AB.db.microbar.enabled then
			ElvUI_MicroBar:Show()
		end
		ElvUI_MicroBarS:Hide()
	end
end

function AB:EnhancementInit()
	EP:RegisterPlugin(addon, AB.GetOptions)
	AB:SetupSymbolBar()
	AB:MenuShow()

	_G["EMB_MenuSys"]:SetScript("OnUpdate", function(self, elapsed)
		if self.updateInterval > 0 then
			self.updateInterval = self.updateInterval - elapsed
		else
			self.updateInterval = PERFORMANCEBAR_UPDATE_INTERVAL
			if self.hover then
				MainMenuBarPerformanceBarFrame_OnEnter(_G["MainMenuMicroButton"])
			end
		end
	end)
end

hooksecurefunc(AB, "SetupMicroBar", AB.EnhancementInit)