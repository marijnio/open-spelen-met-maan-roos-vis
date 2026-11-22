-- Mini-game 5: Invullen

local Assets = require("src.core.assets")
local Cursor = require("src.core.cursor")
local HotzoneManager = require("src.core.hotzone")

local InvullenGame = {}
InvullenGame.__index = InvullenGame

local LEVEL_ROUNDS = {
  [1] = {
    { word = "roos", masked = "r . s", options = { "oo", "aa", "o", "i", "ee", "b" } },
    { word = "sok",  masked = "so .",  options = { "k", "p", "o", "d", "s", "m" } },
    { word = "maan", masked = ". aan", options = { "m", "b", "p", "n", "s", "v" } },
    { word = "pen",  masked = "pe .",  options = { "n", "m", "v", "r", "p", "s" } },
    { word = "ik",   masked = ". k",   options = { "i", "r", "p", "s", "v", "n" } },
    { word = "roos", masked = "roo .", options = { "s", "t", "v", "m", "b", "r" } },
    { word = "sok",  masked = ". ok",  options = { "s", "t", "v", "r", "i", "n" } },
    { word = "maan", masked = "maa .", options = { "n", "b", "p", "m", "v", "t" } },
    { word = "vis",  masked = "v . s", options = { "i", "oo", "aa", "b", "t", "n" } },
    { word = "ik",   masked = "i .",   options = { "k", "t", "p", "b", "v", "s" } },
  },
  [2] = {
    { word = "buik", masked = ". uik", options = { "b", "d", "k", "t", "v", "p" } },
    { word = "aap",  masked = ". p",   options = { "aa", "oo", "a", "e", "i", "ee" } },
    { word = "neus", masked = "neu .", options = { "s", "o", "t", "r", "b", "v" } },
    { word = "oog",  masked = "oo .",  options = { "g", "d", "b", "t", "s", "n" } },
    { word = "teen", masked = ". een", options = { "t", "b", "p", "m", "s", "v" } },
    { word = "buik", masked = "b . k", options = { "ui", "p", "n", "s", "b", "i" } },
    { word = "aap",  masked = "aa .",  options = { "p", "m", "n", "b", "r", "v" } },
    { word = "neus", masked = ". eus", options = { "n", "m", "r", "s", "v", "t" } },
    { word = "oog",  masked = ". g",   options = { "oo", "aa", "p", "n", "s", "t" } },
    { word = "teen", masked = "tee .", options = { "n", "m", "s", "t", "b", "v" } },
  },
  [3] = {
    { word = "poes", masked = "p . s", options = { "oe", "oo", "ee", "aa", "ij", "e" } },
    { word = "zeep", masked = ". eep", options = { "z", "s", "d", "p", "r", "t" } },
    { word = "doos", masked = "doo .", options = { "s", "z", "k", "r", "p", "i" } },
    { word = "doos", masked = ". oos", options = { "d", "b", "m", "v", "k", "t" } },
    { word = "zeep", masked = "z . p", options = { "ee", "aa", "oe", "ij", "p", "k" } },
    { word = "poes", masked = "poe .", options = { "s", "t", "v", "k", "i", "p" } },
    { word = "koek", masked = "k . k", options = { "oe", "ee", "aa", "i", "ij", "oo" } },
    { word = "koek", masked = "koe .", options = { "k", "p", "v", "m", "t", "d" } },
    { word = "eet",  masked = ". t",   options = { "ee", "aa", "oo", "oe", "ij", "i" } },
    { word = "ijs",  masked = "ij .",  options = { "s", "t", "p", "v", "d", "r" } },
  },
  [4] = {
    { word = "vis",  masked = ". is",  options = { "v", "r", "p", "m", "s", "d" } },
    { word = "teen", masked = "t . n", options = { "ee", "oe", "oo", "aa", "ij", "i" } },
    { word = "eet",  masked = "ee .",  options = { "t", "p", "r", "s", "m", "d" } },
    { word = "pen",  masked = ". en",  options = { "p", "d", "r", "t", "s", "n" } },
    { word = "ijs",  masked = ". s",   options = { "ij", "i", "oo", "aa", "b", "s" } },
    { word = "buik", masked = "bui .", options = { "k", "d", "m", "r", "z", "t" } },
    { word = "neus", masked = ". eus", options = { "n", "m", "p", "b", "r", "s" } },
    { word = "roos", masked = ". oos", options = { "r", "t", "s", "p", "b", "n" } },
    { word = "koek", masked = ". oek", options = { "k", "p", "s", "b", "t", "d" } },
    { word = "doos", masked = "d . s", options = { "oo", "ee", "aa", "oe", "d", "s" } },
  },
  [5] = {
    { word = "weg",  masked = ". eg",  options = { "w", "h", "p", "e", "v", "u" } },
    { word = "tak",  masked = "t . k", options = { "a", "u", "o", "e", "ij", "i" } },
    { word = "bos",  masked = "bo .",  options = { "s", "z", "r", "o", "p", "b" } },
    { word = "weg",  masked = "w . g", options = { "e", "a", "o", "u", "w", "i" } },
    { word = "tak",  masked = "ta .",  options = { "k", "p", "h", "w", "r", "s" } },
    { word = "bos",  masked = "b . s", options = { "o", "a", "e", "i", "u", "oo" } },
    { word = "huis", masked = ". uis", options = { "h", "p", "b", "d", "s", "w" } },
    { word = "huis", masked = "hui .", options = { "s", "t", "h", "k", "r", "p" } },
    { word = "hek",  masked = "h . k", options = { "e", "a", "aa", "ee", "ie", "i" } },
    { word = "hek",  masked = ". ek",  options = { "h", "p", "b", "w", "j", "k" } },
  },
  [6] = {
    { word = "bijl", masked = ". ijl", options = { "b", "p", "d", "l", "h", "n" } },
    { word = "riem", masked = "r . m", options = { "ie", "oe", "oo", "ee", "aa", "uu" } },
    { word = "vuur", masked = "vuu .", options = { "r", "s", "e", "l", "j", "t" } },
    { word = "bijl", masked = "b . l", options = { "ij", "i", "b", "oo", "aa", "ee" } },
    { word = "riem", masked = "rie .", options = { "m", "n", "p", "b", "t", "k" } },
    { word = "vuur", masked = "v . r", options = { "uu", "aa", "ee", "v", "u", "eu" } },
    { word = "reus", masked = ". eus", options = { "r", "s", "t", "m", "d", "b" } },
    { word = "hout", masked = "h . t", options = { "ou", "oo", "oe", "uu", "eu", "o" } },
    { word = "hout", masked = "hou .", options = { "t", "s", "l", "d", "b", "r" } },
    { word = "jas",  masked = ". as",  options = { "j", "l", "b", "d", "r", "t" } },
  },
  [7] = {
    { word = "geit", masked = ". eit", options = { "g", "f", "k", "m", "p", "d" } },
    { word = "duif", masked = "d . f", options = { "ui", "ie", "oe", "ee", "au", "ou" } },
    { word = "pauw", masked = "pau .", options = { "w", "v", "r", "h", "f", "n" } },
    { word = "geit", masked = "g . t", options = { "ei", "ie", "ij", "ui", "eu", "oe" } },
    { word = "duif", masked = "dui .", options = { "f", "v", "d", "h", "t", "n" } },
    { word = "pauw", masked = "p . w", options = { "au", "ou", "ei", "ie", "oe", "aa" } },
    { word = "uil",  masked = "ui .",  options = { "l", "j", "i", "k", "t", "f" } },
    { word = "uil",  masked = ". l",   options = { "ui", "ei", "ij", "au", "aa", "eu" } },
    { word = "ei",   masked = ".",     options = { "ei", "ie", "ui", "oe", "oo", "au" } },
    { word = "duif", masked = ". uif", options = { "d", "b", "p", "g", "t", "f" } },
  },
  [8] = {
    { word = "hut",  masked = ". ut",  options = { "h", "p", "v", "r", "b", "n" } },
    { word = "jas",  masked = "j . s", options = { "a", "e", "o", "u", "i", "d" } },
    { word = "uil",  masked = "ui .",  options = { "l", "k", "t", "j", "f", "r" } },
    { word = "tak",  masked = ". ak",  options = { "t", "s", "l", "k", "d", "b" } },
    { word = "bos",  masked = ". os",  options = { "b", "d", "s", "p", "g", "l" } },
    { word = "vuur", masked = ". uur", options = { "v", "f", "p", "r", "g", "z" } },
    { word = "hout", masked = ". out", options = { "h", "b", "p", "g", "n", "t" } },
    { word = "pauw", masked = ". auw", options = { "p", "b", "g", "m", "k", "d" } },
    { word = "geit", masked = "gei .", options = { "t", "s", "d", "p", "b", "r" } },
    { word = "reus", masked = "reu .", options = { "s", "z", "t", "r", "v", "h" } },
  },
}

