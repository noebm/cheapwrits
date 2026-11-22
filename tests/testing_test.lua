local testing = dofile('tests/testing.lua')
local calls = 0
local counts = testing.run_tests({
    plain = function() calls = calls + 1 end,
    parameterized = {
        run = function(a, b) assert(a + b == 3); calls = calls + 1 end,
        cases = { { 1, 2 }, { 3, 0 } },
    },
    empty = { run = function() error('must not run') end, cases = {} },
})
assert(counts.tests == 3 and counts.cases == 3 and calls == 3)

local ok, err = pcall(testing.run_tests, {
    broken = { run = function() error('expected failure') end, cases = { {} } },
})
assert(not ok and err:find('broken') and err:find('case 1') and err:find('expected failure'))

local success, first, second, third = xpcall(function(...)
    assert(select('#', ...) == 3)
    local a, b, c = ...
    assert(a == 42 and b == nil and c == nil)
    return a, nil, 'last'
end, tostring, 42, nil, nil)
assert(success and first == 42 and second == nil and third == 'last')

local handled, message = xpcall(function(value) error(value, 0) end, function(value)
    return 'handled: ' .. value
end, 'expected failure')
assert(not handled and message == 'handled: expected failure')

local popup, cancelled
testing.mock_static_popups(function(dialog) popup = dialog end)
StaticPopupDialogs.TEST = {
    OnAccept = function(dialog)
        assert(popup == dialog, 'WoW calls OnAccept before hiding the popup')
        return true
    end,
    OnCancel = function(_, data, reason)
        assert(reason == 'override')
        cancelled = data
    end,
}
local dialog = StaticPopup_Show('TEST', 'first', nil, 'old')
assert(testing.accept_popup(dialog) and popup == dialog)
StaticPopup_Show('TEST', 'second', nil, 'new')
assert(cancelled == 'old' and popup == dialog)
StaticPopupDialogs.TEST.OnAccept = function() return false end
testing.accept_popup(dialog)
assert(not popup)
assert(StaticPopup_Show('TEST', 'third') == dialog, 'Hidden popup frames are reused')
print('testing module tests passed')
