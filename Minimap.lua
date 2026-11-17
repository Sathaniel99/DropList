-- DropList - botón del minimapa
local DropList = _G.DropList or {}
_G.DropList = DropList

local L = DropList.L

function DropList:UpdateMinimapPosition()
	local button = self.minimapButton
	if not button then
		return
	end
	local angle = math.rad(self:Settings().minimapAngle or 210)
	local radius = 78
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function DropList:CreateMinimapButton()
	if self.minimapButton then
		self.minimapButton:Show()
		self:UpdateMinimapPosition()
		return self.minimapButton
	end

	local button = CreateFrame("Button", "DropListMinimapButton", Minimap)
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetClampedToScreen(true)
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.border = border

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	button.icon = icon

	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local minimapX, minimapY = Minimap:GetCenter()
			local cursorX, cursorY = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			if not minimapX or not scale or scale == 0 then
				return
			end
			cursorX, cursorY = cursorX / scale, cursorY / scale
			local angle = math.deg(math.atan2(cursorY - minimapY, cursorX - minimapX))
			DropList:Settings().minimapAngle = angle
			DropList:UpdateMinimapPosition()
		end)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			DropList:ShowMinimapMenu()
		else
			DropList:Toggle()
		end
	end)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(DropList:ColorText("DropList"))
		GameTooltip:AddLine(L.HelpShow, 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Click derecho: " .. L.MenuOptions, 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self.minimapButton = button
	self:UpdateMinimapPosition()
	if self.SkinMinimapButton then
		self:SkinMinimapButton(button)
	end
	return button
end

function DropList:SetMinimapVisible(visible)
	self:Settings().minimap = visible and true or false
	if visible then
		self:CreateMinimapButton()
		self:Print(L.MinimapOn, 0.8, 0.8, 0.8)
	elseif self.minimapButton then
		self.minimapButton:Hide()
		self:Print(L.MinimapOff, 0.8, 0.8, 0.8)
	end
end

function DropList:ShowMinimapMenu()
	if not self.contextMenu then
		self.contextMenu = CreateFrame("Frame", "DropListContextMenu", UIParent, "UIDropDownMenuTemplate")
	end
	local menu = {
		{ text = L.MenuScale, hasArrow = true, notCheckable = true, menuList = {
			{ text = L.MenuScale .. " 0.8", notCheckable = true, func = function() DropList:ApplyScale(0.8) end },
			{ text = L.MenuScale .. " 1.0", notCheckable = true, func = function() DropList:ApplyScale(1.0) end },
			{ text = L.MenuScale .. " 1.2", notCheckable = true, func = function() DropList:ApplyScale(1.2) end },
		} },
		{ text = L.MenuMinimap, checked = self:Settings().minimap, isNotRadio = true,
			func = function() DropList:SetMinimapVisible(not DropList:Settings().minimap) end },
		{ text = L.MenuTooltip, checked = self:Settings().tooltipButton, isNotRadio = true,
			func = function() DropList:CommandTooltip() end },
		{ text = L.MenuColor, hasArrow = true, notCheckable = true, menuList = {
			{ text = "Azul", notCheckable = true, func = function() DropList:CommandColor("azul") end },
			{ text = "Cian", notCheckable = true, func = function() DropList:CommandColor("cian") end },
			{ text = "Verde", notCheckable = true, func = function() DropList:CommandColor("verde") end },
			{ text = "Dorado", notCheckable = true, func = function() DropList:CommandColor("dorado") end },
			{ text = "Morado", notCheckable = true, func = function() DropList:CommandColor("morado") end },
			{ text = "Rojo", notCheckable = true, func = function() DropList:CommandColor("rojo") end },
		} },
		{ text = L.MenuTest, notCheckable = true, func = function() DropList:RunSelfTest() end },
		{ text = L.MenuReset, notCheckable = true, func = function() DropList:ConfirmClear() end },
		{ text = L.MenuHelp, notCheckable = true, func = function() DropList:PrintHelp() end },
	}
	EasyMenu(menu, self.contextMenu, "cursor", 0, 0, "MENU")
end
