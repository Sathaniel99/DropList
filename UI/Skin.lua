-- DropList - skin único (clásico de Blizzard) + opciones de aspecto propias
-- Fondo oscuro, borde del color de acento, opacidad y tamaño de fuente.
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

-- Color de acento -------------------------------------------------------------

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
	self.Colors.accent = { r, g, b }
	self:ApplyAccent()
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
		if value > 1 then
			value = value / 100
		end
		self:Settings().opacity = max(0.10, min(1, value))
	end
	local f = self.main
	if f then
		f:SetBackdropColor(0.03, 0.03, 0.05, self:FrameOpacity())
		if f.search and f.search.SetBackdropColor then
			f.search:SetBackdropColor(0.03, 0.03, 0.05, self:FrameOpacity())
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
	local r, g, b = self:AccentColor()
	f:SetBackdropColor(0.03, 0.03, 0.05, self:FrameOpacity())
	f:SetBackdropBorderColor(r, g, b, 1)
	if f.search and f.search.SetBackdropColor then
		f.search:SetBackdropColor(0.03, 0.03, 0.05, self:FrameOpacity())
	end

	self:ApplyAccent()
	self:ApplyFonts()
	self:ApplyOpacity()
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
end
