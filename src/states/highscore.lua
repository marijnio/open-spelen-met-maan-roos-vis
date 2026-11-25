-- HighScore name-entry screen (highsy1/highsy2) and 6-game Top-5 leaderboard (score).

local utf8 = require("utf8")
local Assets = require("src.core.assets")
local HighScores = require("src.core.highscores")
local HotzoneManager = require("src.core.hotzone")
local ParentGateDialog = require("src.core.parent_gate_dialog")
local Viewport = require("src.core.viewport")

local HighScoreState = {}
HighScoreState.__index = HighScoreState

local GOOD_1P_VO = { "fdbgd1a", "fdbgd1b", "fdbgd1c" }
local GOOD_BOTH_VO = { "fdbgd2a", "fdbgd2b", "fdbgd2c" }
local GOOD_P2_ONLY_VO = { "fdbgd3a", "fdbgd3b" }
local GOOD_P1_ONLY_VO = { "fdbgd4a", "fdbgd4b" }

local BAD_1P_VO = { "fdbft1a", "fdbft1b", "fdbft1c" }
local BAD_2P_VO = { "fdbft2a", "fdbft2b", "fdbft2c" }

local ENTRY_BG_COLOR = { 204 / 255, 0, 51 / 255 }
local ENTRY_OFFSET_X = -32
local ENTRY_1P_OFFSET_Y = -56
local ENTRY_2P_FALLBACK_OFFSET_Y = -65

local BOX_X = 200 + ENTRY_OFFSET_X
local BOX_W = 200
local BOX_H = 29
local BOX_Y_1P = { 130 + ENTRY_1P_OFFSET_Y }
local BOX_Y_2P = { 43, 123 }
local BOX_Y_2P_FALLBACK = { 130 + ENTRY_2P_FALLBACK_OFFSET_Y, 240 + ENTRY_2P_FALLBACK_OFFSET_Y }
local SCORE_X = 430 + ENTRY_OFFSET_X

local ROW_HIT_X = 106 + ENTRY_OFFSET_X
local ROW_HIT_W = 295
local ROW_HIT_H = 60
local ROW_HIT_Y_1P = { 116 + ENTRY_1P_OFFSET_Y }
local ROW_HIT_Y_2P = { 29, 109 }
local ROW_HIT_Y_2P_FALLBACK = { 116 + ENTRY_2P_FALLBACK_OFFSET_Y, 226 + ENTRY_2P_FALLBACK_OFFSET_Y }

-- Compacted horizontal strips of highsy2.png so both name fields stay well above the Android keyboard.
local TWO_PLAYER_SLICES = {
  { sy = 72, sh = 22, dy = 7 },
  { sy = 116, sh = 80, dy = 29 },
  { sy = 226, sh = 60, dy = 109 },
  { sy = 315, sh = 22, dy = 169 },
}

