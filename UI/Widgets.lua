-- DropList - utilidades de interfaz (compatible con 3.3.5, sin librerías)
local DropList = _G.DropList or {}
_G.DropList = DropList

local Widgets = {}
DropList.Widgets = Widgets

Widgets.Backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 },
}

-- Fondo más fino para la caja de búsqueda.
Widgets.InputBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

function Widgets.Panel(name, width, height, title, closeOnEscape)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetSize(width, height)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetBackdrop(Widgets.Backdrop)
	frame:SetBackdropColor(0.03, 0.03, 0.05, 0.94)
	frame:SetBackdropBorderColor(0.55, 0.55, 0.6, 1)
	frame:SetScript("OnMouseDown", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnMouseUp", function(self)
		self:StopMovingOrSizing()
		if self.onMove then
			self.onMove(self)
		end
	end)

	if title then
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		frame.title:SetPoint("TOP", frame, "TOP", 0, -14)
		frame.title:SetText("|cff69ccf0" .. title .. "|r")
	end

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function()
		frame:Hide()
		if frame.onHide then
			frame.onHide(frame)
		end
	end)
	frame.closeButton = close

	if closeOnEscape ~= false and name then
		UISpecialFrames[#UISpecialFrames + 1] = name
	end
	frame:Hide()
	return frame
end

function Widgets.Button(parent, text, width, height, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 80, height or 22)
	button:SetText(text or "")
	if onClick then
		button:SetScript("OnClick", onClick)
	end
	return button
end

function Widgets.EditBox(parent, width, height, maxLetters)
	local box = CreateFrame("EditBox", nil, parent)
	box:SetSize(width or 120, height or 20)
	box:SetAutoFocus(false)
	box:SetMaxLetters(maxLetters or 200)
	box:EnableMouse(true)
	box:SetBackdrop(Widgets.InputBackdrop)
	box:SetBackdropColor(0.03, 0.03, 0.05, 0.94)
	box:SetBackdropBorderColor(0.55, 0.55, 0.60, 1)
	box:SetTextInsets(8, 8, 0, 0)
	box.backdrop = box
	if ChatFontNormal then
		box:SetFontObject(ChatFontNormal)
	end
	box:SetScript("OnEditFocusGained", function(self)
		if self.HighlightText then
			self:HighlightText()
		end
	end)
	box:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	return box
end

-- Lista con scroll reutilizable y filas fijas.
-- callbacks = { onCreateRow(row), onUpdateRow(row, data, index), onClick(row, data, mouseButton), onEnter(row, data), onLeave(row, data) }
function Widgets.List(parent, scrollName, width, height, rowHeight, numRows, callbacks)
	local list = CreateFrame("Frame", nil, parent)
	list:SetSize(width, height)
	list.rowHeight = rowHeight
	list.numRows = numRows
	list.rows = {}
	list.data = {}
	list.callbacks = callbacks or {}

	local scroll = CreateFrame("ScrollFrame", scrollName, list, "FauxScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 2)
	list.scroll = scroll

	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, function()
			list:Refresh()
		end)
	end)

	function list:Scroll(delta)
		local scrollbar = _G[scrollName .. "ScrollBar"]
		if not scrollbar then
			return
		end
		scrollbar:SetValue(scrollbar:GetValue() - (delta or 0) * rowHeight)
		self:Refresh()
	end

	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(_, delta)
		list:Scroll(delta)
	end)

	for index = 1, numRows do
		local row = CreateFrame("Button", nil, list)
		row:SetHeight(rowHeight)
		row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(index - 1) * rowHeight)
		row:SetPoint("RIGHT", list, "RIGHT", -28, 0)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		local highlight = row:GetHighlightTexture()
		if highlight then
			highlight:SetBlendMode("ADD")
			highlight:SetAlpha(0.35)
		end

		row:SetScript("OnClick", function(self, mouseButton)
			if self.data and list.callbacks.onClick then
				list.callbacks.onClick(self, self.data, mouseButton)
			end
		end)
		row:SetScript("OnEnter", function(self)
			if self.data and list.callbacks.onEnter then
				list.callbacks.onEnter(self, self.data)
			end
		end)
		row:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
			if list.callbacks.onLeave then
				list.callbacks.onLeave(self, self.data)
			end
		end)

		row:EnableMouseWheel(true)
		row:SetScript("OnMouseWheel", function(_, delta)
			list:Scroll(delta)
		end)

		if list.callbacks.onCreateRow then
			list.callbacks.onCreateRow(row)
		end

		list.rows[index] = row
	end

	function list:SetData(data)
		self.data = data or {}
		self:Refresh()
	end

	function list:Refresh()
		if self.__refreshing then
			return
		end
		self.__refreshing = true

		local count = #self.data
		local maxOffset = math.max(0, count - numRows)
		FauxScrollFrame_Update(self.scroll, count, numRows, rowHeight)
		local offset = FauxScrollFrame_GetOffset(self.scroll)
		if offset > maxOffset then
			local scrollbar = _G[scrollName .. "ScrollBar"]
			if scrollbar then
				scrollbar:SetValue(maxOffset * rowHeight)
			end
			offset = maxOffset
		end

		for index = 1, numRows do
			local row = self.rows[index]
			local data = self.data[offset + index]
			row.data = data
			if data then
				row:Show()
				if list.callbacks.onUpdateRow then
					list.callbacks.onUpdateRow(row, data, offset + index)
				end
			else
				row:Hide()
			end
		end
		self.__refreshing = false
	end

	return list
end
