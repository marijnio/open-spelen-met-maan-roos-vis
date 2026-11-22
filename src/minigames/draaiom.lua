-- Mini-game 3: Draai maar om (Draaiom)

local Assets = require("src.core.assets")
local ConfirmDialog = require("src.core.confirm_dialog")
local Cursor = require("src.core.cursor")
local HotzoneManager = require("src.core.hotzone")

local DraaiomGame = {}
DraaiomGame.__index = DraaiomGame

local LEVEL_WORDS = {
  [1] = {
    { word = "maan", phonemes = { "m", "aa", "n" } },
    { word = "roos", phonemes = { "r", "oo", "s" } },
    { word = "vis",  phonemes = { "v", "i", "s" } },
    { word = "pen",  phonemes = { "p", "e", "n" } },
  },
  [2] = {
    { word = "oog",  phonemes = { "oo", "g" } },
    { word = "aap",  phonemes = { "aa", "p" } },
    { word = "buik", phonemes = { "b", "ui", "k" } },
    { word = "teen", phonemes = { "t", "ee", "n" } },
  },
  [3] = {
    { word = "poes", phonemes = { "p", "oe", "s" } },
    { word = "doos", phonemes = { "d", "oo", "s" } },
    { word = "eet",  phonemes = { "ee", "t" } },
    { word = "ijs",  phonemes = { "ij", "s" } },
  },
  [4] = {
    { word = "ik",   phonemes = { "i", "k" } },
    { word = "sok",  phonemes = { "s", "o", "k" } },
    { word = "neus", phonemes = { "n", "eu", "s" } },
    { word = "zeep", phonemes = { "z", "ee", "p" } },
  },
  [5] = {
    { word = "weg",  phonemes = { "w", "e", "g" } },
    { word = "huis", phonemes = { "h", "ui", "s" } },
    { word = "bos",  phonemes = { "b", "o", "s" } },
    { word = "hut",  phonemes = { "h", "u", "t" } },
  },
  [6] = {
    { word = "jas",  phonemes = { "j", "a", "s" } },
    { word = "riem", phonemes = { "r", "ie", "m" } },
    { word = "bijl", phonemes = { "b", "ij", "l" } },
    { word = "vuur", phonemes = { "v", "uu", "r" } },
  },
  [7] = {
    { word = "geit", phonemes = { "g", "ei", "t" } },
    { word = "uil",  phonemes = { "ui", "l" } },
    { word = "pauw", phonemes = { "p", "au", "w" } },
    { word = "duif", phonemes = { "d", "ui", "f" } },
  },
  [8] = {
    { word = "tak",  phonemes = { "t", "a", "k" } },
    { word = "hout", phonemes = { "h", "ou", "t" } },
    { word = "reus", phonemes = { "r", "eu", "s" } },
    { word = "ei",   phonemes = { "ei" } },
  },
}

local TILE_PERM = {
  { 1, 2, 3, 4 },
  { 2, 1, 3, 4 },
  { 3, 2, 1, 4 },
  { 4, 2, 3, 1 },
  { 1, 3, 2, 4 },
  { 1, 4, 3, 2 },
  { 1, 2, 4, 3 },
}

local GRID_SIZE = 3
local TILE_SIZE = 120
local BOARD_SIZE = 360
local BOARD_X = 136
local BOARD_Y = 15
local FRAME_X = 135
local FRAME_Y = 14
local FRAME_W = 362
local FRAME_H = 362

local IMG_W = 362
local IMG_H = 362

local SIDE_SIZE = 90
local SIDE_SLOTS = {
  { x = 23,  y = 41 },
  { x = 517, y = 41 },
  { x = 23,  y = 281 },
  { x = 517, y = 281 },
}

local BAR_Y = 412
local BAR_H = 68

