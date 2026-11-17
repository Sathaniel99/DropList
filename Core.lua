-- DropList - núcleo: utilidades de objetos, hooks de tooltip/cursor y comandos
local DropList = _G.DropList or {}
_G.DropList = DropList

local L = DropList.L
local M = DropList.Model

local QUALITY_HEX = {
	["ff9d9d9d"] = 0,
	["ffffffff"] = 1,
	["ff1eff00"] = 2,
	["ff0070dd"] = 3,
	["ffa335ee"] = 4,
	["ffff8000"] = 5,
	["ffe6cc80"] = 6,
	["ff00ccff"] = 7,
}

local function isPlaceholderName(name)
	return not name or name == "" or string.find(name, "^item:%d+$") ~= nil
end

local function isPlaceholderIcon(icon)
	return not icon or icon == "" or icon == "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function isBareLink(link)
	return not link or string.find(link, "^item:%d+$") ~= nil
end

function DropList:QualityFromLink(link)
	local hex = string.match(link or "", "|c(%x%x%x%x%x%x%x%x)")
	return QUALITY_HEX[string.lower(hex or "")] or 1
end

-- Acepta un enlace de objeto, un "item:ID" suelto o un ID numérico.
function DropList:ResolveItem(input)
	if input == nil then
		return nil
	end
	if type(input) == "table" then
		input = input.link or input.itemID
	end

	local itemID = tonumber(input)
	local link
	if type(input) == "string" then
		link = string.match(input, "|c%x%x%x%x%x%x%x%x|Hitem:%d+[^|]*|h%[.-%]|h|r")
			or string.match(input, "|Hitem:%d+[^|]*|h%[.-%]|h")
		itemID = itemID or tonumber(string.match(input, "item:(%d+)"))
	end
	if not itemID then
		return nil
	end

	local name, gameLink, quality, _, _, class, subclass, maxStack, equipLoc, texture = GetItemInfo(itemID)
	local data = {
		itemID = itemID,
		name = name,
		link = link or gameLink,
		quality = quality,
		icon = texture,
		class = class,
		subclass = subclass,
		maxStack = maxStack,
		equipLoc = equipLoc,
	}
	-- Solo se clasifica cuando el cliente ya conoce el objeto: uno sin caché
	-- devuelve un nombre nil y ningún dato de tipo.
	if name then
		data.itemType = self:ClassifyItem(equipLoc, maxStack)
	end

	if not data.name and link then
		data.name = string.match(link, "|h%[(.-)%]|h")
		data.quality = self:QualityFromLink(link)
	end
	if not data.icon and GetItemIcon then
		data.icon = GetItemIcon(itemID)
	end
	if not data.name then
		data.name = "item:" .. tostring(itemID)
	end
	if not data.icon then
		data.icon = "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	if not data.link then
		data.link = "item:" .. tostring(itemID)
	end
	if not data.quality then
		data.quality = 1
	end
	return data
end

-- Tipo de objeto: un botón para equipo, tres (X, +, -) para objetos contables ---
-- GetItemInfo en 3.3.5 devuelve:
-- name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipLoc, texture
-- El equipo tiene un slot real y no apila. Todo lo demás (marcas de
-- santificación, saronita, tokens de tier, materiales, munición...) es contable.

local NON_EQUIP_LOCS = {
	[""] = true,
	["INVTYPE_NON_EQUIP"] = true,
	["INVTYPE_NON_EQUIP_IGNORE"] = true,
}

-- Función pura: equipLoc y maxStack tal y como los devuelve GetItemInfo para un objeto conocido.
function DropList:ClassifyItem(equipLoc, maxStack)
	if type(equipLoc) ~= "string" or NON_EQUIP_LOCS[equipLoc] then
		return "stack"
	end
	-- Munición, armas arrojadizas y todo lo que apila se cuenta, no es equipo.
	if (tonumber(maxStack) or 1) > 1 then
		return "stack"
	end
	return "equip"
end

