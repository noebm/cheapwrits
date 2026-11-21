local _, addon = ...

local Prices = {}
addon.Prices = Prices

-- Estimate the cost of a quantity from available buyout tiers. Buyouts are
-- listing totals; prorating assumes units can be bought separately.
local function quantityCost(listings, quantity)
    if not listings then
        return nil
    end

    table.sort(listings, function(a, b)
        return a.buyout / a.quantity < b.buyout / b.quantity
    end)

    local remaining, cost = quantity, 0
    for _, listing in ipairs(listings) do
        local take = math.min(remaining, listing.quantity)
        cost = cost + take * listing.buyout / listing.quantity
        remaining = remaining - take

        if remaining == 0 then
            return math.ceil(cost)
        end
    end

    return nil
end

local function compareRows(a, b)
    if a.costPer100Rep ~= b.costPer100Rep then
        if not a.costPer100Rep then return false end
        if not b.costPer100Rep then return true end

        return a.costPer100Rep < b.costPer100Rep
    end

    if a.availableTurnIns ~= b.availableTurnIns then
        return a.availableTurnIns > b.availableTurnIns
    end

    return a.writName < b.writName
end

function Prices.BuildRows(listings)
    local byID, writs, stock, metadata = {}, {}, {}, {}
    for _, listing in ipairs(listings) do
        local itemID = listing.itemID
        if itemID and itemID > 0 and listing.quantity and listing.quantity > 0 then
            metadata[itemID] = metadata[itemID] or {}
            metadata[itemID].name = metadata[itemID].name or listing.name
            metadata[itemID].icon = metadata[itemID].icon or listing.icon

            if addon.Writs[itemID] then
                writs[itemID] = addon.Writs[itemID]
            end

            if listing.buyout and listing.buyout > 0 then
                byID[itemID] = byID[itemID] or {}
                table.insert(byID[itemID], listing)
                stock[itemID] = (stock[itemID] or 0) + listing.quantity
            end
        end
    end

    local rows = {}
    for writItemID, writ in pairs(writs) do
        local itemID, quantity = writ.itemID, writ.quantity
        local writCost = quantityCost(byID[writItemID], 1)
        local itemCost = quantityCost(byID[itemID], quantity)
        local total = writCost and itemCost and (writCost + itemCost) or nil
        local reputation = writ.reputation
        local writInfo, itemInfo = metadata[writItemID] or {}, metadata[itemID] or {}

        rows[#rows + 1] = {
            writName = writInfo.name or tostring(writItemID),
            itemName = itemInfo.name or tostring(itemID),
            quantity = quantity,
            writStock = stock[writItemID] or 0,
            itemStock = stock[itemID] or 0,
            writItemID = writItemID,
            itemID = itemID,
            writIcon = writInfo.icon,
            itemIcon = itemInfo.icon,
            itemUnitCost = quantityCost(byID[itemID], 1),
            costPerRep = total and reputation and (total / reputation) or nil,
            availableTurnIns = math.min(stock[writItemID] or 0, math.floor((stock[itemID] or 0) / quantity)),
            writCost = writCost,
            itemCost = itemCost,
            total = total,
            reputation = reputation,
            costPer100Rep = total and reputation and (total * 100 / reputation) or nil,
        }
    end

    table.sort(rows, compareRows)

    return rows
end