local PERM_TABLE = {
  { 1, 2, 3, 4, 5, 6 },
  { 6, 5, 4, 3, 2, 1 },
  { 1, 6, 2, 5, 3, 4 },
}

local PIC_W = 560
local PIC_H = 340

local WORD_BOX_X = 40
local WORD_BOX_Y = 16
local WORD_BOX_W = 560
local WORD_BOX_H = 240

local TILE_COUNT = 6
local TILE_SIZE = 80
local TILE_X_START = 32
local TILE_X_STEP = 100
local TILE_Y = 296
local TILE_SRC_Y = 260
local TILE_SRC_STEP = 96

local BAR_Y = 412
local BAR_H = 68

local ROUNDS_PER_LEVEL = 10
local TIMER_MAX = 100
local TIMER_TICK_INTERVAL = 0.50
local INITIAL_REVEAL_DELAY = 0.20
local TILE_REVEAL_INTERVAL = 0.10
local FLASH_BASE_TICKS = 28
local FLASH_LEVEL_STEP = 2
local TICK_SECONDS = 0.125
local HINT_PENALTY = 5
local WRONG_PENALTY = 10
local REVEAL_DELAY = 1.50
local FINISH_DELAY = 2.50

local function drawCenteredBold(font, text, x, y, w)
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
  love.graphics.printf(text, x + 1, y, w, "center")