-- Lee el tipo de la caché del cliente y lo guarda en la entrada, porque
-- 3.3.5 solo conoce los objetos que ya están en la caché del cliente.
function DropList:DetectItemType(entry)
	if not entry or not entry.itemID then
		return nil
	end
	local name, _, _, _, _, _, _, maxStack, equipLoc = GetItemInfo(entry.itemID)
	if not name then
		return nil
	end
	local itemType = self:ClassifyItem(equipLoc, maxStack)
	entry.itemType = itemType
	entry.equipLoc = equipLoc
	entry.maxStack = maxStack
	return itemType
end

-- Mientras el cliente no conozca el objeto se muestra un solo botón.
function DropList:IsEquipableEntry(entry)
	if not entry then
		return true
	end
	if entry.itemType == "equip" then
		return true
	end
	if entry.itemType == "stack" then
		return false
	end
	local itemType = self:DetectItemType(entry)
	if itemType then
		return itemType == "equip"
	end
	return true
end

-- Completa nombres, iconos, calidad y el tipo de los objetos que no estaban en
-- caché al añadirlos. Cuando el cliente ya conoce el objeto, sus datos mandan.
function DropList:EnrichEntries()
	local changed = false
	for _, entry in pairs(M:Entries()) do
		local pending = isPlaceholderName(entry.name) or isPlaceholderIcon(entry.icon)
			or isBareLink(entry.link) or not entry.itemType
		if pending then
			local name, link, quality, _, _, _, _, maxStack, equipLoc, texture = GetItemInfo(entry.itemID)
			if name then
				entry.name = name
				if quality then
					entry.quality = quality
				end
				if texture then
					entry.icon = texture
				end
				if link and isBareLink(entry.link) then
					entry.link = link
				end
				if not entry.itemType then
					entry.itemType = self:ClassifyItem(equipLoc, maxStack)
					entry.equipLoc = equipLoc
					entry.maxStack = maxStack
				end
				changed = true
			end
		end
	end
	return changed
end

-- Captura de tooltips -----------------------------------------------------------
-- Misma idea que LootPlan: leer el tooltip que hay en pantalla ahora mismo y
-- guardar además el último objeto visto. Lo segundo importa para el botón
-- "Añadir", porque al mover el ratón al botón desaparece el tooltip del objeto.

-- Primero GameTooltip, luego los tooltips de AtlasLoot y de los enlaces pulsados.
function DropList:TooltipList()
	local list = {}
	if GameTooltip then
		table.insert(list, GameTooltip)
	end
	if AtlasLootTooltip then
		table.insert(list, AtlasLootTooltip)
	end
	if ItemRefTooltip then
		table.insert(list, ItemRefTooltip)
	end
	return list
end

-- requireShown = false al capturar: durante OnTooltipSetItem el tooltip ya
-- tiene los datos pero puede que aún no sea visible.
function DropList:LinkFromTooltip(tooltip, requireShown)
	if not tooltip or not tooltip.GetItem then
		return nil
	end
	if requireShown ~= false and tooltip.IsShown and not tooltip:IsShown() then
		return nil
	end
	local _, link = tooltip:GetItem()
	if type(link) == "string" and string.find(link, "item:", 1, true) then
		return link
	end
	return nil
end

function DropList:RememberItemLink(link)
	if type(link) ~= "string" or not string.find(link, "item:", 1, true) then
		return
	end
	self.lastItemLink = link
	self:UpdateLastItemLabel()
end

-- Muestra qué objeto va a usar el botón.
function DropList:UpdateLastItemLabel()
	local frame = self.main
	if not frame or not frame.lastItem then
		return
	end
	if self.lastItemLink then
		local item = self:ResolveItem(self.lastItemLink)
		frame.lastItem:SetText(string.format(L.LastCaptured, item and item.name or tostring(self.lastItemLink)))
		frame.lastItem:SetTextColor(self:AccentColor())
	else
		frame.lastItem:SetText(L.LastCapturedNone)
		frame.lastItem:SetTextColor(0.55, 0.55, 0.55)
	end
end

function DropList:CaptureTooltip(tooltip)
	local link = self:LinkFromTooltip(tooltip, false)
	if link then
		self:RememberItemLink(link)
	end
	return link
end

