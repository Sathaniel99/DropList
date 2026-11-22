-- DropList - skin único: paletas, acento, opacidad, tipografía y adornos
-- Todo se dibuja con texturas del cliente base, sin dependencias externas.
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

-- Color y fondo ----------------------------------------------------------------

function DropList:FrameBackground()
	local background = self:Settings() and self:Settings().background
	if type(background) == "table" then
		return tonumber(background.r) or 0.03,
			tonumber(background.g) or 0.03,
			tonumber(background.b) or 0.05
	end
	return 0.03, 0.03, 0.05
end

function DropList:AccentColor()
	local accent = self:Settings().accent
	if type(accent) ~= "table" then
		accent = self.Colors.accent
	end
	return tonumber(accent.r or accent[1]) or 1.0,
		tonumber(accent.g or accent[2]) or 0.82,
		tonumber(accent.b or accent[3]) or 0.0
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
	self:Settings().palette = "personalizado"
	self.Colors.accent = { r, g, b }
	self:ApplyAccent()
	return true
end

-- Aplica una paleta completa (fondo + acento). La paleta personalizada conserva
-- lo que el jugador haya ajustado a mano.
function DropList:ApplyPalette(name)
	name = string.lower(tostring(name or ""))
	if not self:IsValidPalette(name) then
		return false
	end
	local palette = DropList.PALETTES[name]
	local settings = self:Settings()
	settings.palette = name
	settings.background = DropList.Copy(palette.bg)
	settings.accent = DropList.Copy(palette.accent)
	self.Colors.accent = DropList.Copy(palette.accent)
	self:ApplySkin()
	return true
end

-- Opacidad y tamaño de fuente -------------------------------------------------

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
	return nil
end

function DropList:StyleFont(region, delta)
	if not region or not region.GetFont or not region.SetFont then
		return
	end
	local path, current, flags = region:GetFont()
	if not region.dropListBaseSize then
		region.dropListBaseSize = current or 12
	end
	if not path then
		return
	end
	local base = self:BaseFontSize()
	local size = base and (base + (delta or 0)) or region.dropListBaseSize
	size = max(6, min(32, size))
	region:SetFont(path, size, flags or "")
end

function DropList:ApplyFonts()
	local f = self.main
	if not f then
		return
	end
	self:StyleFont(f.title, 3)
	self:StyleFont(f.search, 0)
	self:StyleFont(f.countLabel, -1)
	self:StyleFont(f.itemHeader, 0)
	self:StyleFont(f.countHeader, 0)
	self:StyleFont(f.emptyText, -1)
	self:StyleFont(f.hint, -1)
	self:StyleFont(f.lastItem, -1)

	local buttonFields = { "addButton", "undoButton", "clearButton", "hideButton", "emptyButton" }
	for _, field in ipairs(buttonFields) do
		self:StyleFont(f[field] and f[field]:GetFontString())
	end
	if f.filterButtons then
		for _, button in pairs(f.filterButtons) do
			self:StyleFont(button and button:GetFontString())
		end
	end

	if f.itemList then
		for _, row in ipairs(f.itemList.rows) do
			self:StyleFont(row.name, 0)
			self:StyleFont(row.count, 0)
			for _, field in ipairs({ "remove", "plus", "minus" }) do
				local button = row[field]
				if button and button.GetFontString then
					self:StyleFont(button:GetFontString())
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
		if value > 1 then
			value = value / 100
		end
		self:Settings().opacity = max(0.10, min(1, value))
	end
	local f = self.main
	if f then
		local r, g, b = self:FrameBackground()
		f:SetBackdropColor(r, g, b, self:FrameOpacity())
		if f.search and f.search.SetBackdropColor then
			f.search:SetBackdropColor(r, g, b, self:FrameOpacity())
		end
		if f.statsChip then
			f.statsChip:SetBackdropColor(r + 0.04, g + 0.04, b + 0.04, 0.85)
		end
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

-- Aplicación del skin ---------------------------------------------------------

function DropList:ApplySkin()
	local f = self.main
	if not f then
		return
	end
	if f.SetBackdrop then
		f:SetBackdrop(DropList.Widgets.Backdrop)
	end
	local r, g, b = self:FrameBackground()
	f:SetBackdropColor(r, g, b, self:FrameOpacity())
	if f.search and f.search.SetBackdropColor then
		f.search:SetBackdropColor(r, g, b, self:FrameOpacity())
	end

	self:ApplyAccent()
	self:ApplyFonts()
	self:ApplyOpacity()
end