local function pickRandom(pool)
  return pool[love.math.random(1, #pool)]
end

local function drawBoldText(text, x, y)
  love.graphics.print(text, x, y)
  love.graphics.print(text, x + 1, y)
end

local function drawBoldPrintf(text, x, y, limit, align)
  love.graphics.printf(text, x, y, limit, align)
  love.graphics.printf(text, x + 1, y, limit, align)
end

local function setVirtualKeyboard(enabled)
  if love and love.keyboard and love.keyboard.setTextInput then
    love.keyboard.setTextInput(enabled)
  end
end

local function fitTextToWidth(font, text, maxWidth)
  if font:getWidth(text) <= maxWidth then
    return text
  end
  local s = text
  while #s > 0 and font:getWidth(s) > maxWidth do
    local byteOffset = utf8.offset(s, -1)
    if not byteOffset then
      break
    end
    s = s:sub(1, byteOffset - 1)
  end
  return s
end

function HighScoreState.new(app)
  local self = setmetatable({}, HighScoreState)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.resetDialog = ParentGateDialog.new(app)
  self.handlesEscape = true

  self.entryFont = love.graphics.newFont(20)
  self.headerFont = love.graphics.newFont(19)
  self.rowFont = love.graphics.newFont(15)

  self.phase = "board"
  self.gameId = nil
  self.players = 1
  self.scores = {}
  self.qualified = { false, false }
  self.names = { "", "" }
  self.activeField = 1
  self.blinkTimer = 0
  self.returnTo = "hub"
  self.returnParams = nil
  self.twoPlayerQuads = nil
  self.twoPlayerQuadsBg = nil
  return self
end

function HighScoreState:enter(params)
  self.resetDialog:close()
  params = params or {}
  self.gameId = params.gameId
  self.players = params.players or 1
  self.scores = params.scores or {}
  self.returnTo = params.returnTo or "hub"
  self.returnParams = params.returnParams
  self.names = { "", "" }
  self.blinkTimer = 0
  self.qualified = { false, false }

  if self.gameId and self.scores[1] ~= nil then
    local q1 = HighScores.qualifies(self.gameId, self.scores[1])
    local q2 = (self.players == 2) and (self.scores[2] ~= nil) and HighScores.qualifies(self.gameId, self.scores[2])
    self.qualified = { q1, q2 }

    if q1 or q2 then
      local vo
      if q1 and q2 then
        vo = pickRandom(GOOD_BOTH_VO)
      elseif q1 and self.players == 1 then
        vo = pickRandom(GOOD_1P_VO)
      elseif q1 and self.players == 2 then
        vo = pickRandom(GOOD_P1_ONLY_VO)
      else
        vo = pickRandom(GOOD_P2_ONLY_VO)
      end
      self.app.audio:clearAndPlay("jantje", vo)
      self:_enterEntryPhase()
    else
      local vo = pickRandom(self.players == 2 and BAD_2P_VO or BAD_1P_VO)
      self.app.audio:clearAndPlay("jantje", vo)
      self:_enterBoardPhase()
    end
  else
    self:_enterBoardPhase()
  end
end

function HighScoreState:_enterEntryPhase()
  self.phase = "entry"
  self.activeField = self.qualified[1] and 1 or 2
  love.keyboard.setKeyRepeat(true)
  setVirtualKeyboard(true)
  self.hotzones:clear()

  self.hotzones:add({
    id = "ok",
    label = "OK",
    x = 572,
    y = 8,
    w = 60,
    h = 60,
    normalImage = { "ui", "okee" },
    hoverImage = { "ui", "oke2" },
    onClick = function()
      self:_confirmEntry()
    end,
  })
end

function HighScoreState:_confirmEntry()
  love.keyboard.setKeyRepeat(false)
  setVirtualKeyboard(false)
  if self.qualified[1] then
    HighScores.insert(self.gameId, self.names[1], self.scores[1])
  end
  if self.qualified[2] then
    HighScores.insert(self.gameId, self.names[2], self.scores[2])
  end
  self:_enterBoardPhase()
end

function HighScoreState:_enterBoardPhase()
  self.phase = "board"
  love.keyboard.setKeyRepeat(false)
  setVirtualKeyboard(false)
  self.hotzones:clear()

  self.hotzones:add({
    id = "terug",
    label = "Terug",
    x = 8,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "terug" },
    hoverImage = { "ui", "teru2" },
    onClick = function()
      self:_goBack()
    end,
  })

  self.hotzones:add({
    id = "clear_scores",
    label = "Opnieuw",
    x = 72,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "opnieuw" },
    hoverImage = { "ui", "opnieu2" },
    onClick = function()
      self.resetDialog:open(
        function()
          HighScores.reset()
          HighScores.save()
        end,
        nil,
        "Weet je zeker dat je alle scores wilt wissen?\nLos de som op om te bevestigen:",
        "Wissen!"
      )
    end,
  })
end

