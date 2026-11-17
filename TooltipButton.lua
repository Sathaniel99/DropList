local DropList = _G.DropList
if not DropList then return end

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

local function OnAddClick(self)
	local link = self.itemLink
	if not link then return end

	local item = DropList:ResolveItem(link) -- normaliza el enlace
	if item then
		DropList:AddItem(item) -- usa la lógica interna del addon
	else
		DropList:Print(DropList.L.InvalidItemShort, 1, 0.3, 0.3)
	end
end

local function CreateButton(parent)
	if addButton then return addButton end

	addButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	addButton:SetSize(76, 20)
	addButton:SetText(DropList.L.Add)
	addButton:SetScript("OnClick", OnAddClick)
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
		addButton:ClearAllPoints()
		addButton:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10, 10)
		addButton:Show()
	end)

	ItemRefTooltip:HookScript("OnHide", function()
		if addButton then addButton:Hide() end
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
