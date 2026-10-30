local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Device          = require("device")
local FrameContainer  = require("ui/widget/container/framecontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan  = require("ui/widget/horizontalspan")
local Size            = require("ui/size")
local UIManager       = require("ui/uimanager")
local VerticalGroup   = require("ui/widget/verticalgroup")
local VerticalSpan    = require("ui/widget/verticalspan")
local _               = require("i18n")
local T               = require("ffi/util").template

local ScreenBase         = require("screen_base")
local MenuHelper         = require("menu_helper")
local FifteenBoard       = lrequire("board")
local FifteenBoardWidget = lrequire("board_widget")

local DeviceScreen = Device.screen

-- ---------------------------------------------------------------------------
-- FifteenScreen
-- ---------------------------------------------------------------------------

local GAME_RULES_EN = _([[
Fifteen Puzzle — Rules

Reassemble the scrambled picture by sliding its pieces into the empty space.

Tap a piece adjacent to the empty space to slide it in.
Only pieces directly next to the empty space can move.
Goal: put every piece back in its original spot, with the empty space in the bottom-right corner.

The puzzle is always solvable. A new picture is picked at random for each new game.
]])

local GAME_RULES_FR = [[
Taquin — Règles

Reconstituez l'image mélangée en glissant ses morceaux dans l'espace vide.

Appuyez sur un morceau adjacent à l'espace vide pour le faire glisser. Seuls les morceaux directement à côté de l'espace vide peuvent bouger.

But : remettre chaque morceau à sa place d'origine, avec l'espace vide en bas à droite.

Le puzzle est toujours soluble. Une nouvelle image est choisie au hasard à chaque nouvelle partie.
]]

local FifteenScreen = ScreenBase:extend{}

function FifteenScreen:init()
    local state = self.plugin:loadState()
    local n     = self.plugin:getSetting("grid_n", FifteenBoard.DEFAULT_N)
    self.board  = FifteenBoard:new{ n = n }
    if not self.board:load(state) then
        -- fresh board from new()
    end
    ScreenBase.init(self)
end

function FifteenScreen:serializeState()
    return self.board:serialize()
end

function FifteenScreen:buildLayout()
    local is_landscape = self:isLandscape()

    local title_bar = self:buildTitleBar(_("Fifteen Puzzle"), function()
        return {
            { text = _("New game"),     callback = function() self:onNewGame() end },
            { text = self:_gridLabel(), callback = function() self:openGridMenu() end },
            self:makeRulesButtonConfig(GAME_RULES_EN, GAME_RULES_FR),
        }
    end)

    -- Tapping a piece is the only move: no action bar while
    -- playing. Once the round is over, a "New game" bar appears under the status.
    self.status_text:setMaxWidth(self:getControlsWidth())
    local bar = self:buildActionBar({})
    local controls = VerticalGroup:new{ align = "center", self.status_text }
    if bar.round_over then
        table.insert(controls, VerticalSpan:new{ width = Size.span.vertical_large })
        table.insert(controls, bar)
    end

    -- The widget draws its own thick outer border, so the frame only pads.
    local frame_pad = Size.padding.large
    local budget_w, budget_h = self:getBoardBudget(title_bar, controls)
    self.board_widget = FifteenBoardWidget:new{
        board      = self.board,
        max_width  = math.max(budget_w - 2 * frame_pad, 60),
        max_height = math.max(budget_h - 2 * frame_pad, 60),
        cellTapCallback  = function(r, c) self:onCellTap(r, c) end,
    }
    local board_frame = FrameContainer:new{
        padding    = frame_pad,
        margin     = 0,
        bordersize = 0,
        self.board_widget,
    }

    if is_landscape then
        local content = HorizontalGroup:new{
            align = "center",
            board_frame,
            HorizontalSpan:new{ width = self:getGutter() },
            controls,
        }
        self:buildLandscapeLayout(title_bar, content)
    else
        self:buildPortraitLayout(title_bar, board_frame,
            VerticalGroup:new{ align = "center", controls, VerticalSpan:new{ width = self:getGutter() } })
    end
    self:updateStatus()
end

function FifteenScreen:onCellTap(r, c)
    local moved = self.board:slide(r, c)
    if moved then
        self.board_widget:refresh()
        self:updateStatus()
        self.plugin:saveState(self.board:serialize())
        self:refreshActionBar()
        if self.board.won then
            local best_key = "best_moves_" .. self.board.n
            local best = self.plugin:getSetting(best_key)
            local moves = self.board.moves
            if not best or moves < best then
                self.plugin:saveSetting(best_key, moves)
            end
        end
    end
end

function FifteenScreen:isRoundOver()
    return self.board.won and true or false
end

-- The bar only exists once the round is over, so showing or hiding it
-- reflows the layout instead of swapping the bar in place.
function FifteenScreen:refreshActionBar()
    if self.action_bar and self:isRoundOver() ~= self.action_bar.round_over then
        self:buildLayout()
        UIManager:setDirty(self, function() return "ui", self.dimen end)
    end
end

function FifteenScreen:onNewGame()
    local n = self.plugin:getSetting("grid_n", FifteenBoard.DEFAULT_N)
    self.board:newGame(n)
    self.plugin:saveState(self.board:serialize())
    self:buildLayout()
    UIManager:setDirty(self, function() return "ui", self.dimen end)
end

function FifteenScreen:openGridMenu()
    local items = {}
    for _, n in ipairs(FifteenBoard.SIZES) do
        items[#items + 1] = { id = n, text = string.format("%d\xC3\x97%d", n, n) }
    end
    MenuHelper.openPickerMenu{
        title      = _("Size"),
        items      = items,
        current_id = self.plugin:getSetting("grid_n", FifteenBoard.DEFAULT_N),
        parent     = self,
        on_select  = function(n)
            self.plugin:saveSetting("grid_n", n)
            if self.grid_btn then
                self.grid_btn:setText(self:_gridLabel(), self.grid_btn.width)
            end
            self:onNewGame()
        end,
    }
end

function FifteenScreen:updateStatus(msg)
    local status
    if msg then
        status = msg
    elseif self.board.won then
        local best_key = "best_moves_" .. self.board.n
        local best = self.plugin:getSetting(best_key)
        status = T(_("Solved in %1 moves! Best: %2"), self.board.moves, best or self.board.moves)
    else
        local n    = self.board.n
        local best = self.plugin:getSetting("best_moves_" .. n)
        status = self:joinStatus(T("%1\xC3\x97%2", n, n),
            T(_("Moves: %1"), self.board.moves),
            T(_("Time: %1"), self.board.timer:format()),
            best and T(_("Best: %1"), best))
    end
    ScreenBase.updateStatus(self, status)
end

function FifteenScreen:_gridLabel()
    local n = self.plugin:getSetting("grid_n", FifteenBoard.DEFAULT_N)
    return T(_("Size: %1"), string.format("%d\xC3\x97%d", n, n))
end

return FifteenScreen