-- OnTooltipSetItem se dispara con cualquier forma de mostrar un objeto (bolsa,
-- botín, subasta, recompensa de misión, enlace...), así que es el hook fiable.
-- SetHyperlink queda como respaldo para tooltips que no llamen al callback.
function DropList:HookTooltips()
	self.hookedTooltips = self.hookedTooltips or {}
	for _, tooltip in ipairs(self:TooltipList()) do
		if not self.hookedTooltips[tooltip] then
			self.hookedTooltips[tooltip] = true
			pcall(function()
				tooltip:HookScript("OnTooltipSetItem", function(frame)
					DropList:CaptureTooltip(frame)
				end)
			end)
			if hooksecurefunc and tooltip.SetHyperlink then
				pcall(hooksecurefunc, tooltip, "SetHyperlink", function(_, link)
					DropList:RememberItemLink(link)
				end)
			end
		end
	end
end

function DropList:ItemFromGameTooltip()
	local link = self:LinkFromTooltip(GameTooltip)
	return link and self:ResolveItem(link) or nil
end

-- El objeto ya salió del tooltip: se usa el capturado por el hook.
function DropList:ItemFromCaptured()
	if self.lastItemLink then
		return self:ResolveItem(self.lastItemLink)
	end
	return nil
end

-- Tooltips de AtlasLoot / ItemRef, solo como último recurso.
function DropList:ItemFromOtherTooltips()
	for _, tooltip in ipairs(self:TooltipList()) do
		if tooltip ~= GameTooltip then
			local link = self:LinkFromTooltip(tooltip)
			if link then
				local item = self:ResolveItem(link)
				if item then
					return item
				end
			end
		end
	end
	return nil
end

-- Lectura estilo LootPlan: primero GameTooltip y luego el último objeto mostrado.
function DropList:ItemFromTooltip()
	return self:ItemFromGameTooltip()
		or self:ItemFromCaptured()
		or self:ItemFromOtherTooltips()
end

function DropList:ItemFromCursor()
	if not (CursorHasItem and CursorHasItem()) then
		return nil
	end
	local cursorType, itemID, itemLink = GetCursorInfo()
	if cursorType ~= "item" then
		return nil
	end
	if itemLink then
		local item = self:ResolveItem(itemLink)
		if item then
			return item
		end
	end
	return itemID and self:ResolveItem(itemID) or nil
end

-- Enlace en la caja de chat (shift-clic ahí y luego pulsar Añadir).
function DropList:ItemFromChat()
	local edit = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
	if not edit or not edit.GetText then
		return nil
	end
	-- Un chat cerrado puede conservar el último mensaje: solo se usa si está visible.
	if edit.IsShown and not edit:IsShown() then
		return nil
	end
	local text = edit:GetText()
	if not text or text == "" then
		return nil
	end
	return self:ResolveItem(text)
end

-- Devuelve true si el jugador está escribiendo en el chat ahora mismo.
function DropList:ChatIsTyping()
	local edit = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
	if not edit then
		return false
	end
	local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
	if focus then
		return focus == edit
	end
	if edit.IsShown and edit:IsShown() and edit.HasFocus then
		return edit:HasFocus() and true or false
	end
	return false
end

-- Devuelve true si cualquier caja de texto tiene el teclado, del chat u otro addon.
function DropList:IsTypingInEditBox()
	local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
	return focus ~= nil and focus.GetText ~= nil
end

-- Añadir -----------------------------------------------------------------------

function DropList:AddItem(item, qty)
	if not item or not item.itemID then
		self:Print(L.InvalidItemShort, 1, 0.3, 0.3)
		return nil
	end
	qty = math.floor(tonumber(qty) or 1)
	if qty < 1 then qty = 1 end
	local maxQty = M.MAX_VALUE or 99999
	if qty > maxQty then
		qty = maxQty
		self:Print(string.format(L.QuantityClamped, maxQty), 1, 0.82, 0)
	end

	local entry = M:Add({
		itemID = item.itemID,
		name = item.name,
		quality = item.quality,
		icon = item.icon,
		link = item.link,
		qty = qty,
		itemType = item.itemType,
		equipLoc = item.equipLoc,
		maxStack = item.maxStack,
	})
	if not entry then
		self:Print(L.InvalidItemShort, 1, 0.3, 0.3)
		return nil
	end

	self:Refresh()
	self:Print(string.format(L.AddedDetail, M:DisplayName(entry), qty, entry.count or qty), 0.4, 1, 0.4)
	return entry
