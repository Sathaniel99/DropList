-- DropList - ventana principal: lista de objetos con filtros y columnas
local DropList = _G.DropList or {}
_G.DropList = DropList

local W = DropList.Widgets
local L = DropList.L
local M = DropList.Model

local ROW_HEIGHT = 30
local DEFAULT_ROWS = 11
local LIST_TOP = 114
local FOOTER = 78
local MIN_WIDTH, MAX_WIDTH = 440, 760
local MIN_HEIGHT, MAX_HEIGHT = 380, 820

local function clamp(value, minimum, maximum)
	value = tonumber(value) or minimum
	if value < minimum then value = minimum end
	if value > maximum then value = maximum end
	return value
end

-- Crea un separador de columna que se puede arrastrar con el ratón.
local function createDivider(parent, hint)
	local handle = CreateFrame("Frame", nil, parent)
	handle:SetSize(10, 18)
	handle:EnableMouse(true)
	handle.line = handle:CreateTexture(nil, "ARTWORK")
	handle.line:SetTexture("Interface\\Buttons\\WHITE8X8")
	handle.line:SetSize(1, 16)
	handle.line:SetPoint("CENTER")
	handle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(hint, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	handle:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return handle
end

local function startColumnDrag(handle, which, frame)
	handle.dragging = true
	handle:SetScript("OnUpdate", function(self)
		if not self.dragging or not GetCursorPosition then
			return
		end
		local scale = frame:GetEffectiveScale() or 1
		local cursorX = GetCursorPosition() / scale
		local listLeft = (frame:GetLeft() or 0) + 18
		DropList:SetColumnWidth(which, cursorX - listLeft)
	end)
	handle:SetScript("OnMouseUp", function(self)
		self.dragging = false
		self:SetScript("OnUpdate", nil)
	end)
end

function DropList:CreateMainFrame()
	if self.main then
		return self.main
	end

	local f = W.Panel("DropListFrame", 440, 520, nil, true)
	self.main = f
	f.onMove = function(frame)
		self:SavePosition(frame, "mainPos")
	end
	f.onResize = function(frame)
		self:SaveFrameSize(frame)
	end
	f:SetScript("OnShow", function()
		-- Fade propio: así no se pisa el OnUpdate que recuerda el tooltip.
		f:SetAlpha(0)
		f.dropListFade = 0
		self:Refresh()
	end)
	-- Fade de entrada + red de seguridad: con la ventana abierta se recuerda el
	-- último objeto del tooltip. Se consulta cada 0,2 s en vez de en cada fotograma.
	f:SetScript("OnUpdate", function(self, elapsed)
		elapsed = elapsed or 0
		if self.dropListFade and self.dropListFade < 0.18 then
			self.dropListFade = self.dropListFade + elapsed
			self:SetAlpha(math.min(1, self.dropListFade / 0.18))
		elseif self.dropListFade then
			self.dropListFade = nil
			self:SetAlpha(1)
		end
		self.dropListTooltipElapsed = (self.dropListTooltipElapsed or 0) + elapsed
		if self.dropListTooltipElapsed < 0.2 then
			return
		end
		self.dropListTooltipElapsed = 0
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
	f:SetScript("OnSizeChanged", function()
		if not f.__applyingLayout then
			DropList:LayoutMainFrame()
		end
	end)
	-- Arranca invisible: el fade se hace al mostrar la ventana.
	f:SetAlpha(0)

	-- Cabecera -------------------------------------------------------------
	f.titleBar = f:CreateTexture(nil, "BACKGROUND")
	f.titleBar:SetTexture("Interface\\Buttons\\WHITE8X8")
	f.titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
	f.titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
	f.titleBar:SetHeight(30)

	f.titleIcon = f:CreateTexture(nil, "OVERLAY")
	f.titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
	f.titleIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.titleIcon:SetSize(22, 22)
	f.titleIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 42, -10)
	f.title:SetText("DropList")

	f.titleDivider = f:CreateTexture(nil, "ARTWORK")
	f.titleDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
	f.titleDivider:SetHeight(1)
	f.titleDivider:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -36)
	f.titleDivider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -36)

	-- Buscador con lupa -----------------------------------------------------
	local search = W.EditBox(f, 404, 22)
	search:SetPoint("TOP", f, "TOP", 0, -46)

	f.searchIcon = f:CreateTexture(nil, "OVERLAY")
	f.searchIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")
	f.searchIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.searchIcon:SetSize(14, 14)
	f.searchIcon:SetPoint("LEFT", search, "LEFT", 7, 0)

	search.placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	search.placeholder:SetPoint("LEFT", search, "LEFT", 26, 0)
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

	-- Barra de herramientas: filtros y contador -----------------------------
	f.toolbar = CreateFrame("Frame", nil, f)
	f.toolbar:SetHeight(22)
	f.toolbar:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -72)
	f.toolbar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -18, -72)

	f.filterButtons = {}
	local filters = {
		{ key = "all", label = L.FilterAll },
		{ key = "equip", label = L.FilterEquip },
		{ key = "stack", label = L.FilterStack },
	}
	for index, spec in ipairs(filters) do
		local button = W.Button(f.toolbar, spec.label, index == 1 and 48 or 58, 20, function()
			DropList:SetFilter(spec.key)
		end)
		button:SetPoint("LEFT", f.toolbar, "LEFT", (index - 1) * 64, 0)
		button.filterKey = spec.key
		f.filterButtons[spec.key] = button
	end

	f.statsChip = CreateFrame("Frame", nil, f.toolbar)
	f.statsChip:SetSize(170, 20)
	f.statsChip:SetBackdrop(W.InputBackdrop)
	f.statsChip:SetPoint("RIGHT", f.toolbar, "RIGHT", 0, 0)
	f.countLabel = f.statsChip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.countLabel:SetPoint("CENTER")
	f.countLabel:SetJustifyH("CENTER")

	-- Cabeceras y separadores de columnas ----------------------------------
	f.itemHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.itemHeader:SetText(L.Item)
	f.countHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.countHeader:SetText(L.Count)

	f.nameDivider = createDivider(f, L.ColumnHint)
	f.countDivider = createDivider(f, L.ColumnHint)
	f.nameDivider:SetScript("OnMouseDown", function()
		startColumnDrag(f.nameDivider, "name", f)
	end)
	f.countDivider:SetScript("OnMouseDown", function()
		startColumnDrag(f.countDivider, "count", f)
	end)

	-- Lista ----------------------------------------------------------------
	f.itemList = W.List(f, "DropListItemScroll", 404, DEFAULT_ROWS * ROW_HEIGHT, ROW_HEIGHT, DEFAULT_ROWS, {
		onCreateRow = function(row, index)
			row.bg = row:CreateTexture(nil, "BACKGROUND")
			row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
			row.bg:SetAllPoints(row)
			row.bg:SetVertexColor(0.2, 0.3, 0.4, index % 2 == 0 and 0.10 or 0.03)

			row.qualityBar = row:CreateTexture(nil, "ARTWORK")
			row.qualityBar:SetTexture("Interface\\Buttons\\WHITE8X8")
			row.qualityBar:SetWidth(3)
			row.qualityBar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
			row.qualityBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)

			row.iconBorder = CreateFrame("Frame", nil, row)
			row.iconBorder:SetSize(26, 26)
			row.iconBorder:SetPoint("LEFT", row, "LEFT", 5, 0)
			row.iconBorder:SetBackdrop({
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 8,
				insets = { left = 2, right = 2, top = 2, bottom = 2 },
			})

			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(22, 22)
			row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
			row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

			row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row.name:SetPoint("LEFT", row, "LEFT", 38, 0)
			row.name:SetWidth(210)
			row.name:SetJustifyH("LEFT")
			row.name:SetWordWrap(false)

			row.columnDivider = row:CreateTexture(nil, "ARTWORK")
			row.columnDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
			row.columnDivider:SetSize(1, ROW_HEIGHT - 8)
			row.columnDivider:SetPoint("CENTER", row, "LEFT", 252, 0)

			row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			row.count:SetPoint("LEFT", row, "LEFT", 260, 0)
			row.count:SetWidth(40)
			row.count:SetJustifyH("RIGHT")

			-- De izquierda a derecha: [X] [+] [-]. El - solo se muestra a partir de x2.
			local function rowButton(offset, text, tooltip, onClick)
				local button = W.Button(row, text, 20, 18, onClick)
				button:SetPoint("RIGHT", row, "RIGHT", offset, 0)
				button:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(tooltip, 1, 1, 1, true)
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
		onUpdateRow = function(row, entry, index)
			row.name:SetText(M:DisplayName(entry))
			row.name:SetTextColor(DropList:GetQualityColor(entry.quality))
			row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			row.count:SetText("x" .. tostring(entry.count or 1))

			local r, g, b = DropList:GetQualityColor(entry.quality)
			row.qualityBar:SetVertexColor(r, g, b, 0.85)

			local bgR, bgG, bgB = DropList:FrameBackground()
			row.bg:SetVertexColor(bgR + 0.15, bgG + 0.15, bgB + 0.15,
				index % 2 == 0 and 0.10 or 0.03)

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
	f.itemList:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -LIST_TOP)
	f.itemHeader:SetPoint("LEFT", f.itemList, "LEFT", 20, 16)
	f.countHeader:SetPoint("LEFT", f.itemList, "LEFT", 260, 16)

	-- Estado vacío ----------------------------------------------------------
	f.emptyIcon = f:CreateTexture(nil, "ARTWORK")
	f.emptyIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
	f.emptyIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.emptyIcon:SetSize(48, 48)
	f.emptyIcon:SetPoint("CENTER", f.itemList, "CENTER", 0, 28)

	f.emptyText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.emptyText:SetPoint("CENTER", f.itemList, "CENTER", 0, -12)
	f.emptyText:SetWidth(340)
	f.emptyText:SetJustifyH("CENTER")

	f.emptyButton = W.Button(f.itemList, L.AddItem, 130, 22, function()
		DropList:AddFromUI()
	end)
	f.emptyButton:SetPoint("TOP", f.emptyText, "BOTTOM", 0, -8)
	f.emptyButton:RegisterForDrag("LeftButton")
	f.emptyButton:SetScript("OnReceiveDrag", function()
		DropList:AddFromCursor()
	end)
	f.emptyButton:Hide()

	-- Pie de ventana --------------------------------------------------------
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
		GameTooltip:SetText(L.AddItem, 1, 1, 1, true)
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

	-- Tirador para redimensionar --------------------------------------------
	f.resizeGrip = CreateFrame("Frame", nil, f)
	f.resizeGrip:SetSize(16, 16)
	f.resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
	f.resizeGrip:EnableMouse(true)
	f.resizeGrip.line = f.resizeGrip:CreateTexture(nil, "ARTWORK")
	f.resizeGrip.line:SetTexture("Interface\\Buttons\\WHITE8X8")
	f.resizeGrip.line:SetSize(12, 2)
	f.resizeGrip.line:SetPoint("CENTER")
	pcall(f.resizeGrip.line.SetRotation, f.resizeGrip.line, math.rad(-45))
	f.resizeGrip:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.ResizeHint, 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	f.resizeGrip:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	f.resizeGrip:SetScript("OnMouseDown", function()
		f:StartSizing("BOTTOMRIGHT")
	end)
	f.resizeGrip:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		DropList:SaveFrameSize(f)
	end)

	self:RestorePosition(f, "mainPos")
	self:ApplyFrameSize()
	f:SetScale(DropList:Settings().scale or 1)
	if self.ApplySkin then
		self:ApplySkin()
	end
	self:UpdateFilterButtons()
	return f
