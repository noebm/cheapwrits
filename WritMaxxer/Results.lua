local _, addon = ...

local window, content, scroll, status, empty
local displayedRows
local rowFrames = {}
local rowHeight = 44
local contentWidth = 1260
local unknownIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

local function money(copper)
    if not copper then
        return "Unavailable"
    end

    return C_CurrencyInfo.GetCoinTextureString(math.floor(copper))
end

local function label(parent, x, width, font)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetPoint("LEFT", parent, "LEFT", x, 0)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    return text
end

local function createIcon(parent, x)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(32, 32)
    button:SetPoint("LEFT", parent, "LEFT", x, 0)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -1, 1)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.itemID then
            GameTooltip:SetItemByID(self.itemID)
        else
            GameTooltip:SetText(self.itemName)
        end

        GameTooltip:AddLine("Required per turn-in: " .. self.required .. " | Available: " .. self.stock, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function updateIcon(button, name, itemID, icon, stock, required)
    button.itemName, button.itemID = name, itemID
    button.stock, button.required = stock, required
    button.icon:SetTexture(icon or unknownIcon)
    button.count:SetText(stock)
end

local function createRow(index)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(contentWidth, rowHeight)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
    if index % 2 == 0 then
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(1, 1, 1, 0.04)
    end

    row.itemName = label(row, 8, 224)
    row.writ = createIcon(row, 248)
    row.writPrice = label(row, 296, 140)
    row.item = createIcon(row, 456)
    row.itemPrice = label(row, 504, 140)
    row.totalPrice = label(row, 664, 140)
    row.reputation = label(row, 840, 64)
    row.pricePer100Rep = label(row, 924, 148)
    row.turnInZone = label(row, 1088, 164)
    return row
end

local function onItemInfoReceived(_, _, itemID, success)
    if not success then return end

    local name, icon, resolved
    for index, row in ipairs(displayedRows or {}) do
        if row.itemID == itemID or row.writItemID == itemID then
            if not resolved then
                local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(itemID)
                name, icon, resolved = itemName, itemIcon, true
            end

            local frame = rowFrames[index]
            for _, button in ipairs({ frame.item, frame.writ }) do
                if button.itemID == itemID then
                    button.itemName = name or button.itemName
                    if icon then button.icon:SetTexture(icon) end
                end
            end

            frame.itemName:SetText(frame.item.itemName)
        end
    end
end

local function createWindow()
    window = CreateFrame("Frame", "WritMaxxerResults", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(1320, 520)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window.TitleText:SetText("WritMaxxer — Auction prices")
    window:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    window:SetScript("OnEvent", onItemInfoReceived)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    table.insert(UISpecialFrames, "WritMaxxerResults")

    status = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", 16, -36)
    status:SetWidth(contentWidth)
    status:SetJustifyH("LEFT")
    local note = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 16, -56)
    note:SetWidth(contentWidth)
    note:SetJustifyH("LEFT")
    note:SetText("Counts: buyout stock. Unit prices: prorated estimates. Price/100 rep: full turn-in cost, base rep.")

    local header = CreateFrame("Frame", nil, window)
    header:SetSize(contentWidth, 24)
    header:SetPoint("TOPLEFT", 16, -80)
    for _, column in ipairs({
        { 8, 224, "Item name" },
        { 248, 40, "Writ" }, { 296, 140, "Unit price" },
        { 456, 40, "Item" }, { 504, 140, "Unit price" },
        { 664, 140, "Total (pair)" }, { 840, 64, "Rep" },
        { 924, 148, "Price / 100 rep" }, { 1088, 164, "Turn-in zone" },
    }) do
        label(header, column[1], column[2], "GameFontNormalSmall"):SetText(column[3])
    end

    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -108)
    scroll:SetPoint("BOTTOMRIGHT", -32, 16)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(contentWidth, 1)
    scroll:SetScrollChild(content)

    empty = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT", 8, -12)
    empty:SetText("No Craftsman's Writ listings found in this scan.")
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

    displayedRows = rows

    -- WoW caches item data globally; this table only deduplicates lookups for this render.
    -- Uncached data arrives through GET_ITEM_INFO_RECEIVED and updates the matching rows.
    local metadata = {}
    for _, row in ipairs(rows) do
        for _, key in ipairs({ "writItemID", "itemID" }) do
            local itemID = row[key]
            if itemID and not metadata[itemID] then
                local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
                metadata[itemID] = { name = name, icon = icon }
            end
        end
    end

    local age = math.floor((GetTime() - self.scannedAt) / 60)
    status:SetText("Snapshot: " .. age .. " minutes old. Sorted by price/100 rep, then availability. Hover icons for details.")
    for index, row in ipairs(rows) do
        local frame = rowFrames[index] or createRow(index)
        rowFrames[index] = frame
        local writ = self.Writs[row.writItemID]
        local mapInfo = writ and writ.turnInMapID and C_Map.GetMapInfo(writ.turnInMapID)
        local writInfo = metadata[row.writItemID] or {}
        local itemInfo = metadata[row.itemID] or {}

        frame.turnInZone:SetText(mapInfo and mapInfo.name or "Unknown")
        updateIcon(frame.writ, writInfo.name or row.writName, row.writItemID, writInfo.icon or row.writIcon, row.writStock, 1)
        updateIcon(frame.item, itemInfo.name or row.itemName, row.itemID, itemInfo.icon or row.itemIcon, row.itemStock, row.quantity)
        frame.itemName:SetText(frame.item.itemName)
        frame.writPrice:SetText(money(row.writCost))
        frame.itemPrice:SetText(money(row.itemUnitCost))
        frame.totalPrice:SetText(money(row.total))
        frame.reputation:SetText(row.reputation or "Unknown")
        frame.pricePer100Rep:SetText(money(row.costPer100Rep))
        frame:Show()
    end

    for index = #rows + 1, #rowFrames do
        rowFrames[index]:Hide()
    end

    if #rows == 0 then empty:Show() else empty:Hide() end
    content:SetHeight(math.max(rowHeight, #rows * rowHeight))
    scroll:SetVerticalScroll(0)
    window:Show()
end
