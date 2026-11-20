local addon = {}
assert(loadfile("WritMaxxer/Prices.lua"))("WritMaxxer", addon)

local function listing(name, quantity, buyout)
    return { name = name, quantity = quantity, buyout = buyout }
end

local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end

-- Exact name matching, cheapest buyouts, deduplication, and sorted totals.
equal(addon.Prices.GetRequiredItemName("Craftsman's Writ: Copper Rod"), "Copper Rod")
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
equal(rows[1].itemName, "Linen Bag")
equal(rows[1].total, 150)
equal(rows[2].writCost, 100)
equal(rows[2].itemCost, 300)
equal(rows[2].quantity, 1)
equal(rows[2].total, 400)

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

print("Price tests passed")