function HighScoreState:_goBack()
  self.app.audio:stop()
  self.app.scenes:switch(self.returnTo, self.returnParams)
end

function HighScoreState:exit()
  self.resetDialog:close()
  love.keyboard.setKeyRepeat(false)
  setVirtualKeyboard(false)
  self.hotzones:clear()
end

function HighScoreState:update(dt)
  if self.resetDialog:isOpen() then
    self.resetDialog:update(dt)
    return
  end

  self.blinkTimer = self.blinkTimer + dt
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)
end

function HighScoreState:_canUseCompactTwoPlayer(bg)
  if not bg then
    return false
  end
  local bw, bh = bg:getDimensions()
  return bw >= 640 and bh >= 337
end

function HighScoreState:_getTwoPlayerQuads(bg)
  if self.twoPlayerQuadsBg ~= bg then
    local bw, bh = bg:getDimensions()
    local quads = {}
    for i, slice in ipairs(TWO_PLAYER_SLICES) do
      quads[i] = {
        quad = love.graphics.newQuad(0, slice.sy, 640, slice.sh, bw, bh),
        dy = slice.dy,
      }
    end
    self.twoPlayerQuads = quads
    self.twoPlayerQuadsBg = bg
  end
  return self.twoPlayerQuads
end

function HighScoreState:_getEntryFieldGeometry(field)
  if self.players == 2 then
    local bg = Assets.getImage("screens", "highsy2")
    if self:_canUseCompactTwoPlayer(bg) then
      return BOX_Y_2P[field], ROW_HIT_Y_2P[field]
    end
    return BOX_Y_2P_FALLBACK[field], ROW_HIT_Y_2P_FALLBACK[field]
  end
  return BOX_Y_1P[field], ROW_HIT_Y_1P[field]
end

function HighScoreState:_drawEntryField(field)
  local y = self:_getEntryFieldGeometry(field)
  local text = self.names[field]

  love.graphics.setFont(self.entryFont)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(text, BOX_X + 4, y + 3)

  if self.activeField == field and (math.floor(self.blinkTimer * 2) % 2 == 0) then
    local caretX = BOX_X + 4 + self.entryFont:getWidth(text)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(caretX, y + 3, caretX, y + BOX_H - 3)
    love.graphics.setLineWidth(1)
  end

  love.graphics.print(tostring(self.scores[field] or 0), SCORE_X, y + 3)
end

function HighScoreState:_drawEntry()
  love.graphics.setColor(ENTRY_BG_COLOR[1], ENTRY_BG_COLOR[2], ENTRY_BG_COLOR[3], 1)
  love.graphics.rectangle("fill", 0, 0, Viewport.VIRTUAL_W, Viewport.VIRTUAL_H)
  love.graphics.setColor(1, 1, 1, 1)

  local screenKey = (self.players == 2) and "highsy2" or "highsy1"
  local bg = Assets.getImage("screens", screenKey)
  if bg then
    if self.players == 2 and self:_canUseCompactTwoPlayer(bg) then
      for _, slice in ipairs(self:_getTwoPlayerQuads(bg)) do
        love.graphics.draw(bg, slice.quad, ENTRY_OFFSET_X, slice.dy)
      end
    elseif self.players == 2 then
      love.graphics.draw(bg, ENTRY_OFFSET_X, ENTRY_2P_FALLBACK_OFFSET_Y)
    else
      love.graphics.draw(bg, ENTRY_OFFSET_X, ENTRY_1P_OFFSET_Y)
    end
  end

  if self.qualified[1] then
    self:_drawEntryField(1)
  end
  if self.players == 2 and self.qualified[2] then
    self:_drawEntryField(2)
  end
end

