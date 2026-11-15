-- DropList - ventana principal: una lista simple de objetos
local DropList = _G.DropList or {}
_G.DropList = DropList

local W = DropList.Widgets
local L = DropList.L
local M = DropList.Model

local ROW_HEIGHT = 30
local ROW_COUNT = 11

function DropList:CreateMainFrame()
	if self.main then
		return self.main
	end

	local f = W.Panel("DropListFrame", 440, 520, nil, true)
	self.main = f
	f.onMove = function(frame)
		self:SavePosition(frame, "mainPos")
	end
	f:SetScript("OnShow", function()
		self:Refresh()
	end)
	-- Red de seguridad: con la ventana abierta se mantiene a la vista el último
	-- objeto del tooltip, aunque otro addon reemplace el callback OnTooltipSetItem.
	f:SetScript("OnUpdate", function()
		local tooltip = GameTooltip
		if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then
			return
		end
		local _, link = tooltip:GetItem()
		if link and link ~= tooltip.dropListLink then
			tooltip.dropListLink = link
			DropList:RememberItemLink(link)
		end
	end)
	f:SetScript("OnReceiveDrag", function()
		self:AddFromCursor()
	end)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -14)
	f.title:SetText("DropList")

	-- ============================================================
	-- Sección 1: Buscar (ancho completo, centrado)
	-- ============================================================
	local search = W.EditBox(f, 404, 22)
	search:SetPoint("TOP", f, "TOP", 0, -40)

	search.placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	search.placeholder:SetPoint("LEFT", search, "LEFT", 6, 0)
	search.placeholder:SetText(L.Search)
	search.placeholder:SetJustifyH("LEFT")

	search:SetScript("OnTextChanged", function(self)
		if self:GetText() == "" then
			self.placeholder:Show()
		else
			self.placeholder:Hide()
		end
		DropList:Settings().search = self:GetText() or ""
		DropList:Refresh()
	end)
	search:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	search:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
	f.search = search

	-- ============================================================
	-- Sección 2: Contadores (centrados, debajo de la búsqueda)
	-- ============================================================
	f.countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.countLabel:SetPoint("TOP", search, "BOTTOM", 0, -6)
	f.countLabel:SetJustifyH("CENTER")

	f.itemHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.itemHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -94)
	f.itemHeader:SetText(L.Item)

	f.countHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.countHeader:SetPoint("TOPRIGHT", f, "TOPRIGHT", -130, -94)
	f.countHeader:SetText(L.Count)

	f.itemList = W.List(f, "DropListItemScroll", 404, ROW_COUNT * ROW_HEIGHT, ROW_HEIGHT, ROW_COUNT, {
		onCreateRow = function(row)
			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(24, 24)
			row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
			row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

			row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row.name:SetPoint("LEFT", row, "LEFT", 38, 0)
			row.name:SetWidth(210)
			row.name:SetJustifyH("LEFT")
			row.name:SetWordWrap(false)

			row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			row.count:SetPoint("RIGHT", row, "RIGHT", -80, 0)
			row.count:SetWidth(40)
			row.count:SetJustifyH("RIGHT")

			-- De izquierda a derecha: [X] [+] [-]. El - solo se muestra a partir de x2 y
			-- + / - se ocultan en el equipo (un botón, como antes).
			local function rowButton(offset, text, tooltip, onClick)
				local button = W.Button(row, text, 20, 18, onClick)
				button:SetPoint("RIGHT", row, "RIGHT", offset, 0)
				button:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(tooltip)
					GameTooltip:Show()
				end)
				button:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
				return button
			end

			row.remove = rowButton(-52, "X", L.Remove, function(self)
				local entry = self:GetParent().data
				if entry then
					DropList:RemoveEntry(entry.itemID)
				end
			end)
			row.plus = rowButton(-28, "+", L.AddOne, function(self)
				local entry = self:GetParent().data
				if entry then
					DropList:AdjustEntry(entry.itemID, 1)
				end
			end)
			row.minus = rowButton(-4, "-", L.RemoveOne, function(self)
				local entry = self:GetParent().data
				if entry then
					DropList:AdjustEntry(entry.itemID, -1)
				end
			end)
		end,
		onUpdateRow = function(row, entry)
			row.name:SetText(M:DisplayName(entry))
			row.name:SetTextColor(DropList:GetQualityColor(entry.quality))
			row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			row.count:SetText("x" .. tostring(entry.count or 1))
			row.selected:Hide()

			local countable = not DropList:IsEquipableEntry(entry)
			if countable then
				row.plus:Show()
			else
				row.plus:Hide()
			end
			if countable and (tonumber(entry.count) or 1) > 1 then
				row.minus:Show()
			else
				row.minus:Hide()
			end
		end,
		onClick = function(_, entry, mouseButton)
			if mouseButton == "RightButton" then
				DropList:RemoveEntry(entry.itemID)
			end
		end,
		onEnter = function(row, entry)
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(entry.link or ("item:" .. tostring(entry.itemID)))
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(string.format(L.Count .. ": %d", entry.count or 1), 1, 1, 1)
			if DropList:IsEquipableEntry(entry) then
				GameTooltip:AddLine(L.RowHint, 0.8, 0.8, 0.8)
			else
				GameTooltip:AddLine(L.RowHintCount, 0.8, 0.8, 0.8)
			end
			GameTooltip:Show()
		end,
	})
	f.itemList:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -112)

	f.emptyText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.emptyText:SetPoint("CENTER", f.itemList, "CENTER", 0, 20)
	f.emptyText:SetWidth(340)
	f.emptyText:SetJustifyH("CENTER")

	f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 48)
	f.hint:SetText("/droplist add <enlace|ID>")

	f.lastItem = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.lastItem:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 64)
	f.lastItem:SetWidth(400)
	f.lastItem:SetJustifyH("LEFT")
	f.lastItem:SetText(L.LastCapturedNone)
	f.lastItem:SetTextColor(0.55, 0.55, 0.55)

	f.addButton = W.Button(f, L.Add, 100, 24, function()
		DropList:AddFromUI()
	end)
	f.addButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 20)
	f.addButton:RegisterForClicks("LeftButtonUp")
	f.addButton:RegisterForDrag("LeftButton")
	f.addButton:SetScript("OnReceiveDrag", function()
		DropList:AddFromCursor()
	end)
	f.addButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.AddItem)
		local item = DropList.lastItemLink and DropList:ResolveItem(DropList.lastItemLink)
		if item then
			GameTooltip:AddLine(string.format(L.LastCaptured, item.name), 0.66, 0.84, 1, true)
		else
			GameTooltip:AddLine(L.LastCapturedNone, 0.8, 0.8, 0.8, true)
		end
		GameTooltip:AddLine(L.AddHint, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	f.addButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	f.undoButton = W.Button(f, L.Undo, 100, 24, function()
		if M:Undo() then
			DropList:Refresh()
			DropList:Print(L.Undone, 0.4, 1, 0.4)
		else
			DropList:Print(L.NothingUndo)
		end
	end)
	f.undoButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 124, 20)

	f.clearButton = W.Button(f, L.Clear, 100, 24, function()
		DropList:ConfirmClear()
	end)
	f.clearButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 230, 20)

	f.hideButton = W.Button(f, L.Close, 90, 24, function()
		f:Hide()
	end)
	f.hideButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 20)

	self:RestorePosition(f, "mainPos")
	f:SetScale(DropList:Settings().scale or 1)
	if self.ApplySkin then
		self:ApplySkin()
	end
	return f