local TIMER_MAX = 100
local TIMER_TICK_INTERVAL = 0.875
local FLIP_DURATION = 0.14
local CELEBRATE_PRE_SPEECH = 0.45
local CELEBRATE_POST_SOLVED = 1.2
local CELEBRATE_POST_DUP = 1.5
local CELEBRATE_TURN_PAUSE = 0.5
local RECAP_PRE_SPEECH = 0.35
local RECAP_POST_SPEECH = 0.75
local REVEAL_DELAY = 1.2
local FINISH_DELAY = 2.0

local function drawCenteredBold(font, text, x, y, w)
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
  love.graphics.printf(text, x + 1, y, w, "center")
end

local function pointInRect(px, py, rx, ry, rw, rh)
  return px >= rx and px < (rx + rw) and py >= ry and py < (ry + rh)
end

local function drawBevelRect(x, y, w, h, sunken)
  local tl = sunken and 0.5 or 1.0
  local br = sunken and 1.0 or 0.5
  local x1 = x + 0.5
  local y1 = y + 0.5
  local x2 = x + w - 0.5
  local y2 = y + h - 0.5

  love.graphics.setColor(tl, tl, tl, 1)
  love.graphics.line(x1, y2, x1, y1, x2, y1)
  love.graphics.setColor(br, br, br, 1)
  love.graphics.line(x2, y1 + 1, x2, y2, x1 + 1, y2)
end

local function drawTileBevel(x, y, size)
  local x1 = x + 0.5
  local y1 = y + 0.5
  local x2 = x + size - 0.5
  local y2 = y + size - 0.5

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.line(x1, y2, x1, y1, x2, y1)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.line(x2, y1 + 1, x2, y2, x1 + 1, y2)
end

local function drawOutlinedPhoneme(font, text, x, y, w, h, outlinePx)
  if text == nil or text == "" then
    return
  end

  love.graphics.setFont(font)
  local tw = font:getWidth(text)
  local th = font:getHeight()
  local maxW = w - 4
  local sx = (tw > maxW and tw > 0) and (maxW / tw) or 1
  local tx = x + math.floor((w - tw * sx) * 0.5)
  local ty = y + math.floor((h - th) * 0.5)

  love.graphics.setColor(0, 0, 0, 1)
  for dx = -outlinePx, outlinePx do
    for dy = -outlinePx, outlinePx do
      if dx ~= 0 or dy ~= 0 then
        love.graphics.print(text, tx + dx, ty + dy, 0, sx, 1)
      end
    end
  end

  love.graphics.setColor(1, 1, 0, 1)
  love.graphics.print(text, tx, ty, 0, sx, 1)
end

function DraaiomGame.new(app)
  local self = setmetatable({}, DraaiomGame)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.confirmDialog = ConfirmDialog.new(app)
  self.handlesEscape = true

  self.handCursor = Cursor.getSystem("hand")
  self.arrowCursor = Cursor.getSystem("arrow")
  self.waitCursor = Cursor.getSystem("wait") or self.arrowCursor

  self.levelFont = love.graphics.newFont(16)
  self.badgeFont = love.graphics.newFont(12)
  self.scoreFont = love.graphics.newFont(15)
  self.tileLetterFont = love.graphics.newFont(62)
  self.thumbLetterFont = love.graphics.newFont(16)

  self.fullQuad = love.graphics.newQuad(1, 1, BOARD_SIZE, BOARD_SIZE, IMG_W, IMG_H)
  self.tileQuads = {}
  for row = 0, GRID_SIZE - 1 do
    for col = 0, GRID_SIZE - 1 do
      local idx = row * GRID_SIZE + col + 1
      self.tileQuads[idx] = love.graphics.newQuad(
        1 + col * TILE_SIZE,
        1 + row * TILE_SIZE,
        TILE_SIZE,
        TILE_SIZE,
        IMG_W,
        IMG_H
      )
    end
  end

  self.level = 1
  self.players = 1
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.solved = { false, false, false, false }
  self.solvedCount = 0

  self.phase = "settings"
  self.subPhase = nil
  self.phaseTimer = 0
  self.celebrateImg = nil
  self.recapIndex = 1
  self.recapSubPhase = nil
  self.tiles = {}

  self:_initTiles()
  return self
