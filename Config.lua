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

local ACCOUNT_DEFAULTS = {
	version = SCHEMA,
	settings = {
		scale = 1,
		minimap = true,
		minimapAngle = 210,
		search = "",
		-- Appearance (optional ElvUI skin + own tweaks, like Omen)
		theme = "auto",
		accent = { r = 0.41, g = 0.80, b = 0.94 },
		opacity = 0.94,
		fontSize = 0,
		tooltipButton = true,
		tooltipQualities = {
		    solo = { [2]=true, [3]=true, [4]=true, [5]=true },
		    group = { [3]=true, [4]=true, [5]=true },
		},
	},
}

local CHAR_DEFAULTS = {
	version = SCHEMA,
}

-- Old versions stored one row per item + boss + difficulty. Fold those into a
-- single row per item so nobody loses their list.
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
			else
				normalized[itemID] = {
					itemID = itemID,
					name = entry.name,
					quality = entry.quality,
					icon = entry.icon,
					link = entry.link,
					count = count,
				}
			end
		end
	end
	_G.DropListCharDB.entries = normalized
end

function DropList:InitDB()
	if type(_G.DropListDB) ~= "table" then
		_G.DropListDB = {}
	end
	local previousVersion = tonumber(_G.DropListDB.version) or 0
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
		-- Version 0.1 left a filter and raid settings behind. A stale filter is
		-- the easiest way to think "the addon did not add anything".
		local settings = _G.DropListDB.settings
		settings.search = ""
		settings.raidScale = nil
		settings.raidPos = nil
		settings.onlyNeed = nil
		settings.selInstance = nil
		settings.selBoss = nil
		settings.selBossInstance = nil
	end

	-- Keep an unknown theme value from breaking the theme picker.
	local theme = _G.DropListDB.settings.theme
	if theme ~= "auto" and theme ~= "elvui" and theme ~= "classic" then
		_G.DropListDB.settings.theme = "auto"
	end

	normalizeEntries()
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

-- Trims leading/trailing whitespace from any value.
function DropList.Trim(text)
	text = tostring(text or "")
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	return text
end