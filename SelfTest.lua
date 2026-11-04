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