end

-- Tamaño y columnas ------------------------------------------------------------

function DropList:SaveFrameSize(frame)
	local settings = self:Settings()
	settings.frameSize = settings.frameSize or {}
	settings.frameSize.width = clamp(frame:GetWidth(), MIN_WIDTH, MAX_WIDTH)
	settings.frameSize.height = clamp(frame:GetHeight(), MIN_HEIGHT, MAX_HEIGHT)
end

-- Coloca los hijos según el tamaño actual, sin volver a fijar el tamaño del marco.
function DropList:LayoutMainFrame()
	local f = self.main
	if not f or not f.itemList then
		return
	end
	local width = clamp(f:GetWidth(), MIN_WIDTH, MAX_WIDTH)
	local height = clamp(f:GetHeight(), MIN_HEIGHT, MAX_HEIGHT)
	local listWidth = width - 36
	local listHeight = math.max(90, height - LIST_TOP - FOOTER)

	f.search:SetWidth(listWidth)
	f.itemList:SetSize(listWidth, listHeight)
	f.itemList:SetVisibleRows(math.floor(listHeight / ROW_HEIGHT))
	f.emptyText:SetWidth(listWidth - 60)
	f.lastItem:SetWidth(listWidth)
	self:ApplyColumnLayout()
end

function DropList:ApplyFrameSize()
	local f = self.main
	if not f then
		return
	end
	local settings = self:Settings()
	settings.frameSize = settings.frameSize or {}
	f.__applyingLayout = true
	f:SetSize(
		clamp(settings.frameSize.width or 440, MIN_WIDTH, MAX_WIDTH),
		clamp(settings.frameSize.height or 520, MIN_HEIGHT, MAX_HEIGHT)
	)
	f.__applyingLayout = false
	self:LayoutMainFrame()