function DropList:SkinScrollBar(list)
	if not list or not list.scroll then
		return
	end
	local name = list.scroll:GetName()
	if not name then
		return
	end
	local r, g, b = self:AccentColor()
	local thumb = _G[name .. "ThumbTexture"]
	if thumb and thumb.SetVertexColor then
		thumb:SetVertexColor(r, g, b, 0.7)
	end
	for _, suffix in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
		local button = _G[name .. suffix]
		local texture = button and button.GetNormalTexture and button:GetNormalTexture()
		if texture and texture.SetVertexColor then
			texture:SetVertexColor(r, g, b, 0.85)
		end
	end
end

function DropList:ApplyAccent()
	local r, g, b = self:AccentColor()
	local bgR, bgG, bgB = self:FrameBackground()
	self.Colors.accent = { r, g, b }

	local f = self.main
	if not f then
		return
	end

	if f.SetBackdropBorderColor then
		f:SetBackdropBorderColor(r, g, b, 1)
	end

	-- Cabecera con degradado y línea divisoria.
	if f.titleBar and f.titleBar.SetGradient then
		f.titleBar:SetGradient("HORIZONTAL",
			bgR * 0.7, bgG * 0.7, bgB * 0.7,
			bgR + 0.10, bgG + 0.10, bgB + 0.12)
	end
	if f.titleDivider then
		f.titleDivider:SetVertexColor(r, g, b, 0.5)
	end
	if f.title then
		f.title:SetText("DropList  |cff808080" .. tostring(self.version) .. "|r")
		f.title:SetTextColor(r, g, b)
	end
	if f.searchIcon then
		f.searchIcon:SetVertexColor(r, g, b, 0.9)
	end
	if f.search and f.search.backdrop then
		f.search.backdrop:SetBackdropBorderColor(r, g, b, 0.8)
	end
	if f.statsChip then
		f.statsChip:SetBackdropBorderColor(r, g, b, 0.45)
	end
	if f.countLabel then
		f.countLabel:SetTextColor(0.85, 0.85, 0.85)
	end
	if f.itemHeader then
		f.itemHeader:SetTextColor(r, g, b)
	end
	if f.countHeader then
		f.countHeader:SetTextColor(r, g, b)
	end
	if f.nameDivider then
		f.nameDivider.line:SetVertexColor(r, g, b, 0.55)
	end
	if f.countDivider then
		f.countDivider.line:SetVertexColor(r, g, b, 0.30)
	end
	if f.hint then
		f.hint:SetTextColor(0.55, 0.55, 0.55)
	end
	if f.emptyText then
		f.emptyText:SetTextColor(0.65, 0.65, 0.65)
	end
	if f.emptyIcon then
		f.emptyIcon:SetVertexColor(r, g, b, 0.22)
	end
	if f.lastItem then
		if self.lastItemLink then
			f.lastItem:SetTextColor(r, g, b)
		else
			f.lastItem:SetTextColor(0.55, 0.55, 0.55)
		end
	end
	if f.resizeGrip then
		f.resizeGrip.line:SetVertexColor(r, g, b, 0.55)
	end

	local Widgets = DropList.Widgets
	if Widgets then
		for _, button in pairs({ f.addButton, f.undoButton, f.clearButton, f.hideButton, f.emptyButton }) do
			Widgets.StyleButton(button, r, g, b)
		end
		if f.filterButtons then
			for _, button in pairs(f.filterButtons) do
				Widgets.StyleButton(button, r, g, b)
			end
		end
		if f.itemList then
			for _, row in ipairs(f.itemList.rows) do
				for _, field in ipairs({ "remove", "plus", "minus" }) do
					Widgets.StyleButton(row[field], r, g, b)
				end
				local highlight = row:GetHighlightTexture()
				if highlight and highlight.SetVertexColor then
					highlight:SetVertexColor(r, g, b, 0.18)
				end
				if row.iconBorder then
					row.iconBorder:SetBackdropBorderColor(r, g, b, 0.65)
				end
			end
			self:SkinScrollBar(f.itemList)
		end
	end

	self:SkinMinimapButton()
end

-- Botón del minimapa -----------------------------------------------------------

function DropList:SkinMinimapButton(button)
	button = button or self.minimapButton
	if not button then
		return
	end
	local r, g, b = self:AccentColor()
	if button.border then
		button.border:Show()
		button.border:SetVertexColor(r, g, b, 1)
	end
	if button.glow then
		button.glow:SetVertexColor(r, g, b, 0.35)
	end
end
