local testing = dofile('tests/testing.lua')
local tests = {}

local addon, frame, snapshot, requests, shown, now, serverTime, hooks, reads, requestedItems
local failRequest

local function setup(saved)
    addon = { messages = {} }
    function addon:Print(message) self.messages[#self.messages + 1] = message end
    function addon:ShowResults(rows) shown = rows end

    snapshot, requests, shown, now, serverTime = {}, 0, nil, 0, 100000
    hooks, reads, requestedItems, failRequest = {}, 0, {}, false
    CheapWritsDB = saved or {}
    function GetTime() return now end
    function GetServerTime() return serverTime end
    function GetLocale() return "enUS" end
    function debugprofilestop() return 0 end
    function CreateFrame()
        frame = { scripts = {}, events = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:SetScript(event, handler) self.scripts[event] = handler end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        return frame
    end
    function hooksecurefunc(target, method, callback) hooks[method] = callback end

    C_Item = { RequestLoadItemDataByID = function(id) requestedItems[id] = (requestedItems[id] or 0) + 1 end }
    C_AuctionHouse = {
        ReplicateItems = function()
            if failRequest then error("request failed") end

            requests = requests + 1
            if hooks.ReplicateItems then hooks.ReplicateItems() end
        end,
        GetNumReplicateItems = function() return #snapshot end,
        GetReplicateItemInfo = function(index)
            reads = reads + 1
            local row = assert(snapshot[index + 1], "Snapshot indices are zero-based")
            -- Match the live API tuple, including distracting bid/owner fields.
            return row.name, 123, row.quantity, 1, true, 1, nil,
                1, 2, row.buyout, 3, "Bidder", "Bidder-Realm", "Owner", "Owner-Realm",
                row.sold and 1 or 0, row.itemID or index, false
        end,
        GetReplicateItemLink = function(index) return snapshot[index + 1].link end,
        SendBrowseQuery = function() error("Snapshot scan must not browse") end,
        SendSearchQuery = function() error("Snapshot scan must not search individual items") end,
    }
    assert(loadfile("CheapWrits/Writs.lua"))("CheapWrits", addon)
    assert(loadfile("CheapWrits/Prices.lua"))("CheapWrits", addon)
    assert(loadfile("CheapWrits/Auction.lua"))("CheapWrits", addon)
end

local itemIDs = {
    ["Golden Rod"] = 11128, ["Craftsman's Writ: Golden Rod"] = 264021,
    ["Crafted Solid Shot"] = 8069, ["Craftsman's Writ: Crafted Solid Shot"] = 264037,
    ["Barbaric Gloves"] = 4254, ["Craftsman's Writ: Barbaric Gloves"] = 264045,
}

local function listing(name, quantity, buyout)
    return { name = name, quantity = quantity, buyout = buyout, itemID = itemIDs[name] }
end

local function event(name) frame.scripts.OnEvent(frame, name) end
local function tick(seconds)
    seconds = seconds or 0.1
    now, serverTime = now + seconds, serverTime + seconds
    if frame.shown then frame.scripts.OnUpdate(frame) end
end

local function finish()
    for _ = 1, 100 do
        if not frame.shown then return end
        tick()
    end
    error("Scan did not finish")
end

local function messageContains(text)
    for _, message in ipairs(addon.messages) do
        if message:find(text, 1, true) then return true end
    end
    return false
end

tests['snapshot scan replay and cooldown lifecycle'] = function()
    setup()
    addon:StartScan()
    assert(requests == 0 and messageContains("Open the auction house"))
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    assert(requests == 1 and frame.shown)
    addon:StartScan()
    assert(requests == 1 and messageContains("already in progress"))
    assert(reads == 0)
    tick(5)
    assert(messageContains("Waiting for auction snapshot"))
    assert(reads == 0, "Must wait for the snapshot event, not read a stale cache")

    snapshot = {
        listing("Craftsman's Writ: Golden Rod", 1, 100),
        listing("Craftsman's Writ: Golden Rod", 1, 80),
        listing("Golden Rod", 2, 600),
        listing("Recipe: Golden Rod", 1, 1),
        listing("Craftsman's Writ: Crafted Solid Shot", 1, 25),
        listing("Crafted Solid Shot", 100, 100),
        listing("Crafted Solid Shot", 150, 450),
        listing("Sealed Journeyman's Writ", 1, 1),
        listing("Craftsman's Writ: Barbaric Gloves", 1, 0),
        listing("Barbaric Gloves", 1, 10),
    }
    local sold = listing("Golden Rod", 1, 1)
    sold.sold = true
    snapshot[#snapshot + 1] = sold
    event("REPLICATE_ITEM_LIST_UPDATE")
    event("REPLICATE_ITEM_LIST_UPDATE") -- Duplicate notifications must not double count.
    finish()
    assert(requests == 1 and #shown == 3)
    assert(shown[2].itemName == "Crafted Solid Shot" and shown[2].total == 425)
    assert(shown[2].reputation == 75 and shown[2].costPer100Rep == 425 * 100 / 75)
    assert(shown[1].itemName == "Golden Rod" and shown[1].total == 380)
    assert(shown[3].total == nil)
    assert(addon.scannedAt == 0)
    assert(CheapWritsDB.snapshot.requestedAt == 100000)
    assert(#CheapWritsDB.snapshot.listings == 10)
    assert(CheapWritsDB.snapshot.listings[1].icon == 123)
    assert(CheapWritsDB.snapshot.listings[2].itemID == 264021)
    assert(shown[1].writIcon == 123 and shown[1].itemIcon == 123)
    local oldResults = shown
    local messageCount = #addon.messages
    tick(5)
    assert(#addon.messages == messageCount)
    addon:StartScan()
    assert(requests == 1 and messageContains("cooldown") and shown == oldResults)

    -- The cooldown survives reloads, and a new request is allowed once it expires.
    local saved = CheapWritsDB
    setup(saved)
    serverTime = 100120
    local lastRequest = CheapWritsDB.lastSnapshotRequestAt
    addon:ReplayScan()
    assert(requests == 0 and reads == 0 and #shown == 3)
    assert(shown[2].total == 425 and shown[1].total == 380)
    assert(shown[2].reputation == 75 and shown[2].costPer100Rep == 425 * 100 / 75)
    assert(shown[1].writIcon == 123 and shown[1].itemIcon == 123)
    assert(addon.scannedAt == -120, "Replay must preserve the snapshot's original age")
    assert(CheapWritsDB.lastSnapshotRequestAt == lastRequest)
    local calculate = addon.Prices.BuildRows
    local recalculated = false
    addon.Prices.BuildRows = function(listings)
        recalculated = true
        return calculate(listings)
    end
    addon:ReplayScan()
    assert(recalculated and requests == 0 and reads == 0)
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    assert(requests == 0 and messageContains("cooldown"))
    tick(901)
    addon:StartScan()
    assert(requests == 1)
    event("REPLICATE_ITEM_LIST_UPDATE")
    finish()
    assert(shown and #shown == 0)
end

tests['large snapshots yield across frames and report progress'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    for index = 1, 2000 do snapshot[index] = listing("Unrelated Item", 1, 5) end
    snapshot[2001] = listing("Craftsman's Writ: Golden Rod", 1, 100)
    snapshot[2002] = listing("Golden Rod", 1, 300)
    event("REPLICATE_ITEM_LIST_UPDATE")
    assert(reads == 0, "Event handler must not process the full snapshot")
    tick(5)
    assert(frame.shown and reads > 0 and reads < #snapshot)
    tick(5)
    assert(messageContains("listings processed"))
    finish()
    assert(#shown == 1 and shown[1].total == 400)
end

tests['expensive API reads yield within the time budget'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    for index = 1, 100 do snapshot[index] = listing("Unrelated Item", 1, 5) end
    event("REPLICATE_ITEM_LIST_UPDATE")
    local profileTime = 0
    function debugprofilestop()
        profileTime = profileTime + 2
        return profileTime
    end
    tick()
    assert(frame.shown and reads == 1)
    function debugprofilestop() return 0 end
    finish()
    assert(#shown == 0)
end

tests['missing names defer publishing and request item data once'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    snapshot = { listing(nil, 1, 100), listing("Golden Rod", 1, 300) }
    snapshot[1].itemID = 264021
    event("REPLICATE_ITEM_LIST_UPDATE")
    tick()
    assert(not shown and requestedItems[264021] == 1)
    tick()
    assert(not shown and requestedItems[264021] == 1)
    snapshot[1].name = "Craftsman's Writ: Golden Rod"
    finish()
    assert(#shown == 1 and shown[1].total == 400)
end

tests['resolving names out of order does not skip or duplicate rows'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    snapshot = { listing(nil, 1, 100), listing(nil, 1, 300), listing(nil, 1, 200) }
    snapshot[1].itemID, snapshot[2].itemID = 264021, 11128
    event("REPLICATE_ITEM_LIST_UPDATE")
    tick()
    snapshot[2].name = "Golden Rod"
    tick()
    assert(not shown)
    snapshot[1].name = "Craftsman's Writ: Golden Rod"
    snapshot[3].name = "Unrelated Item"
    finish()
    assert(#shown == 1 and shown[1].total == 400)
end

tests['item links supply display names before item data is cached'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    snapshot = { listing(nil, 1, 100), listing("Golden Rod", 1, 300) }
    snapshot[1].itemID = 264021
    snapshot[1].link = "|cffffffff|Hitem:264021::::::::|h[Craftsman's Writ: Golden Rod]|h|r"
    event("REPLICATE_ITEM_LIST_UPDATE")
    finish()
    assert(#shown == 1 and shown[1].total == 400)
end

tests['closing the auction house cancels and ignores late replies'] = {
    cases = { { "AUCTION_HOUSE_CLOSED" }, { "AUCTION_HOUSE_DISABLED" } },
    run = function(closeEvent)
        local oldResults = { { itemID = 11128, total = 400 } }
        local saved = { snapshot = { listings = {} } }

        setup()
        CheapWritsDB.snapshot = saved.snapshot
        addon.results = oldResults
        event("AUCTION_HOUSE_SHOW")
        addon:StartScan()
        event(closeEvent)
        assert(not frame.shown and addon.results == oldResults)
        assert(CheapWritsDB.snapshot == saved.snapshot)
        event("REPLICATE_ITEM_LIST_UPDATE")
        tick(5)
        assert(not shown)
    end,
}

tests['timeouts preserve previous results without retries'] = {
    cases = { { false }, { true } },
    run = function(received)
        local oldResults = { { itemID = 11128, total = 400 } }

        setup()
        addon.results = oldResults
        event("AUCTION_HOUSE_SHOW")
        addon:StartScan()
        if received then
            snapshot = { listing(nil, 1, 100) }
            event("REPLICATE_ITEM_LIST_UPDATE")
            tick()
        end
        tick(121)
        assert(not frame.shown and not shown and addon.results == oldResults)
        assert(messageContains("timed out") and requests == 1)
    end,
}

tests['other snapshot requests share cooldown and cancel active scans'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    C_AuctionHouse.ReplicateItems()
    addon:StartScan()
    assert(requests == 1 and messageContains("cooldown"))
    tick(901)
    addon:StartScan()
    C_AuctionHouse.ReplicateItems()
    assert(not frame.shown and messageContains("another snapshot"))
end

tests['failed snapshot requests do not consume cooldown'] = function()
    setup()
    event("AUCTION_HOUSE_SHOW")
    failRequest = true
    addon:StartScan()
    assert(not frame.shown and messageContains("failed"))
    failRequest = false
    addon:StartScan()
    assert(requests == 1, "A failed call must not consume the local cooldown")
end

tests['replay rejects absent snapshots and active scans'] = function()
    setup()
    addon:ReplayScan()
    assert(not shown and requests == 0 and messageContains("No saved snapshot"))
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    addon:ReplayScan()
    assert(not shown and requests == 1 and messageContains("already in progress"))
end

tests['localized snapshots scan and replay using item IDs'] = function()
    setup()
    function GetLocale() return "deDE" end
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    assert(requests == 1)
    snapshot = {
        { name = "Lokalisierter Auftrag", itemID = 264021, quantity = 1, buyout = 100 },
        { name = "Lokalisierter Gegenstand", itemID = 11128, quantity = 1, buyout = 300 },
    }
    event("REPLICATE_ITEM_LIST_UPDATE")
    finish()
    assert(#shown == 1 and shown[1].total == 400)
    assert(shown[1].itemName == "Lokalisierter Gegenstand")

    local localizedSnapshot = CheapWritsDB
    setup(localizedSnapshot)
    addon:ReplayScan()
    assert(requests == 0 and #shown == 1 and shown[1].total == 400)
    assert(shown[1].itemName == "Lokalisierter Gegenstand")
end

local counts = testing.run_tests(tests)
print(string.format('auction tests passed (%d tests, %d cases)', counts.tests, counts.cases))
