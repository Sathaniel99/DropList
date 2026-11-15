local DropList = _G.DropList
if not DropList then return end

local addButton

local function GetAllowedQualities()
    -- En grupo/raid: azul (3), morado (4), naranja (5)
    -- En solitario: verde (2) para pruebas, más los anteriores
    if IsInGroup() or IsInRaid() then
        return { [3]=true, [4]=true, [5]=true }
    else
        return { [2]=true, [3]=true, [4]=true, [5]=true }
    end
end

local function OnAddClick(self)
    local link = self.itemLink
    if not link then return end

    local item = DropList:ResolveItem(link)   -- normaliza el enlace
    if item then
        DropList:AddItem(item)                -- usa la lógica interna del addon
    end
end

local function CreateButton(parent)
    if addButton then return addButton end

    addButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    addButton:SetSize(80, 22)
    addButton:SetText("Añadir")
    addButton:SetScript("OnClick", OnAddClick)
    return addButton
end

local function HookItemRef()
    if not ItemRefTooltip then return end

    ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        CreateButton(tooltip)

        local _, link = tooltip:GetItem()
        if not link then addButton:Hide(); return end

        local item = DropList:ResolveItem(link)
        if not item then addButton:Hide(); return end

        local allowed = GetAllowedQualities()
        if item.quality and not allowed[item.quality] then
            addButton:Hide()
            return
        end

        addButton.itemLink = link
        addButton:ClearAllPoints()
        addButton:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -8, 8)
        addButton:Show()
    end)

    ItemRefTooltip:HookScript("OnHide", function()
        if addButton then addButton:Hide() end
    end)
end

-- ItemRefTooltip se crea al inicio; si no existe aún, esperamos a PLAYER_LOGIN
if ItemRefTooltip then
    HookItemRef()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function()
        HookItemRef()
        f:UnregisterAllEvents()
    end)
end