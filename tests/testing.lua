local testing = {}
local unpack = unpack or table.unpack

-- Map names to functions, or to { run = function, cases = { { arguments... }, ... } }.
-- A plain function runs once; an explicit empty cases table runs no cases.
-- Returns separate counts of named tests and executed cases; stops on failure.
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

    return counts
end

return testing
