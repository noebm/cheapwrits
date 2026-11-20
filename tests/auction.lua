local addon = { messages = {} }
function addon:Print(message)
    self.messages[#self.messages + 1] = message
end

local now, ready, locale = 0, true, "enUS"
local frame, completed
local calls, infos, browse = {}, {}, {}
local itemResults, commodityResults = {}, {}
local fullBrowse, fullItems, fullCommodities = true, true, true
local hooks, requestedItems = {}, {}

function GetTime() return now end
function GetLocale() return locale end
function CreateFrame()
    frame = { scripts = {} }
    function frame:RegisterEvent() end
    function frame:SetScript(event, handler) self.scripts[event] = handler end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    return frame
end

function hooksecurefunc(target, method, callback)
    hooks[method] = callback
end

local function record(method, argument)
    calls[#calls + 1] = { method = method, argument = argument, at = now }
    if hooks[method] then hooks[method]() end
end

C_Item = { RequestLoadItemDataByID = function(itemID) requestedItems[itemID] = true end }
C_AuctionHouse = {
    -- Any accidental full scan fails this test immediately.
    ReplicateItems = function() error("Full AH scans are forbidden") end,
    IsThrottledMessageSystemReady = function() return ready end,
    SendBrowseQuery = function(query) record("SendBrowseQuery", query.searchString) end,
    RequestMoreBrowseResults = function() record("RequestMoreBrowseResults") end,
    GetBrowseResults = function() return browse end,
    HasFullBrowseResults = function() return fullBrowse end,
    GetItemKeyInfo = function(itemKey) return infos[itemKey.itemID] end,
    SendSearchQuery = function(itemKey) record("SendSearchQuery", itemKey.itemID) end,
    RequestMoreItemSearchResults = function(itemKey) record("RequestMoreItemSearchResults", itemKey.itemID) end,
    RequestMoreCommoditySearchResults = function(id) record("RequestMoreCommoditySearchResults", id) end,
    HasFullItemSearchResults = function() return fullItems end,
    HasFullCommoditySearchResults = function() return fullCommodities end,
    GetNumItemSearchResults = function() return #itemResults end,
    GetNumCommoditySearchResults = function() return #commodityResults end,
    GetItemSearchResultInfo = function(_, index) return itemResults[index] end,
    GetCommoditySearchResultInfo = function(_, index) return commodityResults[index] end,
}

function addon:ShowResults(rows) completed = rows end
assert(loadfile("WritMaxxer/Prices.lua"))("WritMaxxer", addon)
assert(loadfile("WritMaxxer/Auction.lua"))("WritMaxxer", addon)

local function key(id, suffix)
    return { itemID = id, itemLevel = 0, itemSuffix = suffix or 0, battlePetSpeciesID = 0 }
end

local function register(id, name, commodity)
    infos[id] = { itemName = name, isCommodity = commodity or false }
    return { itemKey = key(id), totalQuantity = 1, minPrice = 1 }
end

local function event(name, argument) frame.scripts.OnEvent(frame, name, argument) end
local function tick(seconds)
    now = now + (seconds or 1)
    if frame.shown then frame.scripts.OnUpdate(frame) end
end

local function lastCall(method, argument)
    local call = calls[#calls]
    assert(call and call.method == method, "Expected " .. method)
    assert(call.argument == argument, tostring(call.argument) .. " ~= " .. tostring(argument))
end

local writ = register(10, "Craftsman's Writ: Copper Rod")
local shotWrit = register(20, "Craftsman's Writ: Crafted Solid Shot", true)
local rod = register(30, "Copper Rod")
local shot = register(40, "Crafted Solid Shot", true)
local recipe = register(50, "Recipe: Copper Rod")
local envelope = register(60, "Sealed Journeyman's Writ")

-- Wait for the AH and throttle readiness. Ignore stale results before sending.
addon:StartScan()
assert(#calls == 0)
event("AUCTION_HOUSE_SHOW")
ready = false
addon:StartScan()
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
assert(#calls == 0)
ready = true
tick()
lastCall("SendBrowseQuery", "Writ:")
addon:StartScan()
assert(#calls == 1)

-- Browse every writ page before queuing searches; overlapping pages deduplicate.
browse, fullBrowse = { writ }, false
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick(0)
tick(0.2)
assert(#calls == 1) -- Readiness alone must not bypass the local rate limit.
tick(0.5)
lastCall("RequestMoreBrowseResults")
browse, fullBrowse = { writ, writ, shotWrit, recipe, envelope }, true
event("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
tick()
tick()
lastCall("SendSearchQuery", 10)

-- Wrong item keys and item IDs cannot complete the current request.
local callCount = #calls
event("ITEM_SEARCH_RESULTS_UPDATED", key(10, 7))
event("COMMODITY_SEARCH_RESULTS_UPDATED", 10)
tick()
assert(#calls == callCount and completed == nil)

-- Individual-item prices come from buyouts, not browse minimums or bids.
itemResults, fullItems = { { itemKey = key(10), quantity = 1, buyoutAmount = 100 } }, false
event("ITEM_SEARCH_RESULTS_UPDATED", key(10))
tick()
tick()
lastCall("RequestMoreItemSearchResults", 10)
itemResults, fullItems = {
    { itemKey = key(10), quantity = 1, buyoutAmount = 100 },
    { itemKey = key(10), quantity = 1, buyoutAmount = 80 },
    { itemKey = key(10), quantity = 1, minBid = 1 },
}, true
event("ITEM_SEARCH_RESULTS_ADDED", key(10))
tick()
tick()
lastCall("SendSearchQuery", 20)
commodityResults = { { quantity = 10, unitPrice = 25 } }
event("COMMODITY_SEARCH_RESULTS_UPDATED", 999)
tick()
assert(completed == nil)
event("COMMODITY_SEARCH_RESULTS_UPDATED", 20)
tick()
tick()
lastCall("SendBrowseQuery", "Copper Rod")

-- Resolve uncached names before filtering exact matches. Recipe is never searched.
infos[30] = nil
browse = { rod, rod, recipe }
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
assert(requestedItems[30])
register(30, "Copper Rod")
tick()
tick()
lastCall("SendBrowseQuery", "Crafted Solid Shot")
browse = { shot }
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
tick()
lastCall("SendSearchQuery", 30)
itemResults = { { itemKey = key(30), quantity = 1, buyoutAmount = 300 } }
event("ITEM_SEARCH_RESULTS_UPDATED", key(30))
tick()
tick()
lastCall("SendSearchQuery", 40)

-- Commodity pages are cumulative; price tiers must not be counted twice.
commodityResults, fullCommodities = { { quantity = 100, unitPrice = 1 } }, false
event("COMMODITY_SEARCH_RESULTS_UPDATED", 40)
tick()
tick()
lastCall("RequestMoreCommoditySearchResults", 40)
commodityResults, fullCommodities = {
    { quantity = 100, unitPrice = 1 }, { quantity = 100, unitPrice = 3 },
}, true
event("COMMODITY_SEARCH_RESULTS_ADDED", 40)
tick()
assert(not frame.shown and #completed == 2)
assert(completed[1].itemName == "Copper Rod" and completed[1].total == 380)
assert(completed[2].itemName == "Crafted Solid Shot" and completed[2].total == 425)
for index = 2, #calls do
    assert(calls[index].at - calls[index - 1].at >= 0.7)
end

-- No full-scan cooldown. A dropped request is retried after readiness.
addon:StartScan()
tick()
lastCall("SendBrowseQuery", "Writ:")
event("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
callCount = #calls
ready = false
tick()
assert(#calls == callCount)
ready = true
tick()
assert(#calls == callCount + 1)
lastCall("SendBrowseQuery", "Writ:")

-- External searches cancel; old results survive and late replies are ignored.
local oldResults = completed
C_AuctionHouse.SendBrowseQuery({ searchString = "Unrelated" })
assert(not frame.shown)
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
assert(completed == oldResults)

addon:StartScan()
tick()
event("AUCTION_HOUSE_CLOSED")
assert(not frame.shown and completed == oldResults)
event("AUCTION_HOUSE_SHOW")
addon:StartScan()
tick()
tick(61)
assert(not frame.shown and completed == oldResults)
assert(addon.messages[#addon.messages]:find("timed out"))

addon:StartScan()
tick()
event("AUCTION_HOUSE_BROWSE_FAILURE")
assert(not frame.shown and completed == oldResults)

-- An empty discovery replaces previous results without any detail searches.
addon:StartScan()
tick()
browse = {}
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
assert(not frame.shown and #completed == 0)

-- Disappearing writ auctions and missing required items remain unavailable.
addon:StartScan()
tick()
browse = { writ }
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
tick()
lastCall("SendSearchQuery", 10)
itemResults = {}
event("ITEM_SEARCH_RESULTS_UPDATED", key(10))
tick()
tick()
lastCall("SendBrowseQuery", "Copper Rod")
browse = {}
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
assert(not frame.shown and #completed == 1)
assert(completed[1].writCost == nil and completed[1].itemCost == nil)
assert(completed[1].total == nil)
oldResults = completed

-- Unresolved item information fails without publishing an incomplete scan.
addon:StartScan()
tick()
browse, infos[10] = { writ }, nil
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tick()
tick(61)
assert(not frame.shown and completed == oldResults)
register(10, "Craftsman's Writ: Copper Rod")

-- Retrying dropped messages is bounded.
addon:StartScan()
tick()
for _ = 1, 3 do
    event("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
    tick()
    assert(frame.shown)
end
event("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
assert(not frame.shown and completed == oldResults)

locale = "deDE"
callCount = #calls
addon:StartScan()
tick()
assert(#calls == callCount)
assert(addon.messages[#addon.messages]:find("English"))

print("Targeted auction lifecycle tests passed")
