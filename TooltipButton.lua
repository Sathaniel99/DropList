local DropList = _G.DropList
if not DropList then return end

local L = DropList.L
local addButton

-- Calidades permitidas para el botón, según la configuración guardada.
local function AllowedQualities()
	local settings = DropList:Settings()
	local configured = settings and settings.tooltipQualities
	if type(configured) == "table" then
		if IsInGroup() or IsInRaid() then
			return configured.group or configured.solo
		end
		return configured.solo or configured.group
	end

	-- Respaldo por si el jugador guardó una configuración antigua.
	if IsInGroup() or IsInRaid() then
		return { [3] = true, [4] = true, [5] = true }
	end
	return { [2] = true, [3] = true, [4] = true, [5] = true }
end

-- Confirmación visual: texto corto y borde verde que se apaga solo.
local function FlashAdded(button)
	button.flashTime = 0.5
	button:SetText(L.AddedShort)
	button:SetScript("OnUpdate", function(self, elapsed)
		self.flashTime = (self.flashTime or 0) - (elapsed or 0)
		if self.flashTime <= 0 then
			self:SetScript("OnUpdate", nil)
			self.flashTime = nil
			self:SetText(L.Add)
			if DropList.Widgets then
				DropList.Widgets.StyleButton(self)
			end
		else
			self:SetBackdropBorderColor(0.4, 1, 0.4, self.flashTime / 0.5)
		end
	end)
end

local function OnAddClick(self)
	local link = self.itemLink
	if not link then return end

	local item = DropList:ResolveItem(link) -- normaliza el enlace
	if item then
		DropList:AddItem(item) -- usa la lógica interna del addon
		FlashAdded(self)
	else
		DropList:Print(L.InvalidItemShort, 1, 0.3, 0.3)
	end
end

local function CreateButton(parent)
	if addButton then return addButton end

	-- Botón plano propio: la misma base que usa la ventana principal.
	if DropList.Widgets then
		addButton = DropList.Widgets.Button(parent, L.Add, 80, 20, OnAddClick)
	else
		addButton = CreateFrame("Button", nil, parent)
		addButton:SetSize(80, 20)
		addButton:SetScript("OnClick", OnAddClick)
	end

	local icon = addButton:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", addButton, "LEFT", 3, 0)
	addButton.icon = icon

	local fontString = addButton.GetFontString and addButton:GetFontString()
	if fontString then
		fontString:SetPoint("LEFT", addButton, "LEFT", 20, 0)
		fontString:SetJustifyH("LEFT")
	end
	return addButton
end

local function HookItemRef()
	if not ItemRefTooltip then return end

	ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
		CreateButton(tooltip)

		local settings = DropList:Settings()
		local _, link = tooltip:GetItem()
		if not link or (settings and settings.tooltipButton == false) then
			addButton:Hide()
			return
		end

		local item = DropList:ResolveItem(link)
		if not item then
			addButton:Hide()
			return
		end

		local allowed = AllowedQualities()
		if item.quality and allowed and not allowed[item.quality] then
			addButton:Hide()
			return
		end

		addButton.itemLink = link
		addButton.flashTime = nil
		addButton:SetText(L.Add)
		addButton:ClearAllPoints()
		addButton:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10, 10)
		addButton:Show()
		if DropList.Widgets then
			DropList.Widgets.StyleButton(addButton)
		end
	end)

	ItemRefTooltip:HookScript("OnHide", function()
		if addButton then
			addButton:SetScript("OnUpdate", nil)
			addButton.flashTime = nil
			addButton:Hide()
		end
	end)
end

-- ItemRefTooltip se crea al inicio; si no existe aún, esperamos a PLAYER_LOGIN.
if ItemRefTooltip then
	HookItemRef()
else
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_LOGIN")
	f:SetScript("OnEvent", function()
		HookItemRef()
		f:UnregisterAllEvents()
	end)
end