end

function DraaiomGame:_levelEntries()
  return LEVEL_WORDS[self.level] or LEVEL_WORDS[1]
end

function DraaiomGame:_stepForImage(permRow, targetImg)
  local perm = TILE_PERM[permRow]
  for step = 1, 4 do
    if perm[step] == targetImg then
      return step
    end
  end
  return 1
end

function DraaiomGame:_initTiles()
  self.tiles = {}
  for row = 0, GRID_SIZE - 1 do
    for col = 0, GRID_SIZE - 1 do
      local cellIdx = row * GRID_SIZE + col
      local permRow = (cellIdx % #TILE_PERM) + 1
      table.insert(self.tiles, {
        col = col,
        row = row,
        cellIdx = cellIdx,
        permRow = permRow,
        step = self:_stepForImage(permRow, 1),
        fromImg = 1,
        toImg = 1,
        flipProgress = 1,
      })
    end
  end
end

function DraaiomGame:_tileAt(col, row)
  return self.tiles[row * GRID_SIZE + col + 1]
end

function DraaiomGame:_setTileImage(tile, targetImg, animate)
  local prevImg = tile.toImg
  tile.step = self:_stepForImage(tile.permRow, targetImg)
  tile.fromImg = prevImg
  tile.toImg = targetImg
  tile.flipProgress = animate and 0 or 1
end

function DraaiomGame:_setAllTilesTo(targetImg, animate)
  for _, tile in ipairs(self.tiles) do
    self:_setTileImage(tile, targetImg, animate)
  end
end

function DraaiomGame:_flipTileNext(col, row, animate)
  local tile = self:_tileAt(col, row)
  if not tile then
    return
  end
  local prevImg = tile.toImg
  tile.step = (tile.step % 4) + 1
  tile.fromImg = prevImg
  tile.toImg = TILE_PERM[tile.permRow][tile.step]
  tile.flipProgress = animate and 0 or 1
end

function DraaiomGame:_checkSolvedImage()
  local firstImg = self.tiles[1].toImg
  for i = 2, #self.tiles do
    if self.tiles[i].toImg ~= firstImg then
      return nil
    end
  end
  return firstImg
end

function DraaiomGame:_scrambleInitial()
  self:_setAllTilesTo(1, false)
  local targetImg = love.math.random(2, 4)
  for _ = 1, 7 do
    local id = love.math.random(1, 8)
    self:_setTileImage(self.tiles[id], targetImg, true)
  end
  local solved = self:_checkSolvedImage()
  if solved ~= nil then
    local other = (solved == 1) and targetImg or 1
    self:_setTileImage(self.tiles[1], other, true)
  end
end

function DraaiomGame:_scrambleAfterSolve(solvedImg, isDuplicate)
  if isDuplicate then
    for _ = 1, 4 do
      local id = love.math.random(1, 9)
      local targetImg = love.math.random(2, 4)
      self:_setTileImage(self.tiles[id], targetImg, true)
    end
    local stillSolved = self:_checkSolvedImage()
    if stillSolved ~= nil then
      local other = (stillSolved % 4) + 1
      self:_setTileImage(self.tiles[1], other, true)
    end
  else
    self:_scrambleInitial()
  end
end

function DraaiomGame:_syncHover()
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:syncHover(vx, vy)
end

function DraaiomGame:_setOpnieuwEnabled(enabled)
  local opZone = self.hotzones:getById("opnieuw")
  if opZone then
    opZone.enabled = enabled
  end
end

function DraaiomGame:_addBaseChromeHotzones(helpVoProvider, onTerug)
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
      self.app.audio:stop()
      if onTerug then
        onTerug()
      else
        self.app.scenes:switch("hub")
      end
    end,
  })

  self.hotzones:add({
    id = "help",
    label = "Help",
    x = 72,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "help" },
    hoverImage = { "ui", "hel2" },
    onClick = function()
      self.app.audio:clearAndPlay("jantje", helpVoProvider())
    end,
  })
