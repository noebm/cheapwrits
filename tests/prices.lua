local addon = {}
assert(loadfile("WritMaxxer/Writs.lua"))("WritMaxxer", addon)
assert(loadfile("WritMaxxer/Prices.lua"))("WritMaxxer", addon)

local function listing(itemID, name, quantity, buyout, icon)
    return { itemID = itemID, name = name, quantity = quantity, buyout = buyout, icon = icon }
end

local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end

-- IDs determine identity even when names are localized, equal, or misleading.
local rows = addon.Prices.BuildRows({
    listing(264021, "Auftrag", 1, 200, 123),
    listing(264021, "Auftrag", 1, 100),
    listing(11128, "Goldrute", 1, 300, 456),
    listing(999, "Goldrute", 100, 1),
    listing(998, "Craftsman's Writ: Golden Rod", 1, 1),
    listing(nil, "Craftsman's Writ: Golden Rod", 1, 1),
    listing(264012, "Auftrag", 1, 50),
    listing(3383, "Weisheit", 1, 100),
})
equal(#rows, 2)
equal(rows[1].itemID, 3383)
equal(rows[1].total, 150)
equal(rows[2].itemName, "Goldrute")
equal(rows[2].writCost, 100)
equal(rows[2].itemCost, 300)
equal(rows[2].quantity, 1)
equal(rows[2].total, 400)
equal(rows[2].writStock, 2)
equal(rows[2].itemStock, 1)
equal(rows[2].writItemID, 264021)
equal(rows[2].writIcon, 123)
equal(rows[2].itemIcon, 456)
equal(#addon.Prices.BuildRows({}), 0)

-- No buyout, missing items, and insufficient stock have no complete cost.
rows = addon.Prices.BuildRows({
    listing(264021, "Rod writ", 1, 10),
    listing(264012, "Wisdom writ", 1, 0),
    listing(3383, "Wisdom", 1, 10),
    listing(264037, "Ammo writ", 1, 10),
    listing(8069, "Ammo", 199, 199),
})
equal(#rows, 3)
for _, row in ipairs(rows) do
    equal(row.total, nil)
    equal(row.availableTurnIns, 0)
    if row.itemID == 11128 then
        equal(row.itemName, "11128")
    end
end

-- Quantities consume price tiers; bid-only stock is excluded.
rows = addon.Prices.BuildRows({
    listing(264037, "Ammo writ", 3, 75, 134939),
    listing(8069, "Ammo", 100, 100, 132384),
    listing(8069, "Ammo", 150, 450),
    listing(8069, "Ammo", 100, 0),
})
equal(rows[1].quantity, 200)
equal(rows[1].itemCost, 400)
equal(rows[1].itemUnitCost, 1)
equal(rows[1].total, 425)
equal(rows[1].itemStock, 250)
equal(rows[1].availableTurnIns, 1)
equal(rows[1].costPerRep, 425 / 75)

-- Availability counts complete ammunition batches across listings.
rows = addon.Prices.BuildRows({
    listing(264037, "Ammo writ", 5, 125),
    listing(8069, "Ammo", 199, 199),
    listing(8069, "Ammo", 400, 400),
})
equal(rows[1].availableTurnIns, 2)

-- Stack estimates round to copper; fractional reputation values stay precise.
rows = addon.Prices.BuildRows({
    listing(264021, "Rod writ", 2, 101), listing(11128, "Rod", 2, 201),
})
equal(rows[1].writCost, 51)
equal(rows[1].itemCost, 101)
equal(rows[1].total, 152)

rows = addon.Prices.BuildRows({
    listing(264012, "Wisdom writ", 1, 1), listing(3383, "Wisdom", 1, 1),
    listing(264067, "Stoneshield writ", 1, 1), listing(9144, "Stoneshield", 1, 2),
})
equal(rows[1].reputation, 125)
equal(rows[1].costPer100Rep, 2.4)
equal(rows[2].reputation, 75)

-- Rank rewards determine value; availability and display name break ties.
rows = addon.Prices.BuildRows({
    listing(264012, "Wisdom writ", 1, 100), listing(3383, "Wisdom", 1, 650),
    listing(264067, "Stoneshield writ", 1, 250), listing(9144, "Stoneshield", 1, 750),
    listing(264116, "Demon writ", 1, 300), listing(9224, "Demon", 1, 1200),
})
equal(rows[1].reputation, 200)
equal(rows[1].costPer100Rep, 750)
equal(rows[2].costPer100Rep, 800)
equal(rows[3].costPer100Rep, 1000)

rows = addon.Prices.BuildRows({
    listing(264012, "Z writ", 2, 100), listing(3383, "Wisdom", 10, 250),
    listing(264067, "A writ", 4, 200), listing(9144, "Stoneshield", 3, 225),
    listing(9144, "Stoneshield", 100, 0), listing(264067, "A writ", 100, 0),
})
equal(rows[1].availableTurnIns, 3)
equal(rows[1].costPer100Rep, 100)
equal(rows[2].availableTurnIns, 2)

rows = addon.Prices.BuildRows({
    listing(264012, "Z writ", 1, 25), listing(3383, "Wisdom", 1, 50),
    listing(264037, "A writ", 1, 25), listing(8069, "Ammo", 200, 50),
})
equal(rows[1].itemID, 8069)
equal(rows[2].itemID, 3383)

-- Every supported writ has valid identity, quantity, and base reputation data.
local count = 0
for writID, writ in pairs(addon.Writs) do
    assert(type(writID) == "number" and type(writ.itemID) == "number")
    assert(writ.quantity > 0)
    assert(writ.reputation == 75 or writ.reputation == 125 or writ.reputation == 200)
    count = count + 1
end
equal(count, 150)

print("Price tests passed")
