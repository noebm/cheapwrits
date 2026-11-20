local _, addon = ...

-- Browse discovers item keys; detailed searches provide actual buyouts.
-- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua
local AH = C_AuctionHouse
local frame = CreateFrame("Frame")
local auctionOpen, sending = false, false
local scan
local nextRequestAt = 0
local requestInterval = 0.7 -- Below the API's 100-searches-per-minute limit.
local timeout = 60
local progressInterval = 5

frame:Hide()
for _, event in ipairs({
    "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_DISABLED",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
    "AUCTION_HOUSE_BROWSE_FAILURE", "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
    "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED",
    "COMMODITY_SEARCH_RESULTS_UPDATED", "COMMODITY_SEARCH_RESULTS_ADDED",
}) do
    frame:RegisterEvent(event)
end

local function keyID(key)
    return table.concat({ key.itemID, key.itemLevel or 0, key.itemSuffix or 0, key.battlePetSpeciesID or 0 }, ":")
end

local function stop(message)
    scan = nil
    frame:Hide()

    if message then
        addon:Print(message)
    end
end

-- The browse/search caches are shared with the default UI and other addons.
-- Give control back when another search starts instead of mixing its results.
for _, method in ipairs({
    "SendBrowseQuery", "SendSearchQuery", "SendSellSearchQuery",
    "SearchForItemKeys", "SearchForFavorites", "RequestMoreBrowseResults",
    "RequestMoreItemSearchResults", "RequestMoreCommoditySearchResults",
}) do
    if AH[method] then
        hooksecurefunc(AH, method, function()
            if scan and not sending then
                stop("Scan cancelled because another auction search started.")
            end
        end)
    end
end

local function queueRequest(more)
    scan.phase = "queued"
    scan.more = more or false
    scan.deadline = GetTime() + timeout
end

