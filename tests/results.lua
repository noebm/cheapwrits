-- Exercise rendering, replay compatibility, tooltips, and row reuse at the UI boundary.
local frames = {}
local function widget(parent)
    local self = { parent = parent, scripts = {}, shown = true }
    function self:SetSize(w, h) self.width, self.height = w, h end
    function self:SetHeight(h) self.height = h end
    function self:SetWidth(w) self.width = w end
    function self:SetPoint() end
    function self:SetAllPoints() end
    function self:SetFrameStrata() end
    function self:SetMovable() end
    function self:EnableMouse() end
    function self:RegisterForDrag() end
    function self:SetJustifyH() end
    function self:SetSpacing() end
    function self:GetStringHeight() return 40 end
    function self:SetTextColor() end
    function self:SetColorTexture() end
    function self:SetTexCoord() end
    function self:SetText(text) self.text = tostring(text) end
    function self:SetTexture(texture) self.texture = texture end
    function self:SetScrollChild(child) self.child = child end
    function self:SetVerticalScroll(value) self.offset = value end
    function self:SetScript(event, handler) self.scripts[event] = handler end
    function self:Show() self.shown = true end
    function self:Hide() self.shown = false end
    function self:CreateFontString() return widget(self) end
    function self:CreateTexture() return widget(self) end
    return self
end
function CreateFrame(kind, name, parent)
    local frame = widget(parent)
    frame.kind, frame.name = kind, name
    frame.TitleText = widget(frame)
    frames[#frames + 1] = frame
    return frame
end
UIParent, UISpecialFrames = {}, {}
function GetTime() return 120 end
C_Item = { GetItemInfoInstant = function() return nil end }
GameTooltip = widget()
function GameTooltip:SetOwner() end
function GameTooltip:SetItemByID(id) self.itemID = id end
function GameTooltip:AddLine(line) self.line = line end

local addon = { scannedAt = 0 }
function addon:Print(message) self.message = message end
assert(loadfile('WritMaxxer/Results.lua'))('WritMaxxer', addon)
addon:ShowResults()
assert(addon.message:find('No results loaded', 1, true))
local row = {
    writName = "Craftsman's Writ: Crafted Solid Shot", itemName = 'Crafted Solid Shot',
    writItemID = 264037, itemID = 8069, writIcon = 134939, itemIcon = 132384,
    writStock = 3, itemStock = 250, quantity = 200, availableTurnIns = 1,
    writCost = 25, itemUnitCost = 1, reputation = 75, costPerRep = 425 / 75,
}
addon:ShowResults({ row, row })
local buttons = {}
for _, frame in ipairs(frames) do
    if frame.kind == 'Button' then buttons[#buttons + 1] = frame end
end
assert(#buttons == 4, 'Each result must have two item icons')
assert(buttons[1].icon.texture == 134939 and buttons[1].count.text == '3')
assert(buttons[2].icon.texture == 132384 and buttons[2].count.text == '250')
buttons[2].scripts.OnEnter(buttons[2])
assert(GameTooltip.itemID == 8069 and GameTooltip.line:find('200', 1, true))
buttons[2].scripts.OnLeave(buttons[2])
assert(not GameTooltip.shown)
local firstRow = buttons[1].parent
assert(firstRow.writPrice.text == '0g 0s 25c')
assert(firstRow.itemPrice.text == '0g 0s 1c')
assert(firstRow.reputation.text == '75')
assert(firstRow.goldPerRep.text == '0.000567g')

-- An old snapshot may have no metadata and no complete price estimate.
local old = {
    writName = 'Unknown writ', itemName = 'Unknown item', writStock = 1, itemStock = 0,
    quantity = 1, availableTurnIns = 0,
}
addon:ShowResults({ old })
assert(#frames > 0 and not buttons[3].parent.shown)
assert(buttons[1].count.text == '1' and buttons[2].count.text == '0')
assert(buttons[2].icon.texture == 'Interface\\Icons\\INV_Misc_QuestionMark')
assert(firstRow.itemPrice.text == 'Unavailable' and firstRow.goldPerRep.text == 'Unavailable')
buttons[2].scripts.OnEnter(buttons[2])
assert(GameTooltip.text == 'Unknown item')
local frameCount = #frames
addon:ShowResults({ row })
assert(#frames == frameCount and firstRow.shown, 'Reuse existing rows')
addon:ShowResults({})
assert(not firstRow.shown)
print('Results UI tests passed')
