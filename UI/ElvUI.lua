-- DropList - optional ElvUI skin + own appearance options
-- ElvUI is never required: if it is missing (or the player picks the classic
-- theme) the window keeps its plain Blizzard look. The accent color, opacity
-- and font size work in both themes.
local DropList = _G.DropList or {}
_G.DropList = DropList

local floor = math.floor
local min = math.min
local max = math.max

local ACCENT_PRESETS = {
	azul = "69ccf0",
	cian = "00ccff",
	verde = "1eff00",
	rojo = "ff4040",
	dorado = "ffd100",
	morado = "a335ee",
	rosa = "ff69b4",
	naranja = "ff8000",
	blanco = "ffffff",
	gris = "a0a0a0",
}

-- Returns ElvUI's engine table (ElvUI[1]) only when the skin can be used.
function DropList:GetElvUI()
	if self:ThemeMode() == "classic" then
		return nil
	end
	local addon = _G.ElvUI
	local E = type(addon) == "table" and addon[1] or nil
	if type(E) ~= "table" or type(E.GetModule) ~= "function" then
		return nil
	end
	-- Media is filled at login; until then ElvUI's templates would use nils.
	if type(E.media) ~= "table" or type(E.media.bordercolor) ~= "table" then
		return nil
	end
	if type(E.media.backdropfadecolor) ~= "table" then
		return nil
	end
	if type(E.db) ~= "table" or type(E.db.general) ~= "table" then
		return nil
	end
	return E
end

function DropList:ThemeMode()
	local mode = self:Settings().theme or "auto"
	if mode ~= "auto" and mode ~= "elvui" and mode ~= "classic" then
		mode = "auto"
	end
	return mode
end

function DropList:ThemeName()
	local E = self:GetElvUI()
	if E then
		return "ElvUI"
	end
	return "clasico"
end

-- Accent color ---------------------------------------------------------------

function DropList:AccentColor()
	local accent = self:Settings().accent
	if type(accent) ~= "table" then
		accent = self.Colors.accent
	end
	return tonumber(accent.r or accent[1]) or 0.41,
		tonumber(accent.g or accent[2]) or 0.80,
		tonumber(accent.b or accent[3]) or 0.94
end

function DropList:ColorHex()
	local r, g, b = self:AccentColor()
	return string.format(
		"%02x%02x%02x",
		floor(r * 255 + 0.5),
		floor(g * 255 + 0.5),
		floor(b * 255 + 0.5)
	)
end

function DropList:ColorText(text, r, g, b)
	if not r then
		r, g, b = self:AccentColor()
	end
	return string.format(
		"|cff%02x%02x%02x%s|r",
		floor(r * 255 + 0.5),
		floor(g * 255 + 0.5),
		floor(b * 255 + 0.5),
		tostring(text)
	)
end

function DropList:ParseAccent(text)
	text = string.lower(tostring(text or ""))
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	if text == "" then
		return nil
	end
	local hex = ACCENT_PRESETS[text] or text
	hex = string.gsub(hex, "^#", "")
	if #hex ~= 6 or string.find(hex, "[^%x]") then
		return nil
	end
	return tonumber(string.sub(hex, 1, 2), 16) / 255,
		tonumber(string.sub(hex, 3, 4), 16) / 255,
		tonumber(string.sub(hex, 5, 6), 16) / 255
end

function DropList:SetAccent(r, g, b)
	r, g, b = tonumber(r), tonumber(g), tonumber(b)
	if not (r and g and b) then
		return false
	end
	r, g, b = max(0, min(1, r)), max(0, min(1, g)), max(0, min(1, b))
	self:Settings().accent = { r = r, g = g, b = b }
	self.Colors.accent = { r, g, b }
	self:ApplyAccent()
	return true
end

-- Opacity and font size ------------------------------------------------------

function DropList:FrameOpacity()
	local value = tonumber(self:Settings().opacity)
	if not value then
		value = 0.94
	end
	return max(0.10, min(1, value))
end

function DropList:BaseFontSize()
	local custom = tonumber(self:Settings().fontSize) or 0
	if custom > 0 then
		return custom
	end
	local E = self:GetElvUI()
	if E and E.db and E.db.general then
		return tonumber(E.db.general.fontSize) or 12
	end
	return nil
end