end

function DropList:ApplyColumnLayout()
	local f = self.main
	if not f or not f.itemList then
		return
	end
	local settings = self:Settings()
	settings.columns = settings.columns or {}
	local listWidth = f.itemList:GetWidth() or 404
	local countW = clamp(settings.columns.count or 40, 30, 90)
	local maxName = listWidth - 50 - countW - 84
	local nameW = clamp(settings.columns.name or 210, 110, math.max(110, maxName))
	if maxName < 110 then
		countW = clamp(listWidth - 50 - 110 - 84, 30, 90)
		nameW = 110
	end
	settings.columns.name = nameW
	settings.columns.count = countW

	local countX = 50 + nameW
	f.countHeader:SetPoint("LEFT", f.itemList, "LEFT", countX, 16)
	f.nameDivider:SetPoint("CENTER", f.itemList, "LEFT", 42 + nameW, 0)
	f.countDivider:SetPoint("CENTER", f.itemList, "LEFT", countX + countW + 4, 0)

	for _, row in ipairs(f.itemList.rows) do
		row.name:SetWidth(nameW)
		row.columnDivider:SetPoint("CENTER", row, "LEFT", 42 + nameW, 0)
		row.count:SetPoint("LEFT", row, "LEFT", countX, 0)
		row.count:SetWidth(countW)
	end