function HighScoreState:_drawBoard()
  local bg = Assets.getImage("screens", "score")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  local baseX = 60
  local colStep = 190
  local rowStep = 24
  local blockRowStep = 190
  local baseY = 40

  for idx = 0, #HighScores.GAMES - 1 do
    local game = HighScores.GAMES[idx + 1]
    local col = idx % 3
    local rowBlock = math.floor(idx / 3)
    local titleX = baseX + col * colStep - 16
    local titleY = baseY + rowBlock * blockRowStep

    love.graphics.setFont(self.headerFont)
    love.graphics.setColor(208 / 255, 0, 0, 1)
    drawBoldText(game.title, titleX, titleY)

    local entries = HighScores.getEntries(game.id) or {}
    love.graphics.setFont(self.rowFont)
    love.graphics.setColor(0, 0, 0, 1)

    for r = 1, HighScores.MAX_ENTRIES do
      local entry = entries[r] or { name = "-", score = 0 }
      local ey = titleY + (r - 1) * rowStep + 32
      drawBoldText(tostring(r) .. ".", titleX, ey)
      local fittedName = fitTextToWidth(self.rowFont, entry.name or "-", 96)
      drawBoldText(fittedName, baseX + col * colStep, ey)
      drawBoldPrintf(tostring(entry.score or 0), baseX + col * colStep + 100, ey, 40, "right")
    end
  end
end

function HighScoreState:draw()
  if self.phase == "entry" then
    self:_drawEntry()
  else
    self:_drawBoard()
  end

  love.graphics.setColor(1, 1, 1, 1)
  self.hotzones:draw(self.app.debugHotzones)

  if self.resetDialog:isOpen() then
    self.resetDialog:draw()
  end
end

function HighScoreState:mousepressed(vx, vy, button)
  if self.resetDialog:isOpen() then
    return self.resetDialog:mousepressed(vx, vy, button)
  end

  if self.hotzones:mousepressed(vx, vy, button) then
    return
  end
  if self.phase == "entry" and button == 1 then
    for field = 1, 2 do
      if self.qualified[field] then
        local _, rowY = self:_getEntryFieldGeometry(field)
        if vx >= ROW_HIT_X and vx <= (ROW_HIT_X + ROW_HIT_W) and vy >= rowY and vy <= (rowY + ROW_HIT_H) then
          self.activeField = field
          self.blinkTimer = 0
          setVirtualKeyboard(true)
          return
        end
      end
    end
  end
end

function HighScoreState:textinput(text)
  if self.resetDialog:isOpen() then
    return
  end
  if self.phase ~= "entry" or type(text) ~= "string" then
    return
  end
  local cleaned = text:gsub("[%c]", "")
  if cleaned == "" then
    return
  end
  local cur = self.names[self.activeField] or ""
  local len = utf8.len(cur) or #cur
  if len >= 14 then
    return
  end
  local candidate = cur .. cleaned
  if self.entryFont:getWidth(candidate) <= 188 then
    self.names[self.activeField] = candidate
    self.blinkTimer = 0
  end
end

function HighScoreState:keypressed(key)
  if self.resetDialog:isOpen() then
    return self.resetDialog:keypressed(key)
  end

  if self.phase == "entry" then
    if key == "backspace" then
      local cur = self.names[self.activeField] or ""
      local byteOffset = utf8.offset(cur, -1)
      if byteOffset then
        self.names[self.activeField] = cur:sub(1, byteOffset - 1)
        self.blinkTimer = 0
      end
    elseif key == "tab" then
      if self.players == 2 and self.qualified[1] and self.qualified[2] then
        self.activeField = (self.activeField == 1) and 2 or 1
        self.blinkTimer = 0
      end
    elseif key == "return" or key == "kpenter" then
      if self.activeField == 1 and self.players == 2 and self.qualified[2] then
        self.activeField = 2
        self.blinkTimer = 0
      else
        self:_confirmEntry()
      end
    elseif key == "escape" then
      self:_enterBoardPhase()
    end
  elseif self.phase == "board" then
    if key == "escape" then
      self:_goBack()
    end
  end
end

return HighScoreState
