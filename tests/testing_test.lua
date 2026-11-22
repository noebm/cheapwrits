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
print('testing module tests passed')