end

function DraaiomGame:_enterSettings()
  self.phase = "settings"
  self.subPhase = nil
  self.phaseTimer = 0
  self.celebrateImg = nil
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.solved = { false, false, false, false }
  self.solvedCount = 0
  self.app.audio:stop()

  self:_setAllTilesTo(1, false)

  self.hotzones:clear()
  self:_addBaseChromeHotzones(function()
    return "nivinshp"
  end)

  for lvl = 1, 8 do
    self.hotzones:add({
      id = "level_" .. lvl,
      label = "Niveau " .. lvl,
      x = 200 + (lvl - 1) * 30,
      y = 416,
      w = 30,
      h = 30,
      onClick = function()
        self.level = lvl
      end,
    })
  end

  self.hotzones:add({
    id = "start_2p",
    label = "2 spelers",
    x = 508,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "startwee" },
    hoverImage = { "ui", "startwe2" },
    onClick = function()
      self:_startGame(2)
    end,
  })

  self.hotzones:add({
    id = "start_1p",
    label = "1 speler",
    x = 572,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "starteen" },
    hoverImage = { "ui", "startee2" },
    onClick = function()
      self:_startGame(1)
    end,
  })

  self:_syncHover()
end

function DraaiomGame:_startGame(players)
  self.phase = "playing"
  self.subPhase = nil
  self.phaseTimer = 0
  self.players = players
  self.activePlayer = love.math.random(1, players)
  self.scores = { 0, 0 }
  self.timers = { TIMER_MAX, (players == 2) and TIMER_MAX or 0 }
  self.timerAccum = 0
  self.solved = { false, false, false, false }
  self.solvedCount = 0
  self.celebrateImg = nil
  self.recapIndex = 1
  self.recapSubPhase = nil
  self.app.audio:stop()

  self.hotzones:clear()
  self:_addBaseChromeHotzones(function()
    return "drasphp1"
  end, function()
    self.confirmDialog:open(function()
      self.app.audio:stop()
      self:_enterSettings()
    end)
  end)

  self:_syncHover()
  self:_scrambleInitial()
end

function DraaiomGame:_triggerOpnieuw()
  if self.phase ~= "playing" and self.phase ~= "solving_flip" and self.phase ~= "celebrating" then
    return
  end
  if self.solvedCount >= 4 then
    return
  end

  self.app.audio:stop()
  self:_setOpnieuwEnabled(false)
  self:_setAllTilesTo(1, false)
  self.phase = "revealing"
  self.subPhase = nil
  self.phaseTimer = REVEAL_DELAY
end

function DraaiomGame:_switchTurnIfTwoPlayer()
  if self.players ~= 2 then
    return
  end
  local other = (self.activePlayer == 1) and 2 or 1
  if self.timers[other] > 0 then
    self.activePlayer = other
  end
  self.timerAccum = 0
end

function DraaiomGame:_enterFinishing()
  self:_setOpnieuwEnabled(false)
  self.phase = "finishing"
  self.subPhase = nil
  self.phaseTimer = FINISH_DELAY
  self.app.audio:playSfx("gong")
end

function DraaiomGame:_playWordBreakdown(entry)
  local seq = {}
  for _, ph in ipairs(entry.phonemes) do
    table.insert(seq, { "words", ph })
  end
  table.insert(seq, { "words", entry.word })
  self.app.audio:playSequence(seq, { gap = 0.35 })
end

function DraaiomGame:enter(params)
  local lvl = tonumber(params and params.level) or 1
  self.level = math.max(1, math.min(8, math.floor(lvl)))
  self:_enterSettings()
end

function DraaiomGame:exit()
  self.confirmDialog:close()
  self.hotzones:clear()
  Cursor.set(self.arrowCursor)
