local DIR = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = DIR .. "common/?.lua;" .. DIR .. "?.lua;" .. package.path

-- Difficulty guarantees: the size is the level (3x3, 4x4, 5x5). Every size
-- deals a scrambled, solvable (right permutation parity), unsolved grid;
-- bigger sizes are further from solved on average (sum of the tiles'
-- Manhattan distances, a lower bound on the moves); a seed always deals the
-- same grid, and dealing never reads the clock.
local SEEDS = 10

-- Runs fn with os.clock/os.time wrapped; returns how often they were read.
local function clockReads(fn)
    local clock, time = os.clock, os.time
    local reads = 0
    os.clock = function() reads = reads + 1; return clock() end
    os.time = function(...) reads = reads + 1; return time(...) end
    local ok, err = pcall(fn)
    os.clock, os.time = clock, time
    assert(ok, err)
    return reads
end

-- Solvable iff (for odd n) the inversion count is even; (for even n) the
-- inversion count plus the blank's row counted from the bottom is odd.
local function solvable(b)
    local n, flat = b.n, {}
    for r = 1, n do
        for c = 1, n do
            if b.grid[r][c] ~= 0 then flat[#flat + 1] = b.grid[r][c] end
        end
    end
    local inv = 0
    for i = 1, #flat do
        for j = i + 1, #flat do
            if flat[i] > flat[j] then inv = inv + 1 end
        end
    end
    if n % 2 == 1 then return inv % 2 == 0 end
    return (inv + (n - b.blank_r + 1)) % 2 == 1
end

local function manhattan(b)
    local n, d = b.n, 0
    for r = 1, n do
        for c = 1, n do
            local v = b.grid[r][c]
            if v ~= 0 then
                d = d + math.abs(r - (math.floor((v - 1) / n) + 1)) + math.abs(c - ((v - 1) % n + 1))
            end
        end
    end
    return d
end

local function key(b)
    local t = {}
    for r = 1, b.n do t[r] = table.concat(b.grid[r], ",") end
    return table.concat(t, "/")
end

describe("Fifteen difficulty", function()
    local Board

    setup(function()
        Board = require("board")
    end)

    it("builds a scrambled but solvable 4x4 grid with the blank present", function()
        math.randomseed(42)
        local b = Board:new()
        assert.are.equal(4, b.n)
        local seen = {}
        for r = 1, b.n do
            for c = 1, b.n do
                seen[b.grid[r][c]] = true
            end
        end
        for v = 0, 15 do
            assert.is_true(seen[v], "missing value " .. v)
        end
        assert.are.equal(0, b.grid[b.blank_r][b.blank_c])
    end)

    it("is not solved right after scrambling (extremely unlikely to be)", function()
        math.randomseed(42)
        local b = Board:new()
        assert.is_false(b.won)
    end)

    it("every size deals a solvable, unsolved permutation", function()
        for _, n in ipairs(Board.SIZES) do
            for seed = 1, SEEDS do
                math.randomseed(seed)
                local b = Board:new{ n = n }
                local seen = {}
                for r = 1, n do
                    for c = 1, n do seen[b.grid[r][c]] = true end
                end
                for v = 0, n * n - 1 do assert.is_true(seen[v], n .. ": missing " .. v) end
                assert.is_true(solvable(b), n .. "x" .. n .. " seed " .. seed)
                assert.is_true(manhattan(b) > 0, n .. "x" .. n .. " seed " .. seed .. " is solved")
            end
        end
    end)

    it("bigger sizes start further from solved on average", function()
        local prev = 0
        for _, n in ipairs(Board.SIZES) do
            local sum = 0
            for seed = 1, SEEDS do
                math.randomseed(seed)
                sum = sum + manhattan(Board:new{ n = n })
            end
            assert.is_true(sum / SEEDS > prev, ("%dx%d: %.1f"):format(n, n, sum / SEEDS))
            prev = sum / SEEDS
        end
    end)

    it("the same seed deals the same grid, every size", function()
        for _, n in ipairs(Board.SIZES) do
            math.randomseed(77)
            local a = key(Board:new{ n = n })
            math.randomseed(77)
            assert.are.equal(a, key(Board:new{ n = n }))
        end
    end)

    it("dealing never reads the clock", function()
        for _, n in ipairs(Board.SIZES) do
            local reads = clockReads(function()
                math.randomseed(4)
                Board:new{ n = n }
            end)
            assert.are.equal(0, reads, n)
        end
    end)
end)
