local _, addon = ...

local window, content, scroll, status, empty
local rowFrames = {}
local rowHeight = 44
local contentWidth = 840
local unknownIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

local function money(copper)
    if not copper then
        return "Unavailable"
    end

    copper = math.ceil(copper)

    return string.format("%dg %ds %dc", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
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
    if not icon then
        local resolvedID, _, _, _, resolvedIcon = C_Item.GetItemInfoInstant(itemID or name)
        itemID, icon = itemID or resolvedID, resolvedIcon
    end

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

    row.writ = createIcon(row, 8)
    row.writPrice = label(row, 56, 140)
    row.item = createIcon(row, 216)
    row.itemPrice = label(row, 264, 140)
    row.totalPrice = label(row, 424, 140)
    row.reputation = label(row, 600, 64)
    row.goldPer100Rep = label(row, 684, 148)
    return row
end

local function createWindow()
    window = CreateFrame("Frame", "WritMaxxerResults", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(900, 520)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window.TitleText:SetText("WritMaxxer — Auction prices")
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
    note:SetText("Counts: buyout stock. Unit prices: prorated estimates. Gold/100 rep: full turn-in cost, base rep.")

    local header = CreateFrame("Frame", nil, window)
    header:SetSize(contentWidth, 24)
    header:SetPoint("TOPLEFT", 16, -80)
    for _, column in ipairs({
        { 8, 40, "Writ" }, { 56, 140, "Unit price" },
        { 216, 40, "Item" }, { 264, 140, "Unit price" },
        { 424, 140, "Total (pair)" }, { 600, 64, "Rep" },
        { 684, 148, "Gold / 100 rep" },
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

    local age = math.floor((GetTime() - self.scannedAt) / 60)
    status:SetText("Snapshot: " .. age .. " minutes old. Sorted by gold/100 rep, then availability. Hover icons for details.")
    for index, row in ipairs(rows) do
        local frame = rowFrames[index] or createRow(index)
        rowFrames[index] = frame
        updateIcon(frame.writ, row.writName, row.writItemID, row.writIcon, row.writStock, 1)
        updateIcon(frame.item, row.itemName, row.itemID, row.itemIcon, row.itemStock, row.quantity)
        frame.writPrice:SetText(money(row.writCost))
        frame.itemPrice:SetText(money(row.itemUnitCost))
        frame.totalPrice:SetText(money(row.total))
        frame.reputation:SetText(row.reputation or "Unknown")
        frame.goldPer100Rep:SetText(row.costPer100Rep and string.format("%.6fg", row.costPer100Rep / 10000) or "Unavailable")
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
