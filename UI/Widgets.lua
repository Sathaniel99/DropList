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

-- Fondo más fino para la caja de búsqueda y los chips.
Widgets.InputBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Fondo de los botones propios, sin plantillas de Blizzard.
Widgets.ButtonBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = false,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function frameBackground()
	if DropList.FrameBackground then
		return DropList:FrameBackground()
	end
	return 0.03, 0.03, 0.05
end

-- Aplica el color de acento y el estado (normal, activo, desactivado) a un botón.
function Widgets.StyleButton(button, r, g, b)
	if not button then
		return
	end
	if not r then
		r, g, b = DropList:AccentColor()
	end
	local bgR, bgG, bgB = frameBackground()
	button:SetBackdropColor(bgR + 0.05, bgG + 0.05, bgB + 0.05, 0.9)
	local alpha = 0.55
	if button.active then
		alpha = 1
	elseif button.hover then
		alpha = 0.9
	end
	if button.IsEnabled and not button:IsEnabled() then
		alpha = 0.25
	end
	button:SetBackdropBorderColor(r, g, b, alpha)
	if button.label then
		if button.IsEnabled and not button:IsEnabled() then
			button.label:SetTextColor(0.5, 0.5, 0.5)
		elseif button.active then
			button.label:SetTextColor(r, g, b)
		else
			button.label:SetTextColor(0.9, 0.9, 0.9)
		end
	end
end

function Widgets.SetButtonActive(button, active)
	if not button then
		return
	end
	button.active = active and true or false
	Widgets.StyleButton(button)
end

function Widgets.Panel(name, width, height, title, closeOnEscape)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetSize(width, height)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
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
		if self.onResize then
			self.onResize(self)
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

-- Botón plano con estados propios. Mantiene GetFontString/SetText para el skin.
function Widgets.Button(parent, text, width, height, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width or 80, height or 22)
	button:SetBackdrop(Widgets.ButtonBackdrop)

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("CENTER")
	label:SetText(text or "")
	button.label = label

	function button:GetFontString()
		return label
	end
	function button:SetText(value)
		label:SetText(value or "")
	end

	-- Se usan hooks para que quien quiera añadir tooltips pueda usar SetScript.
	-- pcall protege clientes que no aceptan algún handler concreto.
	local function hook(script, fn)
		pcall(button.HookScript, button, script, fn)
	end
	hook("OnEnter", function(self)
		self.hover = true
		Widgets.StyleButton(self)
	end)
	hook("OnLeave", function(self)
		self.hover = false
		Widgets.StyleButton(self)
	end)
	hook("OnMouseDown", function(self)
		self.pressed = true
		Widgets.StyleButton(self)
	end)
	hook("OnMouseUp", function(self)
		self.pressed = false
		Widgets.StyleButton(self)
	end)
	hook("OnEnable", function(self)
		Widgets.StyleButton(self)
	end)
	hook("OnDisable", function(self)
		Widgets.StyleButton(self)
	end)

	if onClick then
		button:SetScript("OnClick", onClick)
	end
	Widgets.StyleButton(button)
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
	box:SetTextInsets(24, 8, 0, 0)
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
-- callbacks = { onCreateRow(row, index), onUpdateRow(row, data, index),
--               onClick(row, data, mouseButton), onEnter(row, data), onLeave(row, data) }
local MAX_ROWS = 24

function Widgets.List(parent, scrollName, width, height, rowHeight, numRows, callbacks)
	local list = CreateFrame("Frame", nil, parent)
	list:SetSize(width, height)
	list.rowHeight = rowHeight
	list.numRows = numRows
	list.maxRows = MAX_ROWS
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

	for index = 1, MAX_ROWS do
		local row = CreateFrame("Button", nil, list)
		row:SetHeight(rowHeight)
		row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(index - 1) * rowHeight)
		row:SetPoint("RIGHT", list, "RIGHT", -28, 0)
		row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8", "ADD")
		local highlight = row:GetHighlightTexture()
		if highlight then
			highlight:SetVertexColor(0.41, 0.80, 0.94, 0.18)
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
			list.callbacks.onCreateRow(row, index)
		end
		row:Hide()
		list.rows[index] = row
	end

	function list:SetVisibleRows(count)
		self.numRows = math.max(3, math.min(MAX_ROWS, math.floor(tonumber(count) or 3)))
		self:Refresh()
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
		local maxOffset = math.max(0, count - self.numRows)
		FauxScrollFrame_Update(self.scroll, count, self.numRows, rowHeight)
		local offset = FauxScrollFrame_GetOffset(self.scroll)
		if offset > maxOffset then
			local scrollbar = _G[scrollName .. "ScrollBar"]
			if scrollbar then
				scrollbar:SetValue(maxOffset * rowHeight)
			end
			offset = maxOffset
		end

		for index = 1, MAX_ROWS do
			local row = self.rows[index]
			if index > self.numRows then
				row:Hide()
				row.data = nil
			else
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
		end
		self.__refreshing = false
	end

	return list
end