end

function DropList:InitMainFrameValues()
	self.main.search:SetText(self:Settings().search or "")
end

function DropList:RemoveEntry(itemID)
	local removed, entry = M:Remove(itemID)
	if not removed then
		return
	end
	self:Refresh()
	self:Print(string.format(L.Removed, M:DisplayName(entry)), 0.8, 0.8, 0.8)
end

-- Botones de fila - / +: silenciosos (sin spam en el chat) y sin deshacer.
function DropList:AdjustEntry(itemID, delta)
	local entry, changed = M:Adjust(itemID, delta)
	if not entry or not changed then
		return
	end
	self:Refresh()
end

function DropList:Refresh()
	if not self.main then
		return
	end
	self:EnrichEntries()

	local settings = self:Settings()
	local entries = M:EntryList({ text = settings.search })
	self.main.itemList:SetData(entries)

	local stats = M:Stats()
	self.main.countLabel:SetText(string.format(L.Total, stats.items, stats.units))

	local undoCount = M:UndoCount()
	if undoCount > 0 then
		self.main.undoButton:SetText(L.Undo .. " (" .. undoCount .. ")")
		self.main.undoButton:Enable()
	else
		self.main.undoButton:SetText(L.Undo)
		self.main.undoButton:Disable()
	end

	if stats.items == 0 then
		self.main.emptyText:SetText(L.Empty .. "\n|cff808080" .. L.EmptyHint .. "|r")
		self.main.emptyText:Show()
	elseif #entries == 0 then
		self.main.emptyText:SetText(L.NoResults)
		self.main.emptyText:Show()
	else
		self.main.emptyText:Hide()
	end

	if self.UpdateLastItemLabel then
		self:UpdateLastItemLabel()
	end
end