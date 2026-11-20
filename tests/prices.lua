local addon = {}
assert(loadfile("WritMaxxer/WritReputation.lua"))("WritMaxxer", addon)
assert(loadfile("WritMaxxer/Prices.lua"))("WritMaxxer", addon)

local function listing(name, quantity, buyout)
    return { name = name, quantity = quantity, buyout = buyout }
end

local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end

-- Exact name matching, cheapest buyouts, deduplication, and name ties.
equal(addon.Prices.GetRequiredItemName("Craftsman's Writ: Copper Rod"), "Copper Rod")
equal(addon.Prices.GetRequiredItemName("Craftsman's Writ: Lesser Stoneshield Potion"), "Lesser Stoneshield Potion")
equal(addon.Prices.GetRequiredItemName("Craftsman's Writ: "), nil)
equal(addon.Prices.GetRequiredItemName("Sealed Journeyman's Writ"), nil)

local rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Copper Rod", 1, 200),
    listing("Craftsman's Writ: Copper Rod", 1, 100),
    listing("Copper Rod", 1, 300),
    listing("Recipe: Copper Rod", 1, 1),
    listing("Copper Rod of Strength", 1, 1),
    listing("Craftsman's Writ: Linen Bag", 1, 50),
    listing("Linen Bag", 1, 100),
    listing("Sealed Journeyman's Writ", 1, 1),
})
equal(#rows, 2)
equal(rows[1].itemName, "Copper Rod")
equal(rows[1].writCost, 100)
equal(rows[1].itemCost, 300)
equal(rows[1].quantity, 1)
equal(rows[1].total, 400)
equal(rows[2].itemName, "Linen Bag")
equal(rows[2].total, 150)

-- No buyout or insufficient stock must never turn into a cheap total.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Missing", 1, 10),
    listing("Craftsman's Writ: Bid Only", 1, 0),
    listing("Bid Only", 1, 10),
    listing("Craftsman's Writ: Crafted Solid Shot", 1, 10),
    listing("Crafted Solid Shot", 199, 199),
})
equal(#rows, 3)
for _, row in ipairs(rows) do
    equal(row.total, nil)
end

-- Required quantity consumes actual price tiers rather than multiplying
-- the lowest price despite there being insufficient stock at that price.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Crafted Solid Shot", 1, 25),
    listing("Crafted Solid Shot", 100, 100),
    listing("Crafted Solid Shot", 150, 450),
    listing("Crafted Solid Shot", 100, 900),
})
equal(rows[1].quantity, 200)
equal(rows[1].itemCost, 400)
equal(rows[1].total, 425)

-- Stack buyouts are normalized to unit estimates and rounded to copper.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Copper Rod", 2, 101),
    listing("Copper Rod", 2, 201),
})
equal(rows[1].writCost, 51)
equal(rows[1].itemCost, 101)
equal(rows[1].total, 152)
equal(#addon.Prices.BuildRows({}), 0)

-- Rank rewards change the order compared with total gold cost alone.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Elixir of Wisdom", 1, 100),
    listing("Elixir of Wisdom", 1, 650),
    listing("Craftsman's Writ: Lesser Stoneshield Potion", 1, 250),
    listing("Lesser Stoneshield Potion", 1, 750),
    listing("Craftsman's Writ: Potion of Demon Slaying", 1, 300),
    listing("Potion of Demon Slaying", 1, 1200),
    listing("Craftsman's Writ: Unknown", 1, 1),
    listing("Unknown", 1, 1),
    listing("Craftsman's Writ: Elixir of Ogre Strength", 1, 1),
})
equal(rows[1].itemName, "Potion of Demon Slaying")
equal(rows[1].reputation, 200)
equal(rows[1].costPer100Rep, 750)
equal(rows[2].itemName, "Lesser Stoneshield Potion")
equal(rows[2].reputation, 125)
equal(rows[2].costPer100Rep, 800)
equal(rows[3].itemName, "Elixir of Wisdom")
equal(rows[3].reputation, 75)
equal(rows[3].costPer100Rep, 1000)
equal(rows[4].itemName, "Unknown")
equal(rows[4].total, 2)
equal(rows[4].reputation, nil)
equal(rows[4].costPer100Rep, nil)
equal(rows[5].reputation, 75)
equal(rows[5].costPer100Rep, nil)