end

local function pointInRect(px, py, rx, ry, rw, rh)
  return px >= rx and px < (rx + rw) and py >= ry and py < (ry + rh)
end

local function flashDurationForLevel(level)
  return (FLASH_BASE_TICKS - FLASH_LEVEL_STEP * (level - 1)) * TICK_SECONDS
end

function InvullenGame.new(app)
  local self = setmetatable({}, InvullenGame)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.handlesEscape = true

  self.handCursor = Cursor.getSystem("hand")
  self.arrowCursor = Cursor.getSystem("arrow")
  self.waitCursor = Cursor.getSystem("wait") or self.arrowCursor

  self.levelFont = love.graphics.newFont(16)
  self.badgeFont = love.graphics.newFont(12)
  self.scoreFont = love.graphics.newFont(15)
  self.wordFont = love.graphics.newFont(100)
  self.tileFont = love.graphics.newFont(44)

  self.wordBoxQuad = love.graphics.newQuad(0, 0, WORD_BOX_W, WORD_BOX_H, PIC_W, PIC_H)
  self.tileQuads = {}
  for i = 1, TILE_COUNT do
    self.tileQuads[i] = love.graphics.newQuad(
      (i - 1) * TILE_SRC_STEP,
      TILE_SRC_Y,
      TILE_SIZE,
      TILE_SIZE,
      PIC_W,
      PIC_H
    )
  end

  self.level = 1
  self.players = 1
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.roundIndex = 1
  self.slotToOption = { 1, 2, 3, 4, 5, 6 }
  self.visibleTileCount = 0
  self.wordMasked = false
  self.flashTimer = 0
  self.phase = "settings"
  self.phaseTimer = 0

  return self
end

function InvullenGame:_currentRound()
  local rounds = LEVEL_ROUNDS[self.level] or LEVEL_ROUNDS[1]
  return rounds[self.roundIndex]
end

function InvullenGame:_prepareRound()
  local row = love.math.random(1, 3)
  local offset = love.math.random(0, 5)
  local perm = PERM_TABLE[row]
  for slot = 1, TILE_COUNT do
    local idx = ((offset + slot - 1) % TILE_COUNT) + 1
    self.slotToOption[slot] = perm[idx]
  end