-- Works for FontStrings and EditBoxes. With no ElvUI and no custom size it
-- leaves the default font untouched.
function DropList:StyleFont(region, delta)
	if not region or not region.GetFont or not region.SetFont then
		return
	end
	local path, _, flags = region:GetFont()
	local base = self:BaseFontSize()
	if not base then
		return
	end
	local E = self:GetElvUI()
	if E and E.media and E.media.normFont then
		path = E.media.normFont
	end
	if not path then
		return
	end
	local size = base + (delta or 0)
	size = max(6, min(32, size))
	region:SetFont(path, size, flags or "")
end

function DropList:ApplyFonts()
	local f = self.main
	if not f then
		return
	end
	self:StyleFont(f.title, 3)
	self:StyleFont(f.searchLabel, -1)
	self:StyleFont(f.search, 0)
	self:StyleFont(f.countLabel, -1)
	self:StyleFont(f.itemHeader, 0)
	self:StyleFont(f.countHeader, 0)
	self:StyleFont(f.emptyText, -1)
	self:StyleFont(f.hint, -1)
	self:StyleFont(f.lastItem, -1)

	local buttonFields = { "addButton", "undoButton", "clearButton", "hideButton" }
	for _, field in ipairs(buttonFields) do
		local button = f[field]
		local fontString = button and button.GetFontString and button:GetFontString()
		if fontString then
			self:StyleFont(fontString, 0)
		end
	end

	if f.itemList then
		for _, row in ipairs(f.itemList.rows) do
			self:StyleFont(row.name, 0)
			self:StyleFont(row.count, 0)
			for _, field in ipairs({ "remove", "plus", "minus" }) do
				local button = row[field]
				local fontString = button and button.GetFontString and button:GetFontString()
				if fontString then
					self:StyleFont(fontString, 0)
				end
			end
		end
	end
end

function DropList:ApplyOpacity(value)
	if value ~= nil then
		value = tonumber(value)
		if not value then
			return false
		end
		-- Allow both 0.85 and 85.
		if value > 1 then
			value = value / 100
		end
		self:Settings().opacity = max(0.10, min(1, value))
	end
	local f = self.main
	if f then
		local r, g, b = self:FrameBackground()
		f:SetBackdropColor(r, g, b, self:FrameOpacity())
	end
	return true
end

function DropList:ApplyFontSize(value)
	value = tonumber(value)
	if not value then
		return false
	end
	value = floor(value + 0.5)
	if value < 0 then
		value = 0
	end
	if value > 24 then
		value = 24
	end
	self:Settings().fontSize = value
	self:ApplyFonts()
	return true
end

function DropList:ApplyThemeMode(mode)
	mode = string.lower(tostring(mode or ""))
	if mode ~= "auto" and mode ~= "elvui" and mode ~= "classic" then
		return false, false
	end
	local previous = self:ThemeMode()
	self:Settings().theme = mode
	return true, previous ~= mode
end

-- Theme application ----------------------------------------------------------

function DropList:FrameBackground()
	local E = self.themeActive and self:GetElvUI() or nil
	if E and E.media and type(E.media.backdropfadecolor) == "table" then
		local c = E.media.backdropfadecolor
		return c[1] or 0, c[2] or 0, c[3] or 0
	end
	return 0.03, 0.03, 0.05
end

function DropList:HookElvUIMedia(E)
	if not E or self.hookedElvUIMedia then
		return
	end
	self.hookedElvUIMedia = true
	if hooksecurefunc and E.UpdateMedia then
		hooksecurefunc(E, "UpdateMedia", function()
			-- ElvUI changed fonts/textures/colors: refresh our window too.
			if DropList.main then
				DropList:ApplyTheme()
			end
			DropList:SkinMinimapButton()
		end)
	end
end

function DropList:ApplyTheme()
	local f = self.main
	if not f then
		return
	end

	local E = self:GetElvUI()
	local skinned = false

	if E then
		self:HookElvUIMedia(E)
		skinned = pcall(self.ApplyElvUISkin, self, f, E)
	end

	self.themeActive = skinned
	if not skinned then
		pcall(self.ApplyClassicSkin, self, f)
	end

	self:ApplyAccent()
	self:ApplyFonts()
	self:ApplyOpacity()
end

function DropList:ApplyClassicSkin(f)
	if f.SetBackdrop then
		f:SetBackdrop(DropList.Widgets.Backdrop)
	end
	local r, g, b = self:AccentColor()
	f:SetBackdropColor(0.03, 0.03, 0.05, self:FrameOpacity())
	f:SetBackdropBorderColor(r, g, b, 1)
end

