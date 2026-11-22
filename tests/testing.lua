local testing = {}
local unpack = unpack or table.unpack
local nativeXpcall = xpcall

-- Match WoW's argument-forwarding xpcall when testing with standard Lua 5.1.
function xpcall(callback, handler, ...)
    local args, count = { ... }, select('#', ...)
    return nativeXpcall(function() return callback(unpack(args, 1, count)) end, handler)
end

-- Map names to functions, or to { run = function, cases = { { arguments... }, ... } }.
-- A plain function runs once; an explicit empty cases table runs no cases.
-- Prints and returns separate counts of named tests and executed cases; stops on failure.
function testing.run_tests(tests)
    local names = {}
    for name in pairs(tests) do names[#names + 1] = name end
    table.sort(names)

    local counts = { tests = 0, cases = 0 }
    for _, name in ipairs(names) do
        local test = tests[name]
        local run, cases
        if type(test) == 'function' then
            run, cases = test, { {} }
        else
            run, cases = test.run, test.cases or { {} }
        end

        for index, parameters in ipairs(cases) do
            local ok, err = pcall(run, unpack(parameters, 1, parameters.n or #parameters))
            assert(ok, name .. ' (case ' .. index .. '): ' .. tostring(err))
            counts.cases = counts.cases + 1
        end

        counts.tests = counts.tests + 1
    end

    print(string.format('tests passed (%d tests, %d cases)', counts.tests, counts.cases))

    return counts
end

return testing
