-- DropList - bootstrap and shared namespace
local DropList = _G.DropList
if type(DropList) ~= "table" then
	DropList = {}
	_G.DropList = DropList
end

DropList.addonName = "DropList"
DropList.version = "0.5"
DropList.author = "Sathaniel"

-- Item quality colors (0..7), used all over the UI.
DropList.QualityColors = {
	[0] = { 0.62, 0.62, 0.62 }, -- poor
	[1] = { 1.00, 1.00, 1.00 }, -- common
	[2] = { 0.12, 1.00, 0.00 }, -- uncommon
	[3] = { 0.00, 0.44, 0.87 }, -- rare
	[4] = { 0.64, 0.21, 0.93 }, -- epic
	[5] = { 1.00, 0.50, 0.00 }, -- legendary
	[6] = { 0.90, 0.80, 0.50 }, -- artifact
	[7] = { 0.00, 0.80, 1.00 }, -- heirloom
}

function DropList:GetQualityColor(quality)
	local c = self.QualityColors[tonumber(quality) or 1] or self.QualityColors[1]
	return c[1], c[2], c[3]
end

-- Extra shared colors
DropList.Colors = {
	accent = { 0.41, 0.80, 0.94 }, -- light blue
	good = { 0.12, 1.00, 0.00 },
	warn = { 1.00, 0.82, 0.00 },
	bad = { 1.00, 0.25, 0.25 },
	dim = { 0.55, 0.55, 0.55 },
}
