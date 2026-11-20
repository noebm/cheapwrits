local _, addon = ...

local Prices = {}
addon.Prices = Prices

-- English writ titles identify the finished item. Most require one item;
-- ammunition is the known exception. Quantity reference:
-- https://aidvir.github.io/wow-forever-favor/writs.html
local requiredQuantities = { ["Crafted Solid Shot"] = 200 }
Prices.WritSearch = "Craftsman's Writ:"

function Prices.GetRequiredItemName(writName)
    local prefix = Prices.WritSearch .. " "
    if writName:sub(1, #prefix) == prefix and #writName > #prefix then
        return writName:sub(#prefix + 1)
    end

    return nil
end

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
    local byName, writs, stock = {}, {}, {}
    for _, listing in ipairs(listings) do
        local name = listing.name
        if name and listing.quantity and listing.quantity > 0 then
            local itemName = Prices.GetRequiredItemName(name)
            if itemName then
                writs[name] = itemName
            end

            if listing.buyout and listing.buyout > 0 then
                byName[name] = byName[name] or {}
                table.insert(byName[name], listing)
                stock[name] = (stock[name] or 0) + listing.quantity
            end
        end
    end

    local rows = {}
    for writName, itemName in pairs(writs) do
        local quantity = requiredQuantities[itemName] or 1
        local writCost = quantityCost(byName[writName], 1)
        local itemCost = quantityCost(byName[itemName], quantity)
        local total = writCost and itemCost and (writCost + itemCost) or nil
        local reputation = addon.WritReputation[itemName]

        rows[#rows + 1] = {
            writName = writName,
            itemName = itemName,
            quantity = quantity,
            availableTurnIns = math.min(stock[writName] or 0, math.floor((stock[itemName] or 0) / quantity)),
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
