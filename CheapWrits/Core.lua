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
    addon:Print("Commands: /cw scan, /cw replay (saved snapshot), /cw results.")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    self:UnregisterEvent(event)

    SLASH_CHEAPWRITS1 = "/cheapwrits"
    SLASH_CHEAPWRITS2 = "/cw"
    SlashCmdList.CHEAPWRITS = handleSlashCommand
end)
