-- DropList - modelo de datos: una fila por objeto, con contador y deshacer
local DropList = _G.DropList or {}
_G.DropList = DropList

local Model = {}
DropList.Model = Model

local MAX_VALUE = 99999
local MAX_UNDO = 30
local MIN_COUNT = 1
Model.MIN_COUNT = MIN_COUNT

local function charDB()
	return _G.DropListCharDB
end

local function clampInt(value, minimum, maximum)
	value = tonumber(value) or 0
	value = math.floor(value)
	if value < minimum then value = minimum end
	if value > maximum then value = maximum end
	return value
end
Model.ClampInt = clampInt

function Model:Entries()
	return charDB().entries
end

function Model:Get(itemID)
	itemID = tonumber(itemID)
	if not itemID then
		return nil
	end
	return charDB().entries[itemID]
end

function Model:DisplayName(entry)
	if not entry then return "?" end
	local name = entry.name
	if not name or name == "" then
		name = "item:" .. tostring(entry.itemID)
	end
	return name
end

local function capture(undo, itemID)
	for i = 1, #undo do
		if undo[i].itemID == itemID then
			return
		end
	end
	local entry = charDB().entries[itemID]
	table.insert(undo, { itemID = itemID, before = entry and DropList.Copy(entry) or nil })
end

local function pushUndo(undo)
	if #undo == 0 then
		return
	end
	local list = charDB().undo
	table.insert(list, { entries = undo, t = time() })
	while #list > MAX_UNDO do
		table.remove(list, 1)
	end
end

-- Añade un objeto (o incrementa su contador).
-- info = { itemID, name, quality, icon, link, qty, itemType, equipLoc, maxStack }
function Model:Add(info)
	local itemID = info and tonumber(info.itemID)
	if not itemID then
		return nil
	end

	local entries = charDB().entries
	local undo = {}
	capture(undo, itemID)

	local entry = entries[itemID]
	if not entry then
		entry = { itemID = itemID, count = 0 }
		entries[itemID] = entry
	end

	local qty = clampInt(info.qty or 1, 1, MAX_VALUE)
	entry.count = clampInt((entry.count or 0) + qty, 0, MAX_VALUE)
	if info.name then entry.name = info.name end
	if info.quality then entry.quality = info.quality end
	if info.icon then entry.icon = info.icon end
	if info.link then entry.link = info.link end
	if info.itemType then entry.itemType = info.itemType end
	if info.equipLoc then entry.equipLoc = info.equipLoc end
	if info.maxStack then entry.maxStack = info.maxStack end
	entry.updated = time()

	pushUndo(undo)
	return entry
end

-- Cambia el contador en delta (botones - / + de la fila). A propósito no es
-- una acción deshacible: Deshacer sigue deshaciendo el último añadir, quitar o vaciar.
function Model:Adjust(itemID, delta)
	itemID = tonumber(itemID)
	local entry = itemID and charDB().entries[itemID]
	if not entry then
		return nil, false
	end
	delta = math.floor(tonumber(delta) or 0)
	if delta == 0 then
		return entry, false
	end

	local before = clampInt(entry.count or MIN_COUNT, MIN_COUNT, MAX_VALUE)
	local count = clampInt(before + delta, MIN_COUNT, MAX_VALUE)
	if count == before then
		return entry, false
	end
	entry.count = count
	entry.updated = time()
	return entry, true
end

function Model:Remove(itemID)
	itemID = tonumber(itemID)
	local entry = itemID and charDB().entries[itemID]
	if not entry then
		return false
	end
	local undo = {}
	capture(undo, itemID)
	charDB().entries[itemID] = nil
	pushUndo(undo)
	return true, entry
end

function Model:ClearAll()
	local entries = charDB().entries
	local undo = {}
	for itemID in pairs(entries) do
		capture(undo, itemID)
	end
	charDB().entries = {}
	pushUndo(undo)
	return true
end

function Model:Undo()
	local action = table.remove(charDB().undo)
	if not action then
		return false
	end
	local entries = charDB().entries
	for _, snapshot in ipairs(action.entries or {}) do
		if snapshot.before then
			entries[snapshot.itemID] = DropList.Copy(snapshot.before)
		else
			entries[snapshot.itemID] = nil
		end
	end
	return true
end

function Model:UndoCount()
	return #charDB().undo
end

-- filter = { text }
function Model:EntryList(filter)
	filter = filter or {}
	local text = filter.text and string.lower(filter.text) or nil
	if text == "" then text = nil end

	local out = {}
	for _, entry in pairs(charDB().entries) do
		local ok = true
		if text then
			local hay = string.lower((entry.name or "") .. " item:" .. tostring(entry.itemID))
			if not string.find(hay, text, 1, true) then
				ok = false
			end
		end
		if ok then
			table.insert(out, entry)
		end
	end

	table.sort(out, function(a, b)
		return string.lower(a.name or "") < string.lower(b.name or "")
	end)
	return out
end

function Model:Stats()
	local stats = { items = 0, units = 0 }
	for _, entry in pairs(charDB().entries) do
		stats.items = stats.items + 1
		stats.units = stats.units + (entry.count or 0)
	end
	return stats
end
