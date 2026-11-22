-- DropList - valores por defecto, variables guardadas y utilidades
local DropList = _G.DropList or {}
_G.DropList = DropList

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = copy(v)
	end
	return out
end
DropList.Copy = copy

local function mergeDefaults(target, defaults)
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			if type(target[k]) ~= "table" then
				target[k] = {}
			end
			mergeDefaults(target[k], v)
		elseif target[k] == nil then
			target[k] = v
		end
	end
end

local SCHEMA = 4

-- Paletas de la interfaz: fondo y color de acento de cada una.
DropList.PALETTES = {
	obsidiana = { bg = { r = 0.03, g = 0.03, b = 0.05 }, accent = { r = 0.41, g = 0.80, b = 0.94 } },
	cuero     = { bg = { r = 0.09, g = 0.06, b = 0.04 }, accent = { r = 0.85, g = 0.68, b = 0.42 } },
	cian      = { bg = { r = 0.02, g = 0.06, b = 0.08 }, accent = { r = 0.16, g = 0.85, b = 0.95 } },
	dorado    = { bg = { r = 0.07, g = 0.05, b = 0.02 }, accent = { r = 1.00, g = 0.82, b = 0.12 } },
	esmeralda = { bg = { r = 0.02, g = 0.07, b = 0.05 }, accent = { r = 0.25, g = 0.90, b = 0.55 } },
}

function DropList:IsValidPalette(name)
	return type(name) == "string" and DropList.PALETTES[string.lower(name)] ~= nil
end

local ACCOUNT_DEFAULTS = {
	version = SCHEMA,
	settings = {
		scale = 1,
		minimap = true,
		minimapAngle = 210,
		search = "",
		-- Aspecto: color de acento, opacidad y tipografía propios.
		accent = { r = 0.41, g = 0.80, b = 0.94 },
		opacity = 0.94,
		fontSize = 0,
		palette = "obsidiana",
		background = { r = 0.03, g = 0.03, b = 0.05 },
		-- Tamaño de la ventana y ancho de las columnas de la lista.
		frameSize = { width = 440, height = 520 },
		columns = { name = 210, count = 40 },
		filter = "all",
		tooltipButton = true,
		-- Calidades que muestran el botón Añadir en el tooltip, según esté solo o en grupo.
		tooltipQualities = {
			solo = { [2] = true, [3] = true, [4] = true, [5] = true },
			group = { [3] = true, [4] = true, [5] = true },
		},
	},
}

local CHAR_DEFAULTS = {
	version = SCHEMA,
}

-- Las versiones antiguas guardaban una fila por objeto, jefe y dificultad. Se
-- agrupan en una sola fila, pero conservando todos los campos (tipo, equipo,
-- pila y fecha) para no perder la clasificación ya calculada.
local function normalizeEntries()
	local entries = _G.DropListCharDB.entries
	local normalized = {}
	for _, entry in pairs(entries) do
		local itemID = type(entry) == "table" and tonumber(entry.itemID)
		if itemID then
			local count = tonumber(entry.count) or tonumber(entry.dropped) or 1
			if count < 1 then count = 1 end
			local existing = normalized[itemID]
			if existing then
				existing.count = existing.count + count
				for key, value in pairs(entry) do
					if existing[key] == nil then
						existing[key] = value
					end
				end
			else
				local copy = DropList.Copy(entry)
				copy.itemID = itemID
				copy.count = count
				copy.dropped = nil
				normalized[itemID] = copy
			end
		end
	end
	_G.DropListCharDB.entries = normalized
end

function DropList:InitDB()
	local previousVersion = type(_G.DropListDB) == "table" and tonumber(_G.DropListDB.version) or 0
	local charVersion = type(_G.DropListCharDB) == "table" and tonumber(_G.DropListCharDB.version) or 0

	if type(_G.DropListDB) ~= "table" then
		_G.DropListDB = {}
	end
	mergeDefaults(_G.DropListDB, ACCOUNT_DEFAULTS)

	if type(_G.DropListCharDB) ~= "table" then
		_G.DropListCharDB = {}
	end
	mergeDefaults(_G.DropListCharDB, CHAR_DEFAULTS)

	if type(_G.DropListCharDB.entries) ~= "table" then
		_G.DropListCharDB.entries = {}
	end
	if type(_G.DropListCharDB.undo) ~= "table" then
		_G.DropListCharDB.undo = {}
	end

	if previousVersion < SCHEMA then
		-- La versión 0.1 dejó un filtro y ajustes de banda que ya no existen.
		-- Un filtro antiguo es la forma más fácil de pensar que el addon no añade nada.
		local settings = _G.DropListDB.settings
		settings.search = ""
		settings.raidScale = nil
		settings.raidPos = nil
		settings.onlyNeed = nil
		settings.selInstance = nil
		settings.selBoss = nil
		settings.selBossInstance = nil
	end

	-- La migración se ejecuta una sola vez por personaje. Así no se borra en
	-- cada login la clasificación que ya se había calculado.
	if charVersion < SCHEMA then
		normalizeEntries()
	end
	_G.DropListCharDB.undo = {}
	_G.DropListCharDB.version = SCHEMA
	_G.DropListDB.version = SCHEMA
end

function DropList:Settings()
	return _G.DropListDB.settings
end

function DropList:CharDB()
	return _G.DropListCharDB
end

function DropList:Print(message, r, g, b)
	local prefix = "|cff69ccf0DropList|r"
	if self.ColorText then
		prefix = self:ColorText("DropList")
	end
	DEFAULT_CHAT_FRAME:AddMessage(
		prefix .. ": " .. tostring(message),
		r or 1, g or 1, b or 1
	)
end

-- Quita espacios al principio y al final de cualquier valor.
function DropList.Trim(text)
	text = tostring(text or "")
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	return text
end
