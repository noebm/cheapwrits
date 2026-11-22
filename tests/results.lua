local testing = dofile('tests/testing.lua')
local tests = {}

local function setup()
    -- Exercise rendering, replay compatibility, tooltips, and row reuse at the UI boundary.
    local frames = {}
    local function widget(parent)
        local self = { parent = parent, scripts = {}, shown = true }
        function self:SetSize(w, h) self.width, self.height = w, h end
        function self:SetHeight(h) self.height = h end
        function self:SetWidth(w) self.width = w end
        function self:SetPoint() end
        function self:SetAllPoints() end
        function self:SetFrameStrata() end
        function self:SetMovable() end
        function self:EnableMouse() end
        function self:RegisterForDrag() end
        function self:RegisterEvent() end
        function self:SetJustifyH() end
        function self:SetSpacing() end
        function self:GetStringHeight() return 40 end
        function self:SetTextColor() end
        function self:SetColorTexture() end
        function self:SetTexCoord() end
        function self:SetText(text) self.text = tostring(text) end
        function self:SetTexture(texture) self.texture = texture end
        function self:SetScrollChild(child) self.child = child end
        function self:SetVerticalScroll(value) self.offset = value end
        function self:SetScript(event, handler) self.scripts[event] = handler end
        function self:Show() self.shown = true end
        function self:Hide() self.shown = false end
        function self:CreateFontString() return widget(self) end
        function self:CreateTexture() return widget(self) end
        return self
    end
    function CreateFrame(kind, name, parent)
        local frame = widget(parent)
        frame.kind, frame.name = kind, name
        frame.TitleText = widget(frame)
        frames[#frames + 1] = frame
        return frame
    end
    UIParent, UISpecialFrames = {}, {}
    function GetTime() return 120 end
    C_Map = { GetMapInfo = function(id)
        if id == 1437 then return { name = 'Sumpfland' } end
    end }
    C_Item = {
        GetItemInfoInstant = function() return nil end,
        GetItemInfo = function() return nil end,
    }
    C_CurrencyInfo = {
        GetCoinTextureString = function(copper)
            assert(copper == math.floor(copper), 'Coin formatting requires whole copper')
            return 'coin icons: ' .. copper
        end,
    }
    GameTooltip = widget()
    function GameTooltip:SetOwner() end
    function GameTooltip:SetItemByID(id) self.itemID = id end
    function GameTooltip:AddLine(line) self.line = line end

    local addon = { scannedAt = 0 }
    assert(loadfile('CheapWrits/Writs.lua'))('CheapWrits', addon)
    function addon:Print(message) self.message = message end
    assert(loadfile('CheapWrits/Results.lua'))('CheapWrits', addon)

    local row = {
        writName = "Craftsman's Writ: Crafted Solid Shot", itemName = 'Crafted Solid Shot',
        writItemID = 264037, itemID = 8069, writIcon = 134939, itemIcon = 132384,
        writStock = 3, itemStock = 250, quantity = 200, availableTurnIns = 1,
        writCost = 25, itemUnitCost = 1, total = 425, reputation = 75, costPer100Rep = 425 * 100 / 75,
    }

    return addon, frames, row
end

tests['rendering replay tooltips and row reuse'] = function()
    local addon, frames, row = setup()

    addon:ShowResults()
    assert(addon.message:find('No results loaded', 1, true))
    addon:ShowResults({ row, row })
    local buttons = {}
    for _, frame in ipairs(frames) do
        if frame.kind == 'Button' then buttons[#buttons + 1] = frame end
    end
    assert(#buttons == 4, 'Each result must have two item icons')
    assert(buttons[1].icon.texture == 134939 and buttons[1].count.text == '3')
    assert(buttons[2].icon.texture == 132384 and buttons[2].count.text == '250')
    buttons[2].scripts.OnEnter(buttons[2])
    assert(GameTooltip.itemID == 8069 and GameTooltip.line:find('200', 1, true))
    buttons[2].scripts.OnLeave(buttons[2])
    assert(not GameTooltip.shown)
    local firstRow = buttons[1].parent
    assert(firstRow.itemName.text == 'Crafted Solid Shot')
    assert(firstRow.turnInZone.text == 'Sumpfland', 'Resolve zone names in the client locale')
    assert(firstRow.writPrice.text == 'coin icons: 25')
    assert(firstRow.itemPrice.text == 'coin icons: 1')
    assert(firstRow.totalPrice.text == 'coin icons: 425')
    assert(firstRow.reputation.text == '75')
    assert(firstRow.pricePer100Rep.text == 'coin icons: 566')

    -- An old snapshot may have no metadata and no complete price estimate.
    local old = {
        writName = 'Unknown writ', itemName = 'Unknown item', writStock = 1, itemStock = 0,
        quantity = 1, availableTurnIns = 0,
    }
    addon:ShowResults({ old })
    assert(#frames > 0 and not buttons[3].parent.shown)
    assert(buttons[1].count.text == '1' and buttons[2].count.text == '0')
    assert(buttons[2].icon.texture == 'Interface\\Icons\\INV_Misc_QuestionMark')
    assert(firstRow.itemName.text == 'Unknown item')
    assert(firstRow.turnInZone.text == 'Unknown')
    assert(firstRow.totalPrice.text == 'Unavailable')
    assert(firstRow.itemPrice.text == 'Unavailable' and firstRow.pricePer100Rep.text == 'Unavailable')
    buttons[2].scripts.OnEnter(buttons[2])
    assert(GameTooltip.text == 'Unknown item')
    local frameCount = #frames
    addon:ShowResults({ row })
    assert(#frames == frameCount and firstRow.shown, 'Reuse existing rows')
    C_Map.GetMapInfo = function() return nil end
    addon:ShowResults({ row })
    assert(firstRow.turnInZone.text == 'Unknown', 'Handle map data unavailable in this client')
    addon:ShowResults({})
    assert(not firstRow.shown)
end

tests['asynchronous item metadata updates preserve rows and the current view'] = function()
    local addon, frames, row = setup()
    addon:ShowResults({ row, row })
    local buttons = {}
    for _, frame in ipairs(frames) do
        if frame.kind == 'Button' then buttons[#buttons + 1] = frame end
    end
    local firstRow = buttons[1].parent

    -- Missing stock still gets its localized name from item data, including late loads.
    local itemNames = { [11128] = 'Goldrute' }
    C_Item.GetItemInfo = function(id) return itemNames[id] end
    local missing = {
        writName = 'Rod writ', writItemID = 264021, writStock = 1,
        itemName = 'Stale snapshot name', itemID = 11128, itemStock = 0, quantity = 1,
    }
    addon:ShowResults({ missing })
    assert(firstRow.itemName.text == 'Goldrute', 'Resolve names without auction stock')
    assert(missing.itemName == 'Stale snapshot name', 'Rendering leaves pricing rows unchanged')

    local late = {
        writName = 'Ammo writ', writItemID = 264037, writStock = 1,
        itemName = '8069', itemID = 8069, itemStock = 0, quantity = 200,
    }
    addon:ShowResults({ late })
    assert(firstRow.itemName.text == '8069')
    local window
    for _, frame in ipairs(frames) do
        if frame.name == 'CheapWritsResults' then window = frame end
    end
    itemNames[8069] = 'Munition'
    window.scripts.OnEvent(window, 'GET_ITEM_INFO_RECEIVED', 8069, true)
    assert(firstRow.itemName.text == 'Munition', 'Refresh names when item data arrives')
    assert(firstRow.item.count.text == '0' and firstRow.totalPrice.text == 'Unavailable')

    -- A late response must not overwrite a reused row.
    addon:ShowResults({ row })
    window.scripts.OnEvent(window, 'GET_ITEM_INFO_RECEIVED', 8069, true)
    assert(firstRow.itemName.text == 'Munition')
    assert(row.itemName == 'Crafted Solid Shot', 'Rendering leaves snapshot metadata unchanged')

    -- Shared item IDs resolve once per render, supplying both names and icons.
    local lookups = {}
    C_Item.GetItemInfo = function(id)
        lookups[id] = (lookups[id] or 0) + 1
        return itemNames[id], nil, nil, nil, nil, nil, nil, nil, nil, 987
    end
    C_Item.GetItemInfoInstant = function() error('Rendering must use the resolved metadata') end
    addon:ShowResults({ missing, missing })
    assert(lookups[11128] == 1 and lookups[264021] == 1)
    assert(firstRow.itemName.text == 'Goldrute' and firstRow.item.icon.texture == 987)
    assert(buttons[4].icon.texture == 987)

    -- Loading one item updates every matching row without redrawing or moving the view.
    local scroll
    for _, frame in ipairs(frames) do
        if frame.kind == 'ScrollFrame' then scroll = frame end
    end
    scroll:SetVerticalScroll(88)
    window:Hide()
    itemNames[11128] = 'Updated rod'
    lookups = {}
    window.scripts.OnEvent(window, 'GET_ITEM_INFO_RECEIVED', 11128, true)
    assert(firstRow.itemName.text == 'Updated rod')
    assert(buttons[4].parent.itemName.text == 'Updated rod')
    assert(scroll.offset == 88 and not window.shown, 'Item loading preserves the current view')
    assert(lookups[11128] == 1 and lookups[264021] == nil, 'Only the loaded item is looked up')
    lookups = {}
    window.scripts.OnEvent(window, 'GET_ITEM_INFO_RECEIVED', 99999, true)
    window.scripts.OnEvent(window, 'GET_ITEM_INFO_RECEIVED', 11128, false)
    assert(next(lookups) == nil, 'Ignore unrelated and failed loads')
end

local counts = testing.run_tests(tests)
print(string.format('results tests passed (%d tests, %d cases)', counts.tests, counts.cases))