end

function DropList:ReportNoItem()
	self:Print(L.AddHint, 1, 0.82, 0)
	if UIErrorsFrame then
		UIErrorsFrame:AddMessage("DropList: " .. L.AddHintShort, 1, 0.82, 0, 1)
	end
end

-- Arrastrar y soltar en la ventana/botón: usa solo el cursor.
function DropList:AddFromCursor()
	local item = self:ItemFromCursor()
	if not item then
		self:ReportNoItem()
		return nil
	end
	if ClearCursor then
		ClearCursor()
	end
	return self:AddItem(item)
end

-- Botón "Añadir": primero el cursor, luego el enlace del chat si el jugador
-- está escribiendo en él, y por último el tooltip (actual o el último capturado).
function DropList:AddFromUI()
	-- AtlasLoot o cualquier addon cargado tarde puede crear su tooltip después.
	self:HookTooltips()

	local item = self:ItemFromCursor()
	if item then
		if ClearCursor then
			ClearCursor()
		end
		return self:AddItem(item)
	end

	local chatItem = self:ItemFromChat()
	if chatItem and self:ChatIsTyping() then
		return self:AddItem(chatItem)
	end

	item = self:ItemFromTooltip() or chatItem
	if not item then
		self:ReportNoItem()
		return nil
	end
	self:RememberItemLink(item.link)
	return self:AddItem(item)
end

function DropList:AddFromCommand(rest)
	rest = tostring(rest or "")
	local link = string.match(rest, "|c%x%x%x%x%x%x%x%x|Hitem:%d+[^|]*|h%[.-%]|h|r")
		or string.match(rest, "|Hitem:%d+[^|]*|h%[.-%]|h")
		or string.match(rest, "item:%d+")
	local idToken = string.match(rest, "^%s*(%d+)%s*")
	local item = self:ResolveItem(link or idToken)
	if not item then
		self:Open()
		self:ReportNoItem()
		return
	end

	-- Se quita la referencia al objeto para leer la cantidad opcional.
	local tail = rest
	tail = string.gsub(tail, "|c%x%x%x%x%x%x%x%x|Hitem:%d+[^|]*|h%[.-%]|h|r", " ")
	tail = string.gsub(tail, "|Hitem:%d+[^|]*|h%[.-%]|h", " ")
	tail = string.gsub(tail, "item:%d+", " ")
	tail = string.gsub(tail, "%f[%d]" .. tostring(item.itemID) .. "%f[%D]", " ")
	local qty = tonumber(string.match(tail, "%d+")) or 1

	self:AddItem(item, qty)
end

-- Utilidades de ventana ---------------------------------------------------------

function DropList:SavePosition(frame, key)
	if not frame.GetPoint then
		return
	end
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	if not point then
		return
	end
	self:Settings()[key] = {
		point = point,
		relativePoint = relativePoint or point,
		x = x or 0,
		y = y or 0,
	}
end

function DropList:RestorePosition(frame, key)
	local position = self:Settings()[key]
	if type(position) == "table" and position.point then
		frame:ClearAllPoints()
		frame:SetPoint(position.point, UIParent, position.relativePoint or position.point, position.x or 0, position.y or 0)
	end
end

function DropList:ApplyScale(scale)
	scale = tonumber(scale) or 1
	if scale < 0.7 then scale = 0.7 end
	if scale > 1.5 then scale = 1.5 end
	self:Settings().scale = scale
	if self.main then
		self.main:SetScale(scale)
	end
end

function DropList:Open()
	self:HookTooltips()
	local frame = self:CreateMainFrame()
	self:InitMainFrameValues()
	self:Refresh()
	frame:Show()
	return frame
end

function DropList:Toggle()
	local frame = self:CreateMainFrame()
	self:InitMainFrameValues()
	if frame:IsShown() then
		frame:Hide()
	else
		self:Refresh()
		frame:Show()
	end
end

function DropList:ConfirmClear()
	StaticPopup_Show("DROPLIST_CLEAR", L.ConfirmClear)
end

