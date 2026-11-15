-- DropList - arranque y espacio de nombres compartido
local DropList = _G.DropList
if type(DropList) ~= "table" then
	DropList = {}
	_G.DropList = DropList
end

DropList.addonName = "DropList"
DropList.version = "0.5"
DropList.author = "Sathaniel"

-- Colores de calidad de objeto (0..7), usados en toda la interfaz.
DropList.QualityColors = {
	[0] = { 0.62, 0.62, 0.62 }, -- pobre
	[1] = { 1.00, 1.00, 1.00 }, -- común
	[2] = { 0.12, 1.00, 0.00 }, -- poco común
	[3] = { 0.00, 0.44, 0.87 }, -- raro
	[4] = { 0.64, 0.21, 0.93 }, -- épico
	[5] = { 1.00, 0.50, 0.00 }, -- legendario
	[6] = { 0.90, 0.80, 0.50 }, -- artefacto
	[7] = { 0.00, 0.80, 1.00 }, -- reliquia
}

function DropList:GetQualityColor(quality)
	local c = self.QualityColors[tonumber(quality) or 1] or self.QualityColors[1]
	return c[1], c[2], c[3]
end

-- Colores compartidos extra
DropList.Colors = {
	accent = { 0.41, 0.80, 0.94 }, -- azul claro
	good = { 0.12, 1.00, 0.00 },
	warn = { 1.00, 0.82, 0.00 },
	bad = { 1.00, 0.25, 0.25 },
	dim = { 0.55, 0.55, 0.55 },
}