-- Keep fractional copper for ranking; round only for display.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Elixir of Wisdom", 1, 1),
    listing("Elixir of Wisdom", 1, 1),
    listing("Craftsman's Writ: Lesser Stoneshield Potion", 1, 1),
    listing("Lesser Stoneshield Potion", 1, 2),
})
equal(rows[1].reputation, 125)
equal(rows[1].costPer100Rep, 2.4)
equal(rows[2].reputation, 75)

-- Equal reputation value prefers more complete turn-ins, regardless of total.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Elixir of Wisdom", 2, 100),
    listing("Elixir of Wisdom", 10, 250),
    listing("Craftsman's Writ: Lesser Stoneshield Potion", 4, 200),
    listing("Lesser Stoneshield Potion", 3, 225),
    listing("Lesser Stoneshield Potion", 100, 0),
    listing("Craftsman's Writ: Lesser Stoneshield Potion", 100, 0),
})
equal(rows[1].itemName, "Lesser Stoneshield Potion")
equal(rows[1].costPer100Rep, 100)
equal(rows[1].availableTurnIns, 3)
equal(rows[2].availableTurnIns, 2)

-- Ammunition availability counts complete batches across buyout listings.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Crafted Solid Shot", 5, 125),
    listing("Crafted Solid Shot", 199, 199),
    listing("Crafted Solid Shot", 400, 400),
})
equal(rows[1].availableTurnIns, 2)

rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Crafted Solid Shot", 5, 125),
    listing("Crafted Solid Shot", 199, 199),
    listing("Craftsman's Writ: Missing", 1, 1),
})
for _, row in ipairs(rows) do equal(row.availableTurnIns, 0) end

-- Name breaks equal value and availability ties, without comparing total.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Elixir of Wisdom", 1, 25),
    listing("Elixir of Wisdom", 1, 50),
    listing("Craftsman's Writ: Crafted Solid Shot", 1, 25),
    listing("Crafted Solid Shot", 200, 50),
})
equal(rows[1].itemName, "Crafted Solid Shot")
equal(rows[2].itemName, "Elixir of Wisdom")

-- Rows expose stock, item identity, and unit prices for the compact view.
local writ = listing("Craftsman's Writ: Crafted Solid Shot", 3, 75)
writ.itemID, writ.icon = 264037, 134939
local ammo = listing("Crafted Solid Shot", 100, 100)
ammo.itemID, ammo.icon = 8069, 132384
rows = addon.Prices.BuildRows({
    writ, ammo,
    listing("Crafted Solid Shot", 150, 450),
    listing("Crafted Solid Shot", 100, 0),
})
equal(rows[1].writStock, 3)
equal(rows[1].itemStock, 250)
equal(rows[1].writItemID, 264037)
equal(rows[1].itemID, 8069)
equal(rows[1].writIcon, 134939)
equal(rows[1].itemIcon, 132384)
equal(rows[1].itemUnitCost, 1)
equal(rows[1].itemCost, 400)
equal(rows[1].costPerRep, 425 / 75)

-- Old snapshots remain usable without icon metadata; stock shortages still
-- allow a unit price but cannot produce a complete turn-in estimate.
rows = addon.Prices.BuildRows({
    listing("Craftsman's Writ: Crafted Solid Shot", 1, 25),
    listing("Crafted Solid Shot", 199, 199),
})
equal(rows[1].itemUnitCost, 1)
equal(rows[1].costPerRep, nil)
equal(rows[1].itemIcon, nil)

print("Price tests passed")