-- ElvUI: flat panels, media fonts, skin module buttons and scrollbar.
function DropList:ApplyElvUISkin(f, E)
	local S = E:GetModule("Skins")
	local r, g, b = self:AccentColor()

	if f.SetTemplate then
		f:SetTemplate("Transparent")
	end
	if f.CreateShadow then
		pcall(f.CreateShadow, f)
	end

	if S and S.HandleCloseButton and f.closeButton then
		pcall(S.HandleCloseButton, S, f.closeButton)
	end

	local buttonFields = { "addButton", "undoButton", "clearButton", "hideButton" }
	for _, field in ipairs(buttonFields) do
		local button = f[field]
		if button and S and S.HandleButton then
			pcall(S.HandleButton, S, button)
		end
	end

	if f.search then
		if S and S.HandleEditBox then
			pcall(S.HandleEditBox, S, f.search)
		end
		if f.search.backdrop then
			f.search.backdrop:SetBackdropColor(0, 0, 0, 0.35)
			f.search.backdrop:SetBackdropBorderColor(r, g, b, 0.8)
		end
	end

	if f.itemList and f.itemList.scroll and S and S.HandleScrollBar then
		pcall(S.HandleScrollBar, S, f.itemList.scroll)
	end

	if f.itemList then
		for _, row in ipairs(f.itemList.rows) do
			for _, field in ipairs({ "remove", "plus", "minus" }) do
				local button = row[field]
				if button and S and S.HandleButton then
					pcall(S.HandleButton, S, button)
				end
			end
			local highlight = row.GetHighlightTexture and row:GetHighlightTexture()
			if highlight then
				highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
				highlight:SetVertexColor(r, g, b, 0.10)
				highlight:SetBlendMode("ADD")
				highlight:SetAllPoints(row)
			end
			if row.selected then
				row.selected:SetVertexColor(r, g, b, 0.16)
			end
		end
	end
end

function DropList:ApplyAccent()
	local r, g, b = self:AccentColor()
	self.Colors.accent = { r, g, b }

	local f = self.main
	if not f then
		return
	end

	if f.SetBackdropBorderColor then
		f:SetBackdropBorderColor(r, g, b, 1)
	end

	if f.title then
		f.title:SetText("DropList  |cff808080" .. tostring(self.version) .. "|r")
		f.title:SetTextColor(r, g, b)
	end
	if f.itemHeader then
		f.itemHeader:SetTextColor(r, g, b)
	end
	if f.countHeader then
		f.countHeader:SetTextColor(r, g, b)
	end
	if f.countLabel then
		f.countLabel:SetTextColor(0.80, 0.80, 0.80)
	end
	if f.searchLabel then
		f.searchLabel:SetTextColor(0.90, 0.90, 0.90)
	end
	if f.hint then
		f.hint:SetTextColor(0.55, 0.55, 0.55)
	end
	if f.emptyText then
		f.emptyText:SetTextColor(0.60, 0.60, 0.60)
	end
	if f.search and f.search.backdrop then
		f.search.backdrop:SetBackdropBorderColor(r, g, b, 0.8)
	end
	if f.lastItem then
		if self.lastItemLink then
			f.lastItem:SetTextColor(r, g, b)
		else
			f.lastItem:SetTextColor(0.55, 0.55, 0.55)
		end
	end

	if f.itemList then
		for _, row in ipairs(f.itemList.rows) do
			if row.selected then
				row.selected:SetVertexColor(r, g, b, 0.16)
			end
		end
	end

	self:SkinMinimapButton()
end

-- Minimap button -------------------------------------------------------------

function DropList:SkinMinimapButton(button)
	button = button or self.minimapButton
	if not button then
		return
	end
	local r, g, b = self:AccentColor()
	local E = self:GetElvUI()

	if E and button.SetTemplate then
		if button.border then
			button.border:Hide()
		end
		button:SetTemplate("Transparent")
		button:SetBackdropColor(0, 0, 0, 0.85)
		button:SetBackdropBorderColor(r, g, b, 1)
		if button.icon then
			button.icon:SetSize(20, 20)
		end
		local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
		if highlight then
			highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
			highlight:SetVertexColor(r, g, b, 0.15)
			highlight:SetBlendMode("ADD")
			highlight:SetAllPoints(button)
		end
	else
		if button.border then
			button.border:Show()
		end
		if button.SetBackdropBorderColor then
			button:SetBackdropBorderColor(r, g, b, 1)
		end
	end
end
