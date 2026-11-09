local DIR = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = DIR .. "common/?.lua;" .. DIR .. "?.lua;" .. package.path

describe("FifteenBoard", function()
    local Board

    setup(function()
        Board = require("board")
    end)

    describe("slide", function()
        it("moves an orthogonally-adjacent tile into the blank", function()
            math.randomseed(42)
            local b = Board:new()
            local br, bc = b.blank_r, b.blank_c
            -- Find an adjacent tile to slide.
            local tr, tc
            for _, d in ipairs({ {0,1}, {0,-1}, {1,0}, {-1,0} } ) do
                local r, c = br + d[1], bc + d[2]
                if r >= 1 and r <= b.n and c >= 1 and c <= b.n then tr, tc = r, c; break end
            end
            local moved_value = b.grid[tr][tc]
            assert.is_true(b:slide(tr, tc))
            assert.are.equal(moved_value, b.grid[br][bc])
            assert.are.equal(0, b.grid[tr][tc])
            assert.are.equal(1, b.moves)
        end)

        it("refuses a non-adjacent tile", function()
            math.randomseed(42)
            local b = Board:new()
            local br, bc = b.blank_r, b.blank_c
            local far_r = (br == 1) and b.n or 1
            local far_c = (bc == 1) and b.n or 1
            assert.is_false(b:slide(far_r, far_c))
        end)

        it("detects a win once every tile is back in solved order", function()
            local b = Board:new()
            -- Force a solved grid, then undo one move so a single slide wins.
            b:_buildSolved()
            b.grid[b.n][b.n - 1], b.grid[b.n][b.n] = b.grid[b.n][b.n], b.grid[b.n][b.n - 1]
            b.blank_r, b.blank_c = b.n, b.n - 1
            b.won = false
            assert.is_true(b:slide(b.n, b.n))
            assert.is_true(b.won)
        end)
    end)

    describe("serialize / load", function()
        it("round-trips grid, blank position and move count", function()
            math.randomseed(42)
            local b = Board:new()
            local br, bc = b.blank_r, b.blank_c
            for _, d in ipairs({ {0,1}, {0,-1}, {1,0}, {-1,0} } ) do
                local r, c = br + d[1], bc + d[2]
                if r >= 1 and r <= b.n and c >= 1 and c <= b.n then b:slide(r, c); break end
            end
            local data = b:serialize()

            local b2 = Board:new()
            assert.is_true(b2:load(data))
            assert.are.equal(b.n, b2.n)
            assert.are.equal(b.moves, b2.moves)
            assert.are.equal(b.blank_r, b2.blank_r)
            assert.are.equal(b.blank_c, b2.blank_c)
        end)

        it("load returns false for invalid data", function()
            local b = Board:new()
            assert.is_false(b:load(nil))
            assert.is_false(b:load({}))
        end)
    end)
end)
