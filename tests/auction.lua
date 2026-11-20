local addon, frame, snapshot, requests, shown, now, serverTime, hooks, reads, requestedItems
local failRequest

local function setup(saved)
    addon = { messages = {} }
    function addon:Print(message) self.messages[#self.messages + 1] = message end
    function addon:ShowResults(rows) shown = rows end

    snapshot, requests, shown, now, serverTime = {}, 0, nil, 0, 100000
    hooks, reads, requestedItems, failRequest = {}, 0, {}, false
    WritMaxxerDB = saved or {}
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
    assert(loadfile("WritMaxxer/Prices.lua"))("WritMaxxer", addon)
    assert(loadfile("WritMaxxer/Auction.lua"))("WritMaxxer", addon)
end

local function listing(name, quantity, buyout)
    return { name = name, quantity = quantity, buyout = buyout }
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
    listing("Craftsman's Writ: Copper Rod", 1, 100),
    listing("Craftsman's Writ: Copper Rod", 1, 80),
    listing("Copper Rod", 2, 600),
    listing("Recipe: Copper Rod", 1, 1),
    listing("Craftsman's Writ: Crafted Solid Shot", 1, 25),
    listing("Crafted Solid Shot", 100, 100),
    listing("Crafted Solid Shot", 150, 450),
    listing("Sealed Journeyman's Writ", 1, 1),
    listing("Craftsman's Writ: Bid Only", 1, 0),
    listing("Bid Only", 1, 10),
}
local sold = listing("Copper Rod", 1, 1)
sold.sold = true
snapshot[#snapshot + 1] = sold
event("REPLICATE_ITEM_LIST_UPDATE")
event("REPLICATE_ITEM_LIST_UPDATE") -- Duplicate notifications must not double count.
finish()
assert(requests == 1 and #shown == 3)
assert(shown[1].itemName == "Copper Rod" and shown[1].total == 380)
assert(shown[2].itemName == "Crafted Solid Shot" and shown[2].total == 425)
assert(shown[3].total == nil)
assert(addon.scannedAt == 0)
assert(WritMaxxerDB.snapshot.requestedAt == 100000)
assert(#WritMaxxerDB.snapshot.listings == 10)
local oldResults = shown
local messageCount = #addon.messages
tick(5)
assert(#addon.messages == messageCount)
addon:StartScan()
assert(requests == 1 and messageContains("cooldown") and shown == oldResults)

-- The cooldown survives reloads, and a new request is allowed once it expires.
local saved = WritMaxxerDB
setup(saved)
serverTime = 100120
local lastRequest = WritMaxxerDB.lastSnapshotRequestAt
addon:ReplayScan()
assert(requests == 0 and reads == 0 and #shown == 3)
assert(shown[1].total == 380 and shown[2].total == 425)
assert(addon.scannedAt == -120, "Replay must preserve the snapshot's original age")
assert(WritMaxxerDB.lastSnapshotRequestAt == lastRequest)
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

-- Large snapshots are processed over multiple frames, with progress updates.
setup()
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
for index = 1, 2000 do snapshot[index] = listing("Unrelated Item", 1, 5) end
snapshot[2001] = listing("Craftsman's Writ: Copper Rod", 1, 100)
snapshot[2002] = listing("Copper Rod", 1, 300)
event("REPLICATE_ITEM_LIST_UPDATE")
assert(reads == 0, "Event handler must not process the full snapshot")
tick(5)
assert(frame.shown and reads > 0 and reads < #snapshot)
tick(5)
assert(messageContains("listings processed"))
finish()
assert(#shown == 1 and shown[1].total == 400)

-- The time budget also yields early when individual API reads are expensive.
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

-- Resolve missing names without silently publishing incomplete prices.
setup()
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
snapshot = { listing(nil, 1, 100), listing("Copper Rod", 1, 300) }
snapshot[1].itemID = 77
event("REPLICATE_ITEM_LIST_UPDATE")
tick()
assert(not shown and requestedItems[77] == 1)
tick()
assert(not shown and requestedItems[77] == 1)
snapshot[1].name = "Craftsman's Writ: Copper Rod"
finish()
assert(#shown == 1 and shown[1].total == 400)

-- Resolving a later missing name must not skip or count other pending rows twice.
setup()
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
snapshot = { listing(nil, 1, 100), listing(nil, 1, 300), listing(nil, 1, 200) }
event("REPLICATE_ITEM_LIST_UPDATE")
tick()
snapshot[2].name = "Copper Rod"
tick()
assert(not shown)
snapshot[1].name = "Craftsman's Writ: Copper Rod"
snapshot[3].name = "Unrelated Item"
finish()
assert(#shown == 1 and shown[1].total == 400)

-- A link can provide the exact display name before item data is cached.
setup()
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
snapshot = { listing(nil, 1, 100), listing("Copper Rod", 1, 300) }
snapshot[1].link = "|cffffffff|Hitem:77::::::::|h[Craftsman's Writ: Copper Rod]|h|r"
event("REPLICATE_ITEM_LIST_UPDATE")
finish()
assert(#shown == 1 and shown[1].total == 400)

-- Closing or disabling the AH cancels; late replies do not publish results.
for _, closeEvent in ipairs({ "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_DISABLED" }) do
    setup()
    WritMaxxerDB.snapshot = saved.snapshot
    addon.results = oldResults
    event("AUCTION_HOUSE_SHOW")
    addon:StartScan()
    event(closeEvent)
    assert(not frame.shown and addon.results == oldResults)
    assert(WritMaxxerDB.snapshot == saved.snapshot)
    event("REPLICATE_ITEM_LIST_UPDATE")
    tick(5)
    assert(not shown)
end

-- Timeout and unresolved names preserve previous results; no automatic retries.
for _, received in ipairs({ false, true }) do
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
end

-- Other snapshot requests consume the same cooldown and cannot replace an active scan.
setup()
event("AUCTION_HOUSE_SHOW")
C_AuctionHouse.ReplicateItems()
addon:StartScan()
assert(requests == 1 and messageContains("cooldown"))
tick(901)
addon:StartScan()
C_AuctionHouse.ReplicateItems()
assert(not frame.shown and messageContains("another snapshot"))

setup()
event("AUCTION_HOUSE_SHOW")
failRequest = true
addon:StartScan()
assert(not frame.shown and messageContains("failed"))
failRequest = false
addon:StartScan()
assert(requests == 1, "A failed call must not consume the local cooldown")

setup()
addon:ReplayScan()
assert(not shown and requests == 0 and messageContains("No saved snapshot"))
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
addon:ReplayScan()
assert(not shown and requests == 1 and messageContains("already in progress"))

setup()
function GetLocale() return "deDE" end
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
assert(requests == 0 and messageContains("English"))

print("Snapshot auction lifecycle tests passed")