end

function DraaiomGame:_updateCursor(vx, vy)
  if self.hotzones.hoveredId then
    return
  end
  if self.phase == "playing" then
    local onBoard = pointInRect(vx, vy, BOARD_X, BOARD_Y, BOARD_SIZE, BOARD_SIZE)
    Cursor.set(onBoard and self.handCursor or self.arrowCursor)
  elseif self.phase ~= "settings" then
    Cursor.set(self.waitCursor)
  end
end

function DraaiomGame:update(dt)
  if self.confirmDialog:isOpen() then
    self.confirmDialog:update(dt)
    return
  end

  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)

  if self.phase ~= "settings" then
    for _, tile in ipairs(self.tiles) do
      if tile.flipProgress < 1 then
        tile.flipProgress = math.min(1, tile.flipProgress + dt / FLIP_DURATION)
      end
    end
  end

  if self.phase == "playing" then
    self.timerAccum = self.timerAccum + dt
    while self.timerAccum >= TIMER_TICK_INTERVAL do
      self.timerAccum = self.timerAccum - TIMER_TICK_INTERVAL
      if self.timers[self.activePlayer] > 0 then
        self.timers[self.activePlayer] = self.timers[self.activePlayer] - 1
      end
      if self.timers[self.activePlayer] <= 0 then
        self.timers[self.activePlayer] = 0
        self.app.audio:playSfx("fout2")
        local other = (self.activePlayer == 1) and 2 or 1
        if self.players == 2 and self.timers[other] > 0 then
          self.activePlayer = other
          self.timerAccum = 0
        else
          self:_setOpnieuwEnabled(false)
          self.app.audio:clearAndPlay("sfx", "afgelope")
          self.phase = "timeout_finish"
        end
        break
      end
    end
  elseif self.phase == "solving_flip" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self.phase = "celebrating"
      self.subPhase = "pre_speech"
      self.phaseTimer = CELEBRATE_PRE_SPEECH
    end
  elseif self.phase == "celebrating" then
    if self.subPhase == "pre_speech" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        local entry = self:_levelEntries()[self.celebrateImg]
        self:_playWordBreakdown(entry)
        self.subPhase = "speaking"
      end
    elseif self.subPhase == "speaking" then
      if not self.app.audio:isPlaying() then
        if self.solved[self.celebrateImg] then
          self.subPhase = "post_dup"
          self.phaseTimer = CELEBRATE_POST_DUP
        else
          self.solved[self.celebrateImg] = true
          self.solvedCount = self.solvedCount + 1
          self.scores[self.activePlayer] = self.scores[self.activePlayer]
            + self.timers[self.activePlayer]
            + (self.level - 1)
          if self.solvedCount >= 4 then
            self.timers = { 0, 0 }
            self:_setOpnieuwEnabled(false)
            self.subPhase = "post_win"
            self.phaseTimer = CELEBRATE_POST_SOLVED
          else
            self.subPhase = "post_solved"
            self.phaseTimer = CELEBRATE_POST_SOLVED
          end
        end
      end
    elseif self.subPhase == "post_dup" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        self:_scrambleAfterSolve(self.celebrateImg, true)
        self.phase = "playing"
        self.subPhase = nil
      end
    elseif self.subPhase == "post_solved" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        self:_switchTurnIfTwoPlayer()
        self.subPhase = "turn_pause"
        self.phaseTimer = (self.players == 2) and CELEBRATE_TURN_PAUSE or 0.15
      end
    elseif self.subPhase == "turn_pause" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        self:_scrambleAfterSolve(self.celebrateImg, false)
        self.phase = "playing"
        self.subPhase = nil
      end
    elseif self.subPhase == "post_win" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        self.phase = "recap"
        self.recapIndex = 1
        self.recapSubPhase = "pre"
        self.phaseTimer = RECAP_PRE_SPEECH
      end
    end
  elseif self.phase == "recap" then
    if self.recapSubPhase == "pre" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        local entry = self:_levelEntries()[self.recapIndex]
        self.app.audio:clearAndPlay("words", entry.word)
        self.recapSubPhase = "speaking"
      end
    elseif self.recapSubPhase == "speaking" then
      if not self.app.audio:isPlaying() then
        self.recapSubPhase = "post"
        self.phaseTimer = RECAP_POST_SPEECH
      end
    elseif self.recapSubPhase == "post" then
      self.phaseTimer = self.phaseTimer - dt
      if self.phaseTimer <= 0 then
        self.recapIndex = self.recapIndex + 1
        if self.recapIndex <= 4 then
          self.recapSubPhase = "pre"
          self.phaseTimer = RECAP_PRE_SPEECH
        else
          self:_enterFinishing()
        end
      end
    end
  elseif self.phase == "revealing" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self:_enterSettings()
    end
  elseif self.phase == "timeout_finish" then
    if not self.app.audio:isPlaying() then
      self:_enterFinishing()
    end
  elseif self.phase == "finishing" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self.app.scenes:switch("highscore", {
        gameId = "draaiom",
        players = self.players,
        scores = { self.scores[1], self.scores[2] },
        returnTo = "draaiom",
        returnParams = { level = math.min(8, self.level + 1) },
      })
    end
  end

  self:_updateCursor(vx, vy)
