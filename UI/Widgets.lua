-- DropList - small UI toolkit (3.3.5 compatible, no libraries)
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

function Widgets.Checkbox(parent, label, checked, onClick)
	local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	box:SetSize(24, 24)
	box:SetChecked(checked and true or false)
	box:SetScript("OnClick", function(self)
		if onClick then
			onClick(self, self:GetChecked() and true or false)
		end
	end)
	if label then
		local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("LEFT", box, "RIGHT", 2, 0)
		text:SetText(label)
	end
	return box
end

function Widgets.EditBox(parent, width, height, maxLetters)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width or 120, height or 20)
	box:SetAutoFocus(false)
	box:SetMaxLetters(maxLetters or 200)
	box:EnableMouse(true)
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

function Widgets.Dropdown(parent, name, width)
	local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
	if width then
		UIDropDownMenu_SetWidth(dropdown, width)
	end
	return dropdown
end

function Widgets.SetDropdown(dropdown, text)
	UIDropDownMenu_SetText(dropdown, text or "")
end

function Widgets.Menu(dropdown, items, anchorName)
	EasyMenu(items, dropdown, anchorName or dropdown:GetName(), 0, 0, "MENU")
end

function Widgets.Separator(parent, inset)
	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetTexture("Interface\\Buttons\\WHITE8X8")
	line:SetVertexColor(1, 1, 1, 0.12)
	line:SetHeight(1)
	line:SetPoint("LEFT", parent, "LEFT", inset or 8, 0)
	line:SetPoint("RIGHT", parent, "RIGHT", -(inset or 8), 0)
	return line
end

function Widgets.Tooltip(owner, anchor)
	GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
	return GameTooltip
end

-- Simple reusable scrollable list with fixed row frames.
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

		local selected = row:CreateTexture(nil, "BACKGROUND")
		selected:SetTexture("Interface\\Buttons\\WHITE8X8")
		selected:SetVertexColor(0.4, 0.7, 1, 0.16)
		selected:SetAllPoints(row)
		selected:Hide()
		row.selected = selected

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