end

function InvullenGame:_syncHover()
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:syncHover(vx, vy)
end

function InvullenGame:_setOpnieuwEnabled(enabled)
  local opZone = self.hotzones:getById("opnieuw")
  if opZone then
    opZone.enabled = enabled
  end
end

function InvullenGame:_addBaseChromeHotzones(onHelpClick, onTerugClick)
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
      if onTerugClick then
        onTerugClick()
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
    onClick = onHelpClick,
  })
end

function InvullenGame:_enterSettings()
  self.phase = "settings"
  self.roundIndex = 1
  self.visibleTileCount = 0
  self.wordMasked = false
  self.flashTimer = 0
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.phaseTimer = 0
  self.app.audio:stop()

  self:_prepareRound()

  self.hotzones:clear()
  self:_addBaseChromeHotzones(function()
    self.app.audio:clearAndPlay("jantje", "nivinshp")
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
        self.roundIndex = 1
        self:_prepareRound()
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

function InvullenGame:_startRoundReveal()
  self.phase = "revealing_tiles"
  self.visibleTileCount = 0
  self.wordMasked = false
  self.flashTimer = 0
  self.phaseTimer = INITIAL_REVEAL_DELAY + TILE_REVEAL_INTERVAL
  self.timerAccum = 0
end

function InvullenGame:_startGame(players)
  self.players = players
  self.activePlayer = love.math.random(1, players)
  self.scores = { 0, 0 }
  self.timers = { TIMER_MAX, (players == 2) and TIMER_MAX or 0 }
  self.timerAccum = 0
  self.roundIndex = 1
  self.app.audio:stop()

  self.hotzones:clear()
  self:_addBaseChromeHotzones(function()
    self.app.audio:clearAndPlay("jantje", "invsphp1")
  end, function()
    self:_enterSettings()
  end)

  self:_syncHover()
  self:_prepareRound()
  self:_startRoundReveal()
end

function InvullenGame:_triggerOpnieuw()
  if self.phase ~= "revealing_tiles"
    and self.phase ~= "playing"
    and self.phase ~= "hint_speak"
    and self.phase ~= "correct_speak" then
    return
  end

  self.app.audio:stop()
  self:_setOpnieuwEnabled(false)
  self.wordMasked = false
  self.phase = "revealing"
  self.phaseTimer = REVEAL_DELAY
end

function InvullenGame:_switchTurnOrTimeout()
  if self.players == 2 then
    local other = (self.activePlayer == 1) and 2 or 1
    if self.timers[1] <= 0 and self.timers[2] <= 0 then
      self:_setOpnieuwEnabled(false)
      self.app.audio:clearAndPlay("sfx", "afgelope")
      self.phase = "timeout_finish"
      return true
    end
    if self.timers[other] > 0 then
      self.activePlayer = other
    end
    self.timerAccum = 0
    return false
  else
    if self.timers[1] <= 0 then
      self:_setOpnieuwEnabled(false)
      self.app.audio:clearAndPlay("sfx", "afgelope")
      self.phase = "timeout_finish"
      return true
    end
    return false
  end
end

function InvullenGame:_enterFinishing()
  self:_setOpnieuwEnabled(false)
  self.phase = "finishing"
  self.phaseTimer = FINISH_DELAY
  self.app.audio:playSfx("gong")
end

function InvullenGame:enter(params)
  local lvl = tonumber(params and params.level) or 1
  self.level = math.max(1, math.min(8, math.floor(lvl)))
  self:_enterSettings()
end

function InvullenGame:exit()
  self.hotzones:clear()
  Cursor.set(self.arrowCursor)
end

function InvullenGame:_isInWordBox(vx, vy)
  return pointInRect(vx, vy, WORD_BOX_X, WORD_BOX_Y, WORD_BOX_W, WORD_BOX_H)
end

function InvullenGame:_tileSlotAt(vx, vy)
  for slot = 1, self.visibleTileCount do
    local tx = TILE_X_START + (slot - 1) * TILE_X_STEP
    if pointInRect(vx, vy, tx, TILE_Y, TILE_SIZE, TILE_SIZE) then
      return slot
    end
  end
  return nil
end

function InvullenGame:_updateCursor(vx, vy)
  if self.hotzones.hoveredId then
    return
  end
  if self.phase == "playing" then
    local onInteractive = self:_isInWordBox(vx, vy) or (self:_tileSlotAt(vx, vy) ~= nil)
    Cursor.set(onInteractive and self.handCursor or self.arrowCursor)
  elseif self.phase == "settings" then
    Cursor.set(self.arrowCursor)
  else
    Cursor.set(self.waitCursor)
  end
end

function InvullenGame:update(dt)
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)

  if self.phase == "revealing_tiles" then
    self.phaseTimer = self.phaseTimer - dt
    while self.phaseTimer <= 0 and self.visibleTileCount < TILE_COUNT do
      self.visibleTileCount = self.visibleTileCount + 1
      if self.visibleTileCount >= TILE_COUNT then
        self.phase = "playing"
        self.phaseTimer = 0
        self.wordMasked = false
        self.flashTimer = flashDurationForLevel(self.level)
        self.timerAccum = 0
        local round = self:_currentRound()
        if round then
          self.app.audio:clearAndPlay("words", round.word)
        end
        break
      else
        self.phaseTimer = self.phaseTimer + TILE_REVEAL_INTERVAL
      end
    end
  elseif self.phase == "playing" then
    if self.flashTimer > 0 then
      self.flashTimer = self.flashTimer - dt
      if self.flashTimer <= 0 then
        self.flashTimer = 0
        self.wordMasked = true
        self.timerAccum = 0
      end
    else
      self.timerAccum = self.timerAccum + dt
      while self.timerAccum >= TIMER_TICK_INTERVAL do
        self.timerAccum = self.timerAccum - TIMER_TICK_INTERVAL
        if self.timers[self.activePlayer] > 0 then
          self.timers[self.activePlayer] = self.timers[self.activePlayer] - 1
        end
        if self.timers[self.activePlayer] <= 0 then
          self.timers[self.activePlayer] = 0
          self.app.audio:playSfx("fout2")
          self:_switchTurnOrTimeout()
          break
        end
      end
    end
  elseif self.phase == "hint_speak" then
    if not self.app.audio:isPlaying() then
      self.phase = "playing"
    end
  elseif self.phase == "correct_speak" then
    if not self.app.audio:isPlaying() then
      if not self:_switchTurnOrTimeout() then
        self.roundIndex = self.roundIndex + 1
        if self.roundIndex > ROUNDS_PER_LEVEL then
          self:_enterFinishing()
        else
          self:_prepareRound()
          self:_startRoundReveal()
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
        gameId = "invullen",
        players = self.players,
        scores = { self.scores[1], self.scores[2] },
        returnTo = "invullen",
        returnParams = { level = math.min(8, self.level + 1) },
      })
    end
  end

  self:_updateCursor(vx, vy)
