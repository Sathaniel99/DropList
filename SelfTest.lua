-- DropList - in-game self test (/droplist test)
local DropList = _G.DropList or {}
_G.DropList = DropList

local L = DropList.L
local M = DropList.Model

function DropList:RunSelfTest()
	local checks = 0
	local failures = {}

	local function check(name, condition)
		checks = checks + 1
		if not condition then
			table.insert(failures, name)
		end
	end

	local realDB = _G.DropListCharDB
	_G.DropListCharDB = { version = 2, entries = {}, undo = {} }

	local ok, err = pcall(function()
		M:Add({ itemID = 49908, name = "Saronita primordial", quality = 4, link = "item:49908", qty = 1 })
		check("add creates an entry", #M:EntryList({}) == 1)
		check("count starts at 1", M:Get(49908) and M:Get(49908).count == 1)

		M:Add({ itemID = 49908, name = "Saronita primordial", qty = 2 })
		check("adding again stacks", M:Get(49908) and M:Get(49908).count == 3)

		M:Add({ itemID = 47557, name = "Marca de santificación" })
		check("different items are different rows", #M:EntryList({}) == 2)
		check("search by name", #M:EntryList({ text = "saronita" }) == 1)
		check("search miss", #M:EntryList({ text = "no existe" }) == 0)

		local stats = M:Stats()
		check("stats count items", stats.items == 2)
		check("stats count units", stats.units == 4)

		check("undo available", M:Undo() == true)
		check("undo removes the last add", M:Get(47557) == nil)

		local removed, entry = M:Remove(49908)
		check("remove returns the entry", removed and entry and entry.itemID == 49908)
		check("remove deletes it", M:Get(49908) == nil)

		M:Add({ itemID = 1, name = "Prueba" })
		M:ClearAll()
		check("clear empties the list", #M:EntryList({}) == 0)
		check("undo restores the clear", M:Undo() == true and M:Get(1) ~= nil)

		-- Row buttons: gear gets one button, countable items get X, + and -.
		check("weapon is gear", DropList:ClassifyItem("INVTYPE_WEAPON", 1) == "equip")
		check("trinket is gear", DropList:ClassifyItem("INVTYPE_TRINKET", 1) == "equip")
		check("bag is gear", DropList:ClassifyItem("INVTYPE_BAG", 1) == "equip")
		check("ammo is countable", DropList:ClassifyItem("INVTYPE_AMMO", 1000) == "stack")
		check("material is countable", DropList:ClassifyItem("", 20) == "stack")
		check("non-equip is countable", DropList:ClassifyItem("INVTYPE_NON_EQUIP", 1) == "stack")
		check("no data is countable", DropList:ClassifyItem(nil, nil) == "stack")
		check("unknown item keeps one button", DropList:IsEquipableEntry({}) == true)

		-- + / -: clamped at 1 and not undoable.
		local undoBefore = M:UndoCount()
		M:Add({ itemID = 70001, name = "Contable", itemType = "stack" })
		local adjustEntry, changed = M:Adjust(70001, 1)
		check("plus raises the count", changed == true and adjustEntry.count == 2)
		adjustEntry, changed = M:Adjust(70001, -1)
		check("minus lowers the count", changed == true and adjustEntry.count == 1)
		adjustEntry, changed = M:Adjust(70001, -1)
		check("minus stops at one", changed == false and adjustEntry.count == 1)
		check("plus and minus are not undoable", M:UndoCount() == undoBefore + 1)
		check("countable entry keeps three buttons", DropList:IsEquipableEntry({ itemID = 70001, itemType = "stack" }) == false)
	end)

	_G.DropListCharDB = realDB

	if not ok then
		self:Print(string.format(L.SelfTestFail, tostring(err)), 1, 0.3, 0.3)
		return
	end
	if #failures > 0 then
		self:Print(L.SelfTestHeader, 1, 0.6, 0.2)
		for _, name in ipairs(failures) do
			self:Print("  - " .. name, 1, 0.3, 0.3)
		end
		return
	end
	self:Print(string.format(L.SelfTestOk, checks), 0.4, 1, 0.4)
end