end

function DraaiomGame:_drawFullWordImage(word, x, y, size)
  local img = Assets.getImage("draaiom", word)
  if img then
    love.graphics.setColor(1, 1, 1, 1)
    local iw, ih = img:getDimensions()
    if iw == IMG_W and ih == IMG_H and self.fullQuad then
      local s = size / BOARD_SIZE
      love.graphics.draw(img, self.fullQuad, x, y, 0, s, s)
    else
      love.graphics.draw(img, x, y, 0, size / iw, size / ih)
    end
  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", x, y, size, size)
  end
end

function DraaiomGame:_drawTile(col, row, showLetters)
  local tile = self:_tileAt(col, row)
  local tx = BOARD_X + col * TILE_SIZE
  local ty = BOARD_Y + row * TILE_SIZE

  local imgIdx
  local band = 0
  if tile.flipProgress < 0.5 then
    imgIdx = tile.fromImg
    band = math.floor(59 * (tile.flipProgress / 0.5))
  else
    imgIdx = tile.toImg
    band = math.floor(59 * (1 - (tile.flipProgress - 0.5) / 0.5))
  end

  local entry = self:_levelEntries()[imgIdx]
  local img = entry and Assets.getImage("draaiom", entry.word)
  if img then
    love.graphics.setColor(1, 1, 1, 1)
    local iw, ih = img:getDimensions()
    local quad = self.tileQuads[tile.cellIdx + 1]
    if iw == IMG_W and ih == IMG_H and quad then
      love.graphics.draw(img, quad, tx, ty)
    else
      local cellW = iw / GRID_SIZE
      local cellH = ih / GRID_SIZE
      local fallbackQuad = love.graphics.newQuad(col * cellW, row * cellH, cellW, cellH, iw, ih)
      love.graphics.draw(img, fallbackQuad, tx, ty, 0, TILE_SIZE / cellW, TILE_SIZE / cellH)
    end
  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", tx, ty, TILE_SIZE, TILE_SIZE)
  end

  if showLetters and row == 2 and entry then
    local phoneme = entry.phonemes[col + 1]
    if phoneme then
      drawOutlinedPhoneme(self.tileLetterFont, phoneme, tx + 4, ty + 4, TILE_SIZE - 8, TILE_SIZE - 8, 2)
    end
  end

  if band > 0 then
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", tx + 1, ty + 1, TILE_SIZE - 2, band)
    love.graphics.rectangle("fill", tx + 1, ty + TILE_SIZE - 1 - band, TILE_SIZE - 2, band)
  end

  drawTileBevel(tx, ty, TILE_SIZE)