end

function InvullenGame:_drawWordBox(text)
  local img = Assets.getImage("invullen", "pic_a0")
  if img then
    local iw, ih = img:getDimensions()
    if iw == PIC_W and ih == PIC_H and self.wordBoxQuad then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, self.wordBoxQuad, WORD_BOX_X, WORD_BOX_Y)
    else
      love.graphics.setColor(204 / 255, 204 / 255, 1, 1)
      love.graphics.rectangle("fill", WORD_BOX_X, WORD_BOX_Y, WORD_BOX_W, WORD_BOX_H)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("line", WORD_BOX_X + 0.5, WORD_BOX_Y + 0.5, WORD_BOX_W - 1, WORD_BOX_H - 1)
    end
  else
    love.graphics.setColor(204 / 255, 204 / 255, 1, 1)
    love.graphics.rectangle("fill", WORD_BOX_X, WORD_BOX_Y, WORD_BOX_W, WORD_BOX_H)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", WORD_BOX_X + 0.5, WORD_BOX_Y + 0.5, WORD_BOX_W - 1, WORD_BOX_H - 1)
  end

  if text and text ~= "" then
    local font = self.wordFont
    love.graphics.setFont(font)
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local maxW = WORD_BOX_W - 24
    local sx = (tw > maxW and tw > 0) and (maxW / tw) or 1
    local drawX = WORD_BOX_X + math.floor((WORD_BOX_W - tw * sx) * 0.5)
    local drawY = WORD_BOX_Y + math.floor((WORD_BOX_H - th) * 0.5)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(text, drawX, drawY, 0, sx, 1)
  end
