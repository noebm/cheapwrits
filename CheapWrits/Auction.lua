local _, addon = ...

-- Snapshot indices are zero-based. Buyouts are listing totals, not unit prices.
-- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua
local AH = C_AuctionHouse
local frame = CreateFrame("Frame")
local auctionOpen, requesting = false, false
local scan
local snapshotCooldown = 15 * 60
local timeout = 120
local progressInterval = 5
local rowsPerFrame = 500
local frameBudgetMs = 4

frame:Hide()
for _, event in ipairs({
    "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_DISABLED",
    "REPLICATE_ITEM_LIST_UPDATE",
}) do
    frame:RegisterEvent(event)
end

local function stop(message)
    scan = nil
    frame:Hide()

    if message then
        addon:Print(message)
    end
end

-- Snapshot requests from any addon share the server cooldown and replace the cache.
hooksecurefunc(AH, "ReplicateItems", function()
    CheapWritsDB = CheapWritsDB or {}
    CheapWritsDB.lastSnapshotRequestAt = GetServerTime()

    if scan and not requesting then
        stop("Scan cancelled because another snapshot was requested.")
    end
end)

function addon:StartScan()
    if not auctionOpen then
        self:Print("Open the auction house first, then use /cwr scan.")
        return
    end

    if scan then
        self:Print("A scan is already in progress.")
        return
    end

    CheapWritsDB = CheapWritsDB or {}
    local lastRequest = CheapWritsDB.lastSnapshotRequestAt
    local remaining = lastRequest and (snapshotCooldown - (GetServerTime() - lastRequest)) or 0
    if remaining > 0 then
        self:Print("Snapshot cooldown: try again in " .. math.ceil(remaining / 60)
            .. " minutes. Use /cwr replay to recalculate the saved snapshot.")
        return
    end

    local now = GetTime()
    scan = {
        phase = "waiting",
        listings = {},
        pending = {},
        requestedItems = {},
        startedAt = now,
        requestedAt = GetServerTime(),
        deadline = now + timeout,
        nextProgressAt = now + progressInterval,
    }
    frame:Show()
    self:Print("Requesting auction snapshot. Keep the auction house open until the scan finishes.")

    requesting = true
    local ok = pcall(AH.ReplicateItems)
    requesting = false
    if not ok then
        stop("Snapshot request failed. Try /cwr scan again.")
    end
end

function addon:ReplayScan()
    if scan then
        self:Print("A scan is already in progress.")
        return
    end

    local snapshot = CheapWritsDB and CheapWritsDB.snapshot
    if not snapshot or snapshot.version ~= 1 then
        self:Print("No saved snapshot. Open the auction house and use /cwr scan first.")
        return
    end

    local age = math.max(0, GetServerTime() - snapshot.requestedAt)
    self.results = self.Prices.BuildRows(snapshot.listings)
    self.scannedAt = GetTime() - age
    self:Print("Replayed saved snapshot (" .. math.floor(age / 60) .. " minutes old): "
        .. #self.results .. " writs found.")
    self:ShowResults(self.results)
end

local function readListing(index)
    local name, icon, quantity, _, _, _, _, _, _, buyout, _, _, _, _, _, saleStatus, itemID = AH.GetReplicateItemInfo(index)
    if saleStatus ~= 0 or not quantity or quantity <= 0 then
        return true
    end

    if not name or name == "" then
        local link = AH.GetReplicateItemLink(index)
        name = link and link:match("%[(.-)%]")
    end

    if not name or name == "" then
        if itemID and itemID > 0 and not scan.requestedItems[itemID] then
            scan.requestedItems[itemID] = true
            C_Item.RequestLoadItemDataByID(itemID)
        end

        return false
    end

    scan.listings[#scan.listings + 1] = {
        name = name, quantity = quantity, buyout = buyout,
        itemID = itemID, icon = icon,
    }
    return true
end

frame:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        auctionOpen = true
    elseif event == "AUCTION_HOUSE_CLOSED" or event == "AUCTION_HOUSE_DISABLED" then
        auctionOpen = false
        if scan then
            stop("Scan cancelled because the auction house closed or became unavailable.")
        end
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" and scan and scan.phase == "waiting" then
        scan.phase = "reading"
        scan.total = AH.GetNumReplicateItems()
        scan.index = 0
        scan.deadline = GetTime() + timeout
        addon:Print("Snapshot received: " .. scan.total .. " listings. Reading prices...")
    end
end)

frame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now >= scan.deadline then
        stop("Snapshot scan timed out waiting for auction or item data. The server may still be on its 15-minute snapshot cooldown.")
        return
    end

    if now >= scan.nextProgressAt then
        if scan.phase == "waiting" then
            addon:Print("Waiting for auction snapshot...")
        else
            addon:Print("Scan progress: " .. scan.index .. "/" .. scan.total .. " listings processed; "
                .. #scan.pending .. " waiting for item names.")
        end

        scan.nextProgressAt = now + progressInterval
    end

    if scan.phase == "waiting" then
        return
    end

    local started = debugprofilestop()
    local processed = 0
    if scan.phase == "reading" then
        while scan.index < scan.total and processed < rowsPerFrame and debugprofilestop() - started < frameBudgetMs do
            if not readListing(scan.index) then
                scan.pending[#scan.pending + 1] = scan.index
            end

            scan.index = scan.index + 1
            processed = processed + 1
        end

        if scan.index < scan.total then
            return
        end

        scan.phase = "resolving"
        scan.pendingIndex = #scan.pending
        scan.deadline = now + timeout
    end

    while scan.pendingIndex > 0 and processed < rowsPerFrame and debugprofilestop() - started < frameBudgetMs do
        local position = scan.pendingIndex
        if readListing(scan.pending[position]) then
            scan.pending[position] = scan.pending[#scan.pending]
            scan.pending[#scan.pending] = nil
        end

        scan.pendingIndex = position - 1
        processed = processed + 1
    end

    if #scan.pending > 0 then
        if scan.pendingIndex == 0 then
            scan.pendingIndex = #scan.pending
        end

        return
    end

    addon.results = addon.Prices.BuildRows(scan.listings)
    addon.scannedAt = scan.startedAt
    CheapWritsDB.snapshot = {
        version = 1,
        requestedAt = scan.requestedAt,
        listings = scan.listings,
    }
    stop()
    addon:Print("Snapshot scan complete: " .. #addon.results .. " writs found. Prices are estimates from this snapshot.")
    addon:ShowResults(addon.results)
end)
