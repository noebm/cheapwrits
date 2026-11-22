local addonName, addon = ...

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99CheapWrits|r: " .. message)
end

local function handleSlashCommand(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    if command == "scan" then
        addon:StartScan()
        return
    elseif command == "replay" then
        addon:ReplayScan()
        return
    elseif command == "results" then
        addon:ShowResults()
        return
    end

    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")

    addon:Print("Loaded. Version " .. version .. ".")
    addon:Print("Commands: /cwr scan, /cwr replay (saved snapshot), /cwr results.")
end

local function createMinimapButton()
    local button = CreateFrame("Button", "CheapWritsMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetPoint("CENTER", Minimap, "TOPLEFT", 18, -18)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(C_Item.GetItemIconByID(264011))

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function() addon:ShowResults() end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("CheapWrits")
        GameTooltip:AddLine("Left-click to open results.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    self:UnregisterEvent(event)

    SLASH_CHEAPWRITS1 = "/cheapwrits"
    SLASH_CHEAPWRITS2 = "/cwr"
    SlashCmdList.CHEAPWRITS = handleSlashCommand

    createMinimapButton()
end)
