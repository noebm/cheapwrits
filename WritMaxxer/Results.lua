local _, addon = ...

local window, content, text, scroll

local function money(copper)
    if not copper then
        return "Unavailable"
    end

    copper = math.ceil(copper)

    return string.format("%dg %ds %dc", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

local function createWindow()
    window = CreateFrame("Frame", "WritMaxxerResults", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(740, 520)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window.TitleText:SetText("WritMaxxer — Auction prices")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    table.insert(UISpecialFrames, "WritMaxxerResults")

    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -36)
    scroll:SetPoint("BOTTOMRIGHT", -32, 16)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(680, 1)
    scroll:SetScrollChild(content)

    text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT")
    text:SetWidth(680)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
end

function addon:ShowResults(rows)
    rows = rows or self.results
    if not rows then
        self:Print("No results loaded. Use /wmax replay for a saved snapshot, or /wmax scan at the auction house.")
        return
    end

    if not window then
        createWindow()
    end

    local age = math.floor((GetTime() - self.scannedAt) / 60)
    local lines = {
        "Snapshot requested: " .. age .. " minutes ago. Sorted by estimated cost per 100 reputation.",
        "Stack prices are prorated per unit. Costs include the writ and required items.",
        "Base reputation before bonuses. Unknown rewards and unavailable costs sort last.",
        "",
    }

    if #rows == 0 then
        lines[#lines + 1] = "No Craftsman's Writ listings found in this scan."
    end

    for index, row in ipairs(rows) do
        lines[#lines + 1] = index .. ". " .. row.writName .. " — requires " .. row.quantity .. " x " .. row.itemName
        lines[#lines + 1] = "Rep: " .. (row.reputation or "Unknown") .. "   Turn-ins available: " .. row.availableTurnIns .. "   Per 100 rep: " .. money(row.costPer100Rep)
        lines[#lines + 1] = "Writ: " .. money(row.writCost) .. "   Items: " .. money(row.itemCost) .. "   Total: " .. money(row.total)
        lines[#lines + 1] = ""
    end

    text:SetText(table.concat(lines, "\n"))
    content:SetHeight(math.max(1, text:GetStringHeight() + 16))
    scroll:SetVerticalScroll(0)
    window:Show()
end