end

function DropList:SetColumnWidth(which, value)
	local f = self.main
	if not f or not f.itemList then
		return
	end
	local settings = self:Settings()
	settings.columns = settings.columns or {}
	local listWidth = f.itemList:GetWidth() or 404
	if which == "name" then
		local maximum = listWidth - 50 - (settings.columns.count or 40) - 84
		if maximum < 110 then
			maximum = 110
		end
		settings.columns.name = clamp(value - 42, 110, maximum)
	elseif which == "count" then
		settings.columns.count = clamp(value - 54 - (settings.columns.name or 210), 30, 90)
	else
		return
	end
	self:ApplyColumnLayout()
end

function DropList:UpdateFilterButtons()
	local f = self.main
	if not f or not f.filterButtons then
		return
	end
	local current = self:Settings().filter or "all"
	for key, button in pairs(f.filterButtons) do
		DropList.Widgets.SetButtonActive(button, key == current)
	end
end

-- Confirmación visual al añadir, sin temporizadores nuevos (OnUpdate local).
function DropList:FlashAddButton()
	local button = self.main and self.main.addButton
	if not button then
		return
	end
	if button.flashTime then
		return
	end
	button.flashTime = 0.5
	button.label:SetText(L.AddedShort)
	button:SetScript("OnUpdate", function(self, elapsed)
		self.flashTime = (self.flashTime or 0) - (elapsed or 0)
		if self.flashTime <= 0 then
			self:SetScript("OnUpdate", nil)
			self.flashTime = nil
			self.label:SetText(L.Add)
			DropList.Widgets.StyleButton(self)
		else
			self:SetBackdropBorderColor(0.4, 1, 0.4, self.flashTime / 0.5)
		end
	end)
end

function DropList:InitMainFrameValues()
	self.main.search:SetText(self:Settings().search or "")
	self:UpdateFilterButtons()
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
	local filter = settings.filter or "all"
	local entries = M:EntryList({ text = settings.search, itemType = filter })
	self.main.itemList:SetData(entries)
	self:UpdateFilterButtons()

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

	local query = DropList.Trim(settings.search or "")
	if stats.items == 0 then
		self.main.emptyIcon:Show()
		self.main.emptyText:SetText(L.Empty .. "\n|cff808080" .. L.EmptyHint .. "|r")
		self.main.emptyText:Show()
		self.main.emptyButton:Show()
	elseif #entries == 0 then
		self.main.emptyIcon:Hide()
		self.main.emptyButton:Hide()
		if query ~= "" then
			self.main.emptyText:SetText(string.format(L.NoResultsQuery, query))
		else
			self.main.emptyText:SetText(L.NoResults)
		end
		self.main.emptyText:Show()
	else
		self.main.emptyIcon:Hide()
		self.main.emptyText:Hide()
		self.main.emptyButton:Hide()
	end

	if self.UpdateLastItemLabel then
		self:UpdateLastItemLabel()
	end
end