local function nextTask()
    if scan.tasks[scan.taskIndex].discovery and #scan.listings > 0 then
        addon:Print("Found " .. #scan.listings .. " writs. Checking auction prices...")
        scan.nextProgressAt = GetTime() + progressInterval
    end

    scan.taskIndex = scan.taskIndex + 1
    if scan.tasks[scan.taskIndex] then
        queueRequest()
        return
    end

    addon.results = addon.Prices.BuildRows(scan.listings)
    addon.scannedAt = scan.startedAt
    stop()
    addon:Print("Scan complete: " .. #addon.results .. " writs found. Prices are estimates from this scan.")
    addon:ShowResults(addon.results)
end

function addon:StartScan()
    local locale = GetLocale()
    if locale ~= "enUS" and locale ~= "enGB" then
        self:Print("Writ name matching currently requires an English client.")
        return
    end

    if not auctionOpen then
        self:Print("Open the auction house first, then use /wmax scan.")
        return
    end

    if scan then
        self:Print("A scan is already in progress.")
        return
    end

    scan = {
        tasks = { { kind = "browse", name = addon.Prices.WritSearch, discovery = true } },
        taskIndex = 1,
        seenKeys = {},
        seenWrits = {},
        requestedItems = {},
        listings = {},
        startedAt = GetTime(),
        nextProgressAt = GetTime() + progressInterval,
        retries = 0,
    }
    queueRequest()
    frame:Show()
    self:Print("Searching writs and their required items. Keep the auction house open until the scan finishes.")
end

local function addSearch(key, info)
    local identity = info.isCommodity and ("commodity:" .. key.itemID) or keyID(key)
    if scan.seenKeys[identity] then
        return
    end

    scan.seenKeys[identity] = true
    scan.tasks[#scan.tasks + 1] = {
        kind = "search", key = key, name = info.itemName, commodity = info.isCommodity,
    }
end

local function readBrowse(task)
    local results = AH.GetBrowseResults()
    local resolved = {}
    for index, result in ipairs(results) do
        local info = AH.GetItemKeyInfo(result.itemKey)
        if not info or not info.itemName or info.itemName == "" then
            local itemID = result.itemKey.itemID
            if not scan.requestedItems[itemID] then
                scan.requestedItems[itemID] = true
                C_Item.RequestLoadItemDataByID(itemID)
            end

            return false
        end

        resolved[index] = info
    end

    local requiredNames, seenNames = {}, {}
    for index, result in ipairs(results) do
        local info = resolved[index]
        if task.discovery then
            local itemName = addon.Prices.GetRequiredItemName(info.itemName)
            if itemName then
                addSearch(result.itemKey, info)
                if not scan.seenWrits[info.itemName] then
                    scan.seenWrits[info.itemName] = true
                    -- Keep a discovered writ in the list if its auctions disappear
                    -- before the detail search, or if it has only bids.
                    scan.listings[#scan.listings + 1] = { name = info.itemName, quantity = 1, buyout = 0 }
                end

                if not seenNames[itemName] then
                    seenNames[itemName] = true
                    requiredNames[#requiredNames + 1] = itemName
                end
            end
        elseif info.itemName == task.name then
            addSearch(result.itemKey, info)
        end
    end

    for _, name in ipairs(requiredNames) do
        scan.tasks[#scan.tasks + 1] = { kind = "browse", name = name }
    end

    return true
end

local function readSearch(task)
    local count = task.commodity and AH.GetNumCommoditySearchResults(task.key.itemID)
        or AH.GetNumItemSearchResults(task.key)
    local listings = {}
    for index = 1, count do
        local result
        if task.commodity then
            result = AH.GetCommoditySearchResultInfo(task.key.itemID, index)
        else
            result = AH.GetItemSearchResultInfo(task.key, index)
        end

        if not result then
            return false
        end

        if task.commodity or (result.itemKey and keyID(result.itemKey) == keyID(task.key)) then
            local quantity = result.quantity
            if quantity and quantity > 0 then
                local buyout = result.buyoutAmount
                if task.commodity then
                    buyout = result.unitPrice and result.unitPrice * quantity
                end

                listings[#listings + 1] = { name = task.name, quantity = quantity, buyout = buyout }
            end
        end
    end

    for _, listing in ipairs(listings) do
        scan.listings[#scan.listings + 1] = listing
    end

    return true
end

local function sendRequest(task)
    if task.kind == "browse" then
        if scan.more then
            AH.RequestMoreBrowseResults()
        else
            -- Use the game's default filters, independent of the current UI selection.
            local filters = {}
            for filter, enabled in pairs(AUCTION_HOUSE_DEFAULT_FILTERS) do
                if enabled then
                    filters[#filters + 1] = filter
                end
            end

            AH.SendBrowseQuery({
                searchString = task.name,
                minLevel = 0,
                maxLevel = 0,
                filters = filters,
                sorts = {
                    { sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false },
                    { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false },
                },
            })
        end
    elseif scan.more then
        if task.commodity then
            AH.RequestMoreCommoditySearchResults(task.key.itemID)
        else
            AH.RequestMoreItemSearchResults(task.key)
        end
    else
        AH.SendSearchQuery(task.key, {}, false)
    end
end

frame:SetScript("OnEvent", function(_, event, argument)
    if event == "AUCTION_HOUSE_SHOW" then
        auctionOpen = true
    elseif event == "AUCTION_HOUSE_CLOSED" or event == "AUCTION_HOUSE_DISABLED" then
        auctionOpen = false
        if scan then
            stop("Scan cancelled because the auction house closed or became unavailable.")
        end
    elseif scan and scan.phase == "waiting" then
        local task = scan.tasks[scan.taskIndex]
        if event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
            scan.retries = scan.retries + 1
            if scan.retries > 3 then
                stop("Scan stopped because auction searches were repeatedly dropped. Try again later.")
            else
                queueRequest(scan.more)
            end

            return
        elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" and task.kind == "browse" then
            stop("Auction search failed. Try /wmax scan again.")
            return
        end

        local browseEvent = event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED"
        local itemEvent = event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED"
        local commodityEvent = event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_ADDED"
        if (task.kind == "browse" and browseEvent)
            or (task.kind == "search" and task.commodity and commodityEvent and argument == task.key.itemID)
            or (task.kind == "search" and not task.commodity and itemEvent and argument and keyID(argument) == keyID(task.key)) then
            scan.phase = "reading"
            scan.deadline = GetTime() + timeout
            scan.retries = 0
        end
    end
end)

frame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now >= scan.deadline then
        stop("Scan timed out waiting for auction data. Try /wmax scan again.")
        return
    end

    local task = scan.tasks[scan.taskIndex]
    if now >= scan.nextProgressAt then
        if task.discovery then
            addon:Print("Searching writ listings. Waiting for auction data...")
        else
            addon:Print("Scan progress: " .. (scan.taskIndex - 2) .. " checks completed; checking " .. task.name .. ".")
        end

        scan.nextProgressAt = now + progressInterval
    end

    if scan.phase == "queued" then
        if now >= nextRequestAt and AH.IsThrottledMessageSystemReady() then
            scan.phase = "waiting"
            scan.deadline = now + timeout
            nextRequestAt = now + requestInterval
            sending = true
            local ok = pcall(sendRequest, task)
            sending = false
            if not ok then
                stop("Auction search failed. Try /wmax scan again.")
            end
        end

        return
    end

    if scan.phase ~= "reading" then
        return
    end

    local complete
    if task.kind == "browse" then
        complete = AH.HasFullBrowseResults()
    elseif task.commodity then
        complete = AH.HasFullCommoditySearchResults(task.key.itemID)
    else
        complete = AH.HasFullItemSearchResults(task.key)
    end

    if not complete then
        queueRequest(true)
        return
    end

    -- Read cumulative caches only after all pages arrive to avoid double counting.
    local read = task.kind == "browse" and readBrowse or readSearch
    if read(task) then
        nextTask()
    end
end)