end

function DraaiomGame:_drawSeamlessImage(imgIdx, showLetters)
  local entry = self:_levelEntries()[imgIdx]
  if not entry then
    return
  end
  self:_drawFullWordImage(entry.word, BOARD_X, BOARD_Y, BOARD_SIZE)

  if showLetters then
    local rowY = BOARD_Y + 2 * TILE_SIZE
    for col = 0, GRID_SIZE - 1 do
      local phoneme = entry.phonemes[col + 1]
      if phoneme then
        drawOutlinedPhoneme(
          self.tileLetterFont,
          phoneme,
          BOARD_X + col * TILE_SIZE + 4,
          rowY + 4,
          TILE_SIZE - 8,
          TILE_SIZE - 8,
          2
        )
      end
    end
  end
end

function DraaiomGame:_drawSideThumbnail(slotIdx, showImage, showLetters)
  local slot = SIDE_SLOTS[slotIdx]
  local sx, sy = slot.x, slot.y

  if not showImage then
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", sx, sy, SIDE_SIZE, SIDE_SIZE)
    drawBevelRect(sx, sy, SIDE_SIZE, SIDE_SIZE, false)
    return
  end

  local entry = self:_levelEntries()[slotIdx]
  if entry then
    self:_drawFullWordImage(entry.word, sx, sy, SIDE_SIZE)
    if showLetters then
      for col = 0, GRID_SIZE - 1 do
        local phoneme = entry.phonemes[col + 1]
        if phoneme then
          drawOutlinedPhoneme(self.thumbLetterFont, phoneme, sx + col * 30, sy + 60, 30, 30, 1)
        end
      end
    end
  end

  drawBevelRect(sx, sy, SIDE_SIZE, SIDE_SIZE, true)
end

function DraaiomGame:_drawPlayerHud(panelX, playerIndex, isActive)
  local spriteKey
  if playerIndex == 1 then
    spriteKey = isActive and "tijdsc1p" or "tijdsc11"
  else
    spriteKey = isActive and "tijdsc2p" or "tijdsc21"
  end

  local panelImg = Assets.getImage("ui", spriteKey)
  if panelImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(panelImg, panelX, 416)
  end

  if isActive then
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", panelX + 1, 417, 13, 16)
    love.graphics.setColor(1, 1, 1, 1)
    local badgeY = 417 + math.floor((16 - self.badgeFont:getHeight()) * 0.5)
    drawCenteredBold(self.badgeFont, tostring(self.level), panelX + 1, badgeY, 13)
  end

  local percent = math.max(0, math.min(100, self.timers[playerIndex] or 0))
  if percent > 0 then
    local bx = panelX + 70
    local by = 461
    local bw = 46
    local bh = 11

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", bx + 0.5, by + 0.5, bw - 1, bh - 1)

    local fillW = math.floor(percent * (bw - 2) / 100)
    if fillW > 0 then
      if percent > 20 then
        love.graphics.setColor(0, 1, 0, 1)
      else
        love.graphics.setColor(1, 0, 0, 1)
      end
      love.graphics.rectangle("fill", bx + 1, by + 1, fillW, bh - 2)
    end
  end

  love.graphics.setColor(0, 0, 0, 1)
  drawCenteredBold(self.scoreFont, tostring(self.scores[playerIndex] or 0), panelX + 131, 452, 40)
end

