local addonName, addon = ...

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99WritMaxxer|r: " .. message)
end

local function handleSlashCommand(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    if command == "scan" then
        addon:StartScan()
        return
    elseif command == "results" then
        addon:ShowResults()
        return
    end

    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")

    addon:Print("Loaded. Version " .. version .. ".")
    addon:Print("Commands: /wmax scan, /wmax results.")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    self:UnregisterEvent(event)

    SLASH_WRITMAXXER1 = "/writmaxxer"
    SLASH_WRITMAXXER2 = "/wmax"
    SlashCmdList.WRITMAXXER = handleSlashCommand
end)
