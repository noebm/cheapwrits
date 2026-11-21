local _, addon = ...

-- Writ item ID -> required item ID, quantity, base reputation, and optional turn-in UiMapID.
-- Turn-in zones: Wowhead's guide by Serenal (updated 2026-11-15), read 2026-11-21.
-- https://www.wowhead.com/forever/guide/professions/craftsmans-writs-overview-recipes-rewards
-- English map names are annotations only; the UI resolves localized names via C_Map.
-- Missing turnInMapID means the guide does not list a zone.
-- WoW Forever build 1.60.1.70862, all 150 writs:
-- https://github.com/AidVir/wow-forever-favor/blob/main/data/writs.js
-- English annotations: data/recipes.json in the same repository.
addon.Writs = {
    -- Journeyman
    [264011] = { itemID = 3391, quantity = 1, reputation = 75, turnInMapID = 1416 --[[ Alterac Mountains ]] }, -- Elixir of Ogre Strength
    [264012] = { itemID = 3383, quantity = 1, reputation = 75, turnInMapID = 1417 --[[ Arathi Highlands ]] }, -- Elixir of Wisdom
    [264013] = { itemID = 3385, quantity = 1, reputation = 75, turnInMapID = 1440 --[[ Ashenvale ]] }, -- Lesser Mana Potion
    [264014] = { itemID = 6048, quantity = 1, reputation = 75, turnInMapID = 1431 --[[ Duskwood ]] }, -- Shadow Protection Potion
    [264015] = { itemID = 5634, quantity = 1, reputation = 75, turnInMapID = 1424 --[[ Hillsbrad Foothills ]] }, -- Free Action Potion
    [264016] = { itemID = 3390, quantity = 1, reputation = 75, turnInMapID = 1442 --[[ Stonetalon Mountains ]] }, -- Elixir of Lesser Agility
    [264017] = { itemID = 3388, quantity = 1, reputation = 75, turnInMapID = 1434 --[[ Stranglethorn Vale ]] }, -- Lesser Troll's Blood Elixir
    [264018] = { itemID = 8951, quantity = 1, reputation = 75, turnInMapID = 1441 --[[ Thousand Needles ]] }, -- Elixir of Defense
    [264019] = { itemID = 5996, quantity = 1, reputation = 75, turnInMapID = 1437 --[[ Wetlands ]] }, -- Draught of Water Breathing
    [264020] = { itemID = 5540, quantity = 1, reputation = 75, turnInMapID = 1416 --[[ Alterac Mountains ]] }, -- Pearl-handled Dagger
    [264021] = { itemID = 11128, quantity = 1, reputation = 75, turnInMapID = 1417 --[[ Arathi Highlands ]] }, -- Golden Rod
    [264022] = { itemID = 5541, quantity = 1, reputation = 75, turnInMapID = 1440 --[[ Ashenvale ]] }, -- Iridescent Hammer
    [264023] = { itemID = 15869, quantity = 1, reputation = 75, turnInMapID = 1431 --[[ Duskwood ]] }, -- Silver Skeleton Key
    [264024] = { itemID = 3491, quantity = 1, reputation = 75, turnInMapID = 1424 --[[ Hillsbrad Foothills ]] }, -- Heavy Bronze Mace
    [264025] = { itemID = 2865, quantity = 1, reputation = 75, turnInMapID = 1442 --[[ Stonetalon Mountains ]] }, -- Rough Bronze Leggings
    [264026] = { itemID = 3485, quantity = 1, reputation = 75, turnInMapID = 1434 --[[ Stranglethorn Vale ]] }, -- Green Iron Gauntlets
    [264027] = { itemID = 3848, quantity = 1, reputation = 75, turnInMapID = 1441 --[[ Thousand Needles ]] }, -- Big Bronze Knife
    [264028] = { itemID = 3484, quantity = 1, reputation = 75, turnInMapID = 1437 --[[ Wetlands ]] }, -- Green Iron Boots
    [264029] = { itemID = 5507, quantity = 1, reputation = 75, turnInMapID = 1416 --[[ Alterac Mountains ]] }, -- Ornate Spyglass
    [264030] = { itemID = 4384, quantity = 1, reputation = 75, turnInMapID = 1417 --[[ Arathi Highlands ]] }, -- Explosive Sheep
    [264031] = { itemID = 4383, quantity = 1, reputation = 75, turnInMapID = 1440 --[[ Ashenvale ]] }, -- Moonsight Rifle
    [264032] = { itemID = 4381, quantity = 1, reputation = 75, turnInMapID = 1431 --[[ Duskwood ]] }, -- Minor Recombobulator
    [264033] = { itemID = 6712, quantity = 1, reputation = 75, turnInMapID = 1424 --[[ Hillsbrad Foothills ]] }, -- Practice Lock
    [264034] = { itemID = 4373, quantity = 1, reputation = 75, turnInMapID = 1442 --[[ Stonetalon Mountains ]] }, -- Shadow Goggles
    [264035] = { itemID = 7506, quantity = 1, reputation = 75, turnInMapID = 1434 --[[ Stranglethorn Vale ]] }, -- Gnomish Universal Remote
    [264036] = { itemID = 4380, quantity = 1, reputation = 75, turnInMapID = 1441 --[[ Thousand Needles ]] }, -- Big Bronze Bomb
    [264037] = { itemID = 8069, quantity = 200, reputation = 75, turnInMapID = 1437 --[[ Wetlands ]] }, -- Crafted Solid Shot
    [264038] = { itemID = 18662, quantity = 1, reputation = 75, turnInMapID = 1416 --[[ Alterac Mountains ]] }, -- Heavy Leather Ball
    [264039] = { itemID = 5958, quantity = 1, reputation = 75, turnInMapID = 1417 --[[ Arathi Highlands ]] }, -- Fine Leather Pants
    [264040] = { itemID = 7349, quantity = 1, reputation = 75, turnInMapID = 1440 --[[ Ashenvale ]] }, -- Herbalist's Gloves
    [264041] = { itemID = 2317, quantity = 1, reputation = 75, turnInMapID = 1431 --[[ Duskwood ]] }, -- Dark Leather Tunic
    [264042] = { itemID = 7358, quantity = 1, reputation = 75, turnInMapID = 1424 --[[ Hillsbrad Foothills ]] }, -- Pilferer's Gloves
    [264043] = { itemID = 7371, quantity = 1, reputation = 75, turnInMapID = 1442 --[[ Stonetalon Mountains ]] }, -- Heavy Quiver
    [264044] = { itemID = 4252, quantity = 1, reputation = 75, turnInMapID = 1434 --[[ Stranglethorn Vale ]] }, -- Dark Leather Shoulders
    [264045] = { itemID = 4254, quantity = 1, reputation = 75, turnInMapID = 1441 --[[ Thousand Needles ]] }, -- Barbaric Gloves
    [264046] = { itemID = 7284, quantity = 1, reputation = 75, turnInMapID = 1437 --[[ Wetlands ]] }, -- Red Whelp Gloves
    [264047] = { itemID = 5766, quantity = 1, reputation = 75, turnInMapID = 1416 --[[ Alterac Mountains ]] }, -- Lesser Wizard's Robe
    [264048] = { itemID = 6263, quantity = 1, reputation = 75, turnInMapID = 1417 --[[ Arathi Highlands ]] }, -- Blue Overalls
    [264049] = { itemID = 7048, quantity = 1, reputation = 75, turnInMapID = 1440 --[[ Ashenvale ]] }, -- Azure Silk Hood
    [264050] = { itemID = 4245, quantity = 1, reputation = 75, turnInMapID = 1431 --[[ Duskwood ]] }, -- Small Silk Pack
    [264051] = { itemID = 4317, quantity = 1, reputation = 75, turnInMapID = 1416 --[[ Alterac Mountains ]] }, -- Phoenix Pants
    [264052] = { itemID = 4313, quantity = 1, reputation = 75, turnInMapID = 1442 --[[ Stonetalon Mountains ]] }, -- Red Woolen Boots
    [264053] = { itemID = 10048, quantity = 1, reputation = 75, turnInMapID = 1434 --[[ Stranglethorn Vale ]] }, -- Colorful Kilt
    [264054] = { itemID = 6264, quantity = 1, reputation = 75, turnInMapID = 1441 --[[ Thousand Needles ]] }, -- Greater Adept's Robe
    [264055] = { itemID = 4321, quantity = 1, reputation = 75, turnInMapID = 1437 --[[ Wetlands ]] }, -- Spider Silk Slippers
    -- Expert
    [264056] = { itemID = 6050, quantity = 1, reputation = 125, turnInMapID = 1418 --[[ Badlands ]] }, -- Frost Protection Potion
    [264057] = { itemID = 3823, quantity = 1, reputation = 125, turnInMapID = 1443 --[[ Desolace ]] }, -- Lesser Invisibility Potion
    [264058] = { itemID = 4623, quantity = 1, reputation = 125, turnInMapID = 1445 --[[ Dustwallow Marsh ]] }, -- Lesser Stoneshield Potion
    [264059] = { itemID = 6052, quantity = 1, reputation = 125, turnInMapID = 1448 --[[ Felwood ]] }, -- Nature Protection Potion
    [264060] = { itemID = 10592, quantity = 1, reputation = 125, turnInMapID = 1444 --[[ Feralas ]] }, -- Catseye Draught
    [264061] = { itemID = 5633, quantity = 1, reputation = 125, turnInMapID = 1450 --[[ Moonglade ]] }, -- Great Rage Potion
    [264062] = { itemID = 3827, quantity = 1, reputation = 125, turnInMapID = 1440 --[[ Ashenvale ]] }, -- Mana Potion
    [264063] = { itemID = 6049, quantity = 1, reputation = 125, turnInMapID = 1427 --[[ Searing Gorge ]] }, -- Fire Protection Potion
    [264064] = { itemID = 3824, quantity = 1, reputation = 125, turnInMapID = 1435 --[[ Swamp of Sorrows ]] }, -- Shadow Oil
    [264065] = { itemID = 9061, quantity = 1, reputation = 125, turnInMapID = 1447 --[[ Azshara ]] }, -- Goblin Rocket Fuel
    [264066] = { itemID = 8949, quantity = 1, reputation = 125, turnInMapID = 1425 --[[ The Hinterlands ]] }, -- Elixir of Agility
    [264067] = { itemID = 9144, quantity = 1, reputation = 125, turnInMapID = 1449 --[[ Un'Goro Crater ]] }, -- Wildvine Potion
    [264068] = { itemID = 7922, quantity = 1, reputation = 125 }, -- Steel Plate Helm
    [264069] = { itemID = 9060, quantity = 1, reputation = 125, turnInMapID = 1443 --[[ Desolace ]] }, -- Inlaid Mithril Cylinder
    [264070] = { itemID = 6041, quantity = 1, reputation = 125, turnInMapID = 1445 --[[ Dustwallow Marsh ]] }, -- Steel Weapon Chain
    [264071] = { itemID = 7928, quantity = 1, reputation = 125, turnInMapID = 1448 --[[ Felwood ]] }, -- Ornate Mithril Shoulders
    [264072] = { itemID = 7942, quantity = 1, reputation = 125 }, -- Blue Glittering Axe
    [264073] = { itemID = 3853, quantity = 1, reputation = 125, turnInMapID = 1450 --[[ Moonglade ]] }, -- Moonsteel Broadsword
    [264074] = { itemID = 3837, quantity = 1, reputation = 125, turnInMapID = 2548 --[[ Riverglades ]] }, -- Golden Scale Coif
    [264075] = { itemID = 7964, quantity = 1, reputation = 125 }, -- Solid Sharpening Stone
    [264076] = { itemID = 7943, quantity = 1, reputation = 125 }, -- Wicked Mithril Blade
    [264077] = { itemID = 11144, quantity = 1, reputation = 125 }, -- Truesilver Rod
    [264078] = { itemID = 9366, quantity = 1, reputation = 125 }, -- Golden Scale Gauntlets
    [264079] = { itemID = 7941, quantity = 1, reputation = 125, turnInMapID = 1449 --[[ Un'Goro Crater ]] }, -- Heavy Mithril Axe
    [264080] = { itemID = 4396, quantity = 1, reputation = 125 }, -- Mechanical Dragonling
    [264081] = { itemID = 4392, quantity = 1, reputation = 125, turnInMapID = 1443 --[[ Desolace ]] }, -- Advanced Target Dummy
    [264082] = { itemID = 4393, quantity = 1, reputation = 125, turnInMapID = 1445 --[[ Dustwallow Marsh ]] }, -- Craftsman's Monocle
    [264083] = { itemID = 4395, quantity = 1, reputation = 125, turnInMapID = 1448 --[[ Felwood ]] }, -- Goblin Land Mine
    [264084] = { itemID = 10501, quantity = 1, reputation = 125, turnInMapID = 1444 --[[ Feralas ]] }, -- Catseye Ultra Goggles
    [264085] = { itemID = 10560, quantity = 1, reputation = 125, turnInMapID = 1450 --[[ Moonglade ]] }, -- Unstable Trigger
    [264086] = { itemID = 4852, quantity = 1, reputation = 125, turnInMapID = 2548 --[[ Riverglades ]] }, -- Flash Bomb
    [264087] = { itemID = 10500, quantity = 1, reputation = 125 }, -- Fire Goggles
    [264088] = { itemID = 10514, quantity = 1, reputation = 125 }, -- Mithril Frag Bomb
    [264089] = { itemID = 10498, quantity = 1, reputation = 125 }, -- Gyromatic Micro-Adjustor
    [264090] = { itemID = 11590, quantity = 1, reputation = 125 }, -- Mechanical Repair Kit
    [264091] = { itemID = 16005, quantity = 1, reputation = 125 }, -- Dark Iron Bomb
    [264092] = { itemID = 8174, quantity = 1, reputation = 125, turnInMapID = 1418 --[[ Badlands ]] }, -- Comfortable Leather Hat
    [264093] = { itemID = 5965, quantity = 1, reputation = 125, turnInMapID = 1443 --[[ Desolace ]] }, -- Guardian Cloak
    [264094] = { itemID = 7378, quantity = 1, reputation = 125, turnInMapID = 1445 --[[ Dustwallow Marsh ]] }, -- Dusky Bracers
    [264095] = { itemID = 8214, quantity = 1, reputation = 125, turnInMapID = 1448 --[[ Felwood ]] }, -- Wild Leather Helmet
    [264096] = { itemID = 8210, quantity = 1, reputation = 125, turnInMapID = 1444 --[[ Feralas ]] }, -- Wild Leather Shoulders
    [264097] = { itemID = 8217, quantity = 1, reputation = 125, turnInMapID = 1450 --[[ Moonglade ]] }, -- Quickdraw Quiver
    [264098] = { itemID = 7391, quantity = 1, reputation = 125, turnInMapID = 2548 --[[ Riverglades ]] }, -- Swift Boots
    [264099] = { itemID = 8192, quantity = 1, reputation = 125, turnInMapID = 1427 --[[ Searing Gorge ]] }, -- Nightscape Shoulders
    [264100] = { itemID = 8201, quantity = 1, reputation = 125, turnInMapID = 1435 --[[ Swamp of Sorrows ]] }, -- Big Voodoo Mask
    [264101] = { itemID = 8200, quantity = 1, reputation = 125, turnInMapID = 1446 --[[ Tanaris ]] }, -- Big Voodoo Robe
    [264102] = { itemID = 8189, quantity = 1, reputation = 125 }, -- Turtle Scale Breastplate
    [264103] = { itemID = 8218, quantity = 1, reputation = 125, turnInMapID = 1449 --[[ Un'Goro Crater ]] }, -- Thick Leather Ammo Pouch
    [264104] = { itemID = 10050, quantity = 1, reputation = 125, turnInMapID = 1418 --[[ Badlands ]] }, -- Mageweave Bag
    [264105] = { itemID = 10023, quantity = 1, reputation = 125, turnInMapID = 1443 --[[ Desolace ]] }, -- Shadoweave Gloves
    [264106] = { itemID = 7063, quantity = 1, reputation = 125, turnInMapID = 1445 --[[ Dustwallow Marsh ]] }, -- Crimson Silk Robe
    [264107] = { itemID = 10004, quantity = 1, reputation = 125, turnInMapID = 1448 --[[ Felwood ]] }, -- Shadoweave Robe
    [264108] = { itemID = 22246, quantity = 1, reputation = 125, turnInMapID = 1448 --[[ Felwood ]] }, -- Enchanted Mageweave Pouch
    [264109] = { itemID = 4329, quantity = 1, reputation = 125, turnInMapID = 1450 --[[ Moonglade ]] }, -- Star Belt
    [264110] = { itemID = 9998, quantity = 1, reputation = 125, turnInMapID = 2548 --[[ Riverglades ]] }, -- Black Mageweave Vest
    [264111] = { itemID = 10009, quantity = 1, reputation = 125, turnInMapID = 1427 --[[ Searing Gorge ]] }, -- Red Mageweave Pants
    [264112] = { itemID = 10052, quantity = 1, reputation = 125, turnInMapID = 1435 --[[ Swamp of Sorrows ]] }, -- Orange Martial Shirt
    [264113] = { itemID = 10008, quantity = 1, reputation = 125 }, -- White Bandit Mask
    [264114] = { itemID = 10042, quantity = 1, reputation = 125 }, -- Cindercloth Robe
    [264115] = { itemID = 7061, quantity = 1, reputation = 125, turnInMapID = 1449 --[[ Un'Goro Crater ]] }, -- Earthen Silk Belt
    -- Artisan
    [264116] = { itemID = 9224, quantity = 1, reputation = 200 }, -- Potion of Demon Slaying
    [264117] = { itemID = 12190, quantity = 1, reputation = 200, turnInMapID = 1419 --[[ Blasted Lands ]] }, -- Dreamless Sleep Potion
    [264118] = { itemID = 13457, quantity = 1, reputation = 200 }, -- Greater Fire Protection Potion
    [264119] = { itemID = 9233, quantity = 1, reputation = 200, turnInMapID = 1430 --[[ Deadwind Pass ]] }, -- Draught of Detect Demon
    [264120] = { itemID = 9088, quantity = 1, reputation = 200 }, -- Gift of Arthas
    [264121] = { itemID = 13513, quantity = 1, reputation = 200 }, -- Flask of Chromatic Resistance
    [264122] = { itemID = 3387, quantity = 1, reputation = 200 }, -- Limited Invulnerability Potion
    [264123] = { itemID = 18253, quantity = 1, reputation = 200 }, -- Major Rejuvenation Potion
    [264124] = { itemID = 246948, quantity = 1, reputation = 200, turnInMapID = 1452 --[[ Winterspring ]] }, -- Distilled Firewater
    [264125] = { itemID = 12417, quantity = 1, reputation = 200 }, -- Radiant Circlet
    [264126] = { itemID = 12416, quantity = 1, reputation = 200 }, -- Radiant Belt
    [264127] = { itemID = 7929, quantity = 1, reputation = 200 }, -- Orcish War Leggings
    [264128] = { itemID = 7969, quantity = 1, reputation = 200, turnInMapID = 1430 --[[ Deadwind Pass ]] }, -- Mithril Spurs
    [264129] = { itemID = 12422, quantity = 1, reputation = 200 }, -- Imperial Plate Chest
    [264130] = { itemID = 20549, quantity = 1, reputation = 200 }, -- Darkrune Gauntlets
    [264131] = { itemID = 12775, quantity = 1, reputation = 200 }, -- Huge Thorium Battleaxe
    [264132] = { itemID = 15872, quantity = 1, reputation = 200 }, -- Arcanite Skeleton Key
    [264133] = { itemID = 7947, quantity = 1, reputation = 200 }, -- Ebon Shiv
    [264134] = { itemID = 16023, quantity = 1, reputation = 200 }, -- Masterwork Target Dummy
    [264135] = { itemID = 10504, quantity = 1, reputation = 200 }, -- Green Lens
    [264136] = { itemID = 15996, quantity = 1, reputation = 200 }, -- Lifelike Mechanical Toad
    [264137] = { itemID = 18645, quantity = 1, reputation = 200 }, -- Alarm-O-Bot
    [264138] = { itemID = 18587, quantity = 1, reputation = 200 }, -- Goblin Jumper Cables XL
    [264139] = { itemID = 18232, quantity = 1, reputation = 200 }, -- Field Repair Bot 74A
    [264140] = { itemID = 18631, quantity = 1, reputation = 200 }, -- Truesilver Transformer
    [264141] = { itemID = 10548, quantity = 1, reputation = 200 }, -- Sniper Scope
    [264142] = { itemID = 21277, quantity = 1, reputation = 200 }, -- Tranquil Mechanical Yeti
    [264143] = { itemID = 15087, quantity = 1, reputation = 200 }, -- Wicked Leather Pants
    [264144] = { itemID = 18258, quantity = 1, reputation = 200 }, -- Gordok Ogre Suit
    [264145] = { itemID = 15053, quantity = 1, reputation = 200 }, -- Volcanic Breastplate
    [264146] = { itemID = 15094, quantity = 1, reputation = 200, turnInMapID = 1430 --[[ Deadwind Pass ]] }, -- Runic Leather Headband
    [264147] = { itemID = 15084, quantity = 1, reputation = 200 }, -- Wicked Leather Bracers
    [264148] = { itemID = 15075, quantity = 1, reputation = 200 }, -- Chimeric Vest
    [264149] = { itemID = 15080, quantity = 1, reputation = 200 }, -- Heavy Scorpid Helm
    [264150] = { itemID = 15092, quantity = 1, reputation = 200 }, -- Runic Leather Bracers
    [264151] = { itemID = 15071, quantity = 1, reputation = 200 }, -- Frostsaber Boots
    [264152] = { itemID = 14130, quantity = 1, reputation = 200 }, -- Wizardweave Turban
    [264153] = { itemID = 14046, quantity = 1, reputation = 200, turnInMapID = 1419 --[[ Blasted Lands ]] }, -- Runecloth Bag
    [264154] = { itemID = 13864, quantity = 1, reputation = 200 }, -- Runecloth Boots
    [264155] = { itemID = 10036, quantity = 1, reputation = 200, turnInMapID = 1430 --[[ Deadwind Pass ]] }, -- Tuxedo Jacket
    [264156] = { itemID = 14108, quantity = 1, reputation = 200 }, -- Felcloth Boots
    [264157] = { itemID = 22251, quantity = 1, reputation = 200 }, -- Cenarion Herb Bag
    [264158] = { itemID = 10025, quantity = 1, reputation = 200, turnInMapID = 1451 --[[ Silithus ]] }, -- Shadoweave Mask
    [264159] = { itemID = 14141, quantity = 1, reputation = 200 }, -- Ghostweave Vest
    [264160] = { itemID = 21340, quantity = 1, reputation = 200, turnInMapID = 1452 --[[ Winterspring ]] }, -- Soul Pouch
}