function DraaiomGame:_drawSettings()
  local bg = Assets.getImage("screens", "mem_0")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(200 / 255, 1, 200 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  for row = 0, GRID_SIZE - 1 do
    for col = 0, GRID_SIZE - 1 do
      self:_drawTile(col, row, false)
    end
  end
  drawBevelRect(FRAME_X, FRAME_Y, FRAME_W, FRAME_H, false)

  for i = 1, 4 do
    self:_drawSideThumbnail(i, true, false)
  end

  love.graphics.setColor(0, 0, 130 / 255, 1)
  love.graphics.rectangle("fill", 0, BAR_Y, 640, BAR_H)

  local levelTextY = 416 + math.floor((30 - self.levelFont:getHeight()) * 0.5)
  for lvl = 1, 8 do
    local bx = 200 + (lvl - 1) * 30
    local by = 416
    if lvl == self.level then
      love.graphics.setColor(1, 1, 71 / 255, 1)
    else
      love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.rectangle("fill", bx, by, 30, 30)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", bx + 0.5, by + 0.5, 29, 29)
    drawCenteredBold(self.levelFont, tostring(lvl), bx, levelTextY, 30)
  end
end

function DraaiomGame:_drawPlaying()
  local bg = Assets.getImage("screens", "draaiom")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(1, 102 / 255, 51 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  if self.phase == "celebrating" and self.celebrateImg then
    self:_drawSeamlessImage(self.celebrateImg, true)
  elseif self.phase == "recap" then
    self:_drawSeamlessImage(self.recapIndex, true)
  elseif self.phase == "finishing" and self.solvedCount >= 4 then
    self:_drawSeamlessImage(4, true)
  else
    local showLetters = (self.phase ~= "revealing")
    for row = 0, GRID_SIZE - 1 do
      for col = 0, GRID_SIZE - 1 do
        self:_drawTile(col, row, showLetters)
      end
    end
  end
  drawBevelRect(FRAME_X, FRAME_Y, FRAME_W, FRAME_H, false)

  if self.phase == "revealing" then
    for i = 1, 4 do
      self:_drawSideThumbnail(i, true, false)
    end
  elseif self.solvedCount > 0 then
    for i = 1, 4 do
      self:_drawSideThumbnail(i, self.solved[i], true)
    end
  end

  love.graphics.setColor(0, 0, 130 / 255, 1)
  love.graphics.rectangle("fill", 0, BAR_Y, 640, BAR_H)

  if self.players == 1 then
    self:_drawPlayerHud(260, 1, true)
  else
    self:_drawPlayerHud(140, 1, self.activePlayer == 1)
    self:_drawPlayerHud(324, 2, self.activePlayer == 2)
  end
end

function DraaiomGame:draw()
  if self.phase == "settings" then
    self:_drawSettings()
  else
    self:_drawPlaying()
  end

  love.graphics.setColor(1, 1, 1, 1)
  self.hotzones:draw(self.app.debugHotzones)

  if self.confirmDialog:isOpen() then
    self.confirmDialog:draw()
  end
end

function DraaiomGame:mousepressed(vx, vy, button)
  if self.confirmDialog:isOpen() then
    return self.confirmDialog:mousepressed(vx, vy, button)
  end

  if self.hotzones:mousepressed(vx, vy, button) then
    return true
  end

  if self.phase ~= "playing" or button ~= 1 then
    return false
  end

  if not pointInRect(vx, vy, BOARD_X, BOARD_Y, BOARD_SIZE, BOARD_SIZE) then
    return false
  end

  local col = math.floor((vx - BOARD_X) / TILE_SIZE)
  local row = math.floor((vy - BOARD_Y) / TILE_SIZE)
  self:_flipTileNext(col, row, true)

  local solvedImg = self:_checkSolvedImage()
  if solvedImg then
    self.celebrateImg = solvedImg
    self.phase = "solving_flip"
    self.phaseTimer = FLIP_DURATION
  end

  return true
end

function DraaiomGame:keypressed(key)
  if self.confirmDialog:isOpen() then
    return self.confirmDialog:keypressed(key)
  end

  if key == "escape" then
    if self.phase == "settings" then
      self.app.audio:stop()
      self.app.scenes:switch("hub")
    elseif self.phase ~= "finishing" then
      self.confirmDialog:open(function()
        self.app.audio:stop()
        self:_enterSettings()
      end)
    end
  end
end

return function(app)
  return DraaiomGame.new(app)
end