end

function InvullenGame:_drawTile(slot)
  local tx = TILE_X_START + (slot - 1) * TILE_X_STEP
  local ty = TILE_Y
  local optIdx = self.slotToOption[slot] or slot
  local round = self:_currentRound()
  local text = round and round.options[optIdx] or ""

  local img = Assets.getImage("invullen", "pic_a0")
  local quad = self.tileQuads[optIdx]
  local drewImg = false
  if img and quad then
    local iw, ih = img:getDimensions()
    if iw == PIC_W and ih == PIC_H then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, quad, tx, ty)
      drewImg = true
    end
  end
  if not drewImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", tx, ty, TILE_SIZE, TILE_SIZE)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", tx + 0.5, ty + 0.5, TILE_SIZE - 1, TILE_SIZE - 1)
  end

  if text ~= "" then
    local font = self.tileFont
    love.graphics.setFont(font)
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local maxW = TILE_SIZE - 12
    local sx = (tw > maxW and tw > 0) and (maxW / tw) or 1
    local drawX = tx + math.floor((TILE_SIZE - tw * sx) * 0.5)
    local drawY = ty + math.floor((TILE_SIZE - th) * 0.5)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(text, drawX, drawY, 0, sx, 1)
  end
end

function InvullenGame:_drawPlayerHud(panelX, playerIndex, isActive)
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

function InvullenGame:_drawSettings()
  local bg = Assets.getImage("screens", "mem_0")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(200 / 255, 1, 200 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  local round = self:_currentRound()
  self:_drawWordBox(round and round.word or "")

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

function InvullenGame:_drawPlaying()
  local bg = Assets.getImage("screens", "invullen")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(220 / 255, 240 / 255, 130 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  local round = self:_currentRound()
  local displayWord = ""
  if round then
    displayWord = self.wordMasked and round.masked or round.word
  end
  self:_drawWordBox(displayWord)

  for slot = 1, self.visibleTileCount do
    self:_drawTile(slot)
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

function InvullenGame:draw()
  if self.phase == "settings" then
    self:_drawSettings()
  else
    self:_drawPlaying()
  end

  love.graphics.setColor(1, 1, 1, 1)
  self.hotzones:draw(self.app.debugHotzones)
end

function InvullenGame:mousepressed(vx, vy, button)
  if self.hotzones:mousepressed(vx, vy, button) then
    return true
  end

  if self.phase ~= "playing" or button ~= 1 then
    return false
  end

  local round = self:_currentRound()
  if not round then
    return false
  end

  if self:_isInWordBox(vx, vy) then
    self.scores[self.activePlayer] = math.max(0, self.scores[self.activePlayer] - HINT_PENALTY)
    self.app.audio:clearAndPlay("words", round.word)
    self.phase = "hint_speak"
    return true
  end

  local slot = self:_tileSlotAt(vx, vy)
  if not slot then
    return false
  end

  if self.slotToOption[slot] == 1 then
    self.scores[self.activePlayer] = self.scores[self.activePlayer]
      + self.timers[self.activePlayer]
      + (self.level - 1)
    self.app.audio:clearAndPlay("words", round.word)
    self.phase = "correct_speak"
  else
    self.scores[self.activePlayer] = math.max(0, self.scores[self.activePlayer] - WRONG_PENALTY)
    self.app.audio:playSfx("fout2")
    self:_switchTurnOrTimeout()
  end

  return true
end

function InvullenGame:keypressed(key)
  if key == "escape" then
    self.app.audio:stop()
    if self.phase == "settings" then
      self.app.scenes:switch("hub")
    elseif self.phase ~= "finishing" then
      self:_enterSettings()
    end
  end
end

return function(app)
  return InvullenGame.new(app)
end