StaticPopupDialogs["DROPLIST_CLEAR"] = {
	text = "%s",
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		DropList.Model:ClearAll()
		DropList:Refresh()
		DropList:Print(DropList.L.Cleared, 0.8, 0.8, 0.8)
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

-- Comandos ---------------------------------------------------------------------

function DropList:PrintHelp()
	self:Print(L.HelpHeader)
	self:Print(L.HelpShow, 0.8, 0.8, 0.8)
	self:Print(L.HelpAdd, 0.8, 0.8, 0.8)
	self:Print(L.HelpUndo, 0.8, 0.8, 0.8)
	self:Print(L.HelpReset, 0.8, 0.8, 0.8)
	self:Print(L.HelpScale, 0.8, 0.8, 0.8)
	self:Print(L.HelpMinimap, 0.8, 0.8, 0.8)
	self:Print(L.HelpColor, 0.8, 0.8, 0.8)
	self:Print(L.HelpOpacity, 0.8, 0.8, 0.8)
	self:Print(L.HelpFontSize, 0.8, 0.8, 0.8)
	self:Print(L.HelpTooltip, 0.8, 0.8, 0.8)
	self:Print(L.HelpTest, 0.8, 0.8, 0.8)
	self:Print(L.HelpDebug, 0.8, 0.8, 0.8)
end

function DropList:PrintDebug()
	local function describe(frame)
		if not frame then
			return "nil"
		end
		local name = frame.GetName and frame:GetName()
		local shown = frame.IsShown and frame:IsShown()
		return tostring(name or "sin nombre") .. " visible=" .. tostring(shown and true or false)
	end

	local chatItem = self:ItemFromChat()
	self:Print("DropList " .. tostring(self.version))
	self:Print(string.format(L.DebugFrame, describe(self.main)))
	self:Print(string.format(L.DebugTooltip, tostring(self.lastItemLink or "ninguno")))
	self:Print(string.format(L.DebugChat, tostring(chatItem and chatItem.name or "ninguno")))

	for _, tooltip in ipairs(self:TooltipList()) do
		self:Print(string.format(
			L.DebugTooltipSource,
			tostring(tooltip.GetName and tooltip:GetName() or "tooltip"),
			describe(tooltip),
			tostring(self:LinkFromTooltip(tooltip) or "ninguno")
		))
	end
	self:Print(string.format(L.DebugHooks, tostring(self.hookedTooltips ~= nil)))
	self:Print(L.DebugEntries .. tostring(#M:EntryList({})))
end

function DropList:CommandColor(rest)
	local r, g, b = self:ParseAccent(rest)
	if r then
		self:SetAccent(r, g, b)
		self:Print(string.format(L.ColorSet, self:ColorHex()), 0.8, 0.8, 0.8)
		return
	end
	self:Print(string.format(L.ColorHelp, self:ColorHex()), 0.8, 0.8, 0.8)
	self:Print(L.ColorPresets, 0.8, 0.8, 0.8)
end

function DropList:CommandOpacity(rest)
	rest = DropList.Trim(rest)
	if rest == "" then
		self:Print(string.format(L.OpacitySet, string.format("%.2f", self:FrameOpacity())), 0.8, 0.8, 0.8)
		return
	end
	if self:ApplyOpacity(rest) then
		self:Print(string.format(L.OpacitySet, string.format("%.2f", self:FrameOpacity())), 0.8, 0.8, 0.8)
	else
		self:Print(L.OpacityInvalid)
	end
end

function DropList:CommandFontSize(rest)
	rest = DropList.Trim(rest)
	local current = tonumber(self:Settings().fontSize) or 0
	if rest == "" then
		local shown = current > 0 and tostring(current) or L.FontSizeAuto
		self:Print(string.format(L.FontSizeSet, shown), 0.8, 0.8, 0.8)
		return
	end
	if self:ApplyFontSize(rest) then
		local value = tonumber(self:Settings().fontSize) or 0
		local shown = value > 0 and tostring(value) or L.FontSizeAuto
		self:Print(string.format(L.FontSizeSet, shown), 0.8, 0.8, 0.8)
	else
		self:Print(L.FontSizeInvalid)
	end
end

function DropList:CommandTooltip()
	local settings = self:Settings()
	settings.tooltipButton = not settings.tooltipButton
	self:Print(settings.tooltipButton and L.TooltipOn or L.TooltipOff, 0.8, 0.8, 0.8)
end

local function dispatchCommand(command, rest)
	if command == "" then
		DropList:Toggle()
	elseif command == "add" then
		DropList:AddFromCommand(rest)
	elseif command == "undo" then
		if M:Undo() then
			DropList:Refresh()
			DropList:Print(L.Undone, 0.4, 1, 0.4)
		else
			DropList:Print(L.NothingUndo)
		end
	elseif command == "reset" then
		DropList:ConfirmClear()
	elseif command == "scale" then
		DropList:ApplyScale(tonumber(rest) or 1)
		DropList:Print(string.format(L.ScaleSet, tostring(DropList:Settings().scale)), 0.8, 0.8, 0.8)
	elseif command == "minimap" then
		DropList:SetMinimapVisible(not DropList:Settings().minimap)
	elseif command == "color" then
		DropList:CommandColor(rest)
	elseif command == "opacity" then
		DropList:CommandOpacity(rest)
	elseif command == "fontsize" then
		DropList:CommandFontSize(rest)
	elseif command == "tooltip" then
		DropList:CommandTooltip()
	elseif command == "test" then
		DropList:RunSelfTest()
	elseif command == "debug" then
		DropList:PrintDebug()
	else
		DropList:PrintHelp()
	end
end

local function handleCommand(message)
	-- Se conserva el caso original: los enlaces de objeto no deben pasar a minúsculas.
	local command, rest = string.match(tostring(message or ""), "^(%S*)%s*(.*)$")
	dispatchCommand(string.lower(command or ""), rest or "")
end

SLASH_DROPLIST1 = "/droplist"
SLASH_DROPLIST2 = "/dl"
SLASH_DROPLIST3 = "/dlist"
SlashCmdList["DROPLIST"] = function(message)
	-- Un error de Lua aquí abortaría ChatEdit_SendText y dejaría el chat abierto,
	-- así que se captura siempre y se informa por el chat.
	local ok, err = pcall(handleCommand, message)
	if not ok then
		DropList:Print("Error: " .. tostring(err), 1, 0.3, 0.3)
		if UIErrorsFrame then
			UIErrorsFrame:AddMessage("DropList error: " .. tostring(err), 1, 0.1, 0.1, 1)
		end
	end
end

-- Eventos -----------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
DropList.eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
	if event == "ADDON_LOADED" then
		if arg1 == "DropList" then
			DropList:InitDB()
		end
	elseif event == "PLAYER_LOGIN" then
		DropList:EnrichEntries()
		DropList:HookTooltips()
		if DropList:Settings().minimap then
			DropList:CreateMinimapButton()
		end

		if not DropList.hookedInsertLink then
			DropList.hookedInsertLink = true
			local originalInsertLink = ChatEdit_InsertLink
			if originalInsertLink then
				ChatEdit_InsertLink = function(text, ...)
					-- Shift-clic sobre un objeto con la lista abierta: se añade directamente.
					-- Nunca se roba el enlace mientras el jugador escribe en cualquier sitio.
					if not DropList:IsTypingInEditBox()
						and DropList.main and DropList.main:IsShown()
						and type(text) == "string" and string.find(text, "item:", 1, true) then
						local item = DropList:ResolveItem(text)
						if item then
							DropList:AddItem(item)
							return true
						end
					end
					return originalInsertLink(text, ...)
				end
			end
		end

		DropList:Print(L.Loaded, 0.8, 0.8, 0.8)
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- El cliente puede terminar de inicializar la UI después: se refresca
		-- el skin (color de acento, fuentes y opacidad) y el botón del minimapa.
		if DropList.main then
			DropList:ApplySkin()
		end
		DropList:SkinMinimapButton()
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		-- El cliente acaba de cachear un objeto: se completa la fila sin esperar
		-- a que el jugador vuelva a abrir la ventana.
		if arg1 and DropList.Model:Get(arg1) and DropList:EnrichEntries() then
			if DropList.main and DropList.main:IsShown() then
				DropList:Refresh()
			end
		end
	end
end)

-- Se instalan los hooks del tooltip lo antes posible, para que un objeto visto
-- antes de abrir la ventana ya esté capturado.
DropList:HookTooltips()
