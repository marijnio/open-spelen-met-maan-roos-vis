-- Mini-game 1: Onthouden maar! (Memory)

local Assets = require("src.core.assets")
local ConfirmDialog = require("src.core.confirm_dialog")
local Cursor = require("src.core.cursor")
local HotzoneManager = require("src.core.hotzone")

local MemoryGame = {}
MemoryGame.__index = MemoryGame

local LEVEL_WORDS = {
  [1] = { "maan", "roos", "ik", "sok", "teen", "buik", "oog", "aap", "poes", "eet", "ijs", "doos" },
  [2] = { "huis", "weg", "bos", "tak", "riem", "jas", "hout", "bijl", "uil", "ei", "geit", "pauw" },
  [3] = { "vis", "pen", "roos", "sok", "neus", "buik", "oog", "teen", "koek", "zeep", "doos", "eet" },
  [4] = { "hek", "hut", "tak", "huis", "reus", "vuur", "bijl", "riem", "duif", "ei", "geit", "uil" },
  [5] = { "ik", "maan", "vis", "pen", "neus", "teen", "oog", "aap", "koek", "zeep", "poes", "eet" },
  [6] = { "weg", "bos", "tak", "hut", "bijl", "vuur", "jas", "hout", "uil", "pauw", "duif", "geit" },
  [7] = { "roos", "sok", "maan", "ik", "buik", "oog", "teen", "neus", "doos", "ijs", "poes", "eet" },
  [8] = { "hek", "hut", "weg", "bos", "reus", "riem", "vuur", "jas", "ei", "duif", "geit", "pauw" },
}

local COLS = 6
local ROWS = 4
local CELL_W = 104
local CELL_H = 96
local FRAME_W = 100
local FRAME_H = 92
local FRAME_RADIUS = 10
local FACE_W = 90
local FACE_H = 80

local BAR_Y = 412
local BAR_H = 68

local MATCH_DELAY = 0.50
local REVEAL_DELAY = 1.0
local FINISH_DELAY = 1.6

local function cardFrameOrigin(index)
  local zero = index - 1
  local col = zero % COLS
  local row = math.floor(zero / COLS)
  return 10 + col * CELL_W, 10 + row * CELL_H
end

local function cardFaceOrigin(index)
  local zero = index - 1
  local col = zero % COLS
  local row = math.floor(zero / COLS)
  return 15 + col * CELL_W, 17 + row * CELL_H
end

local function cardModeFor(level, variant)
  if level <= 2 then
    return "picture"
  elseif level <= 4 then
    return (variant == 1) and "picture" or "word"
  else
    return "word"
  end
end

local function drawCenteredBold(font, text, x, y, w)
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
  love.graphics.printf(text, x + 1, y, w, "center")
end

function MemoryGame.new(app)
  local self = setmetatable({}, MemoryGame)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.confirmDialog = ConfirmDialog.new(app)
  self.handlesEscape = true

  self.handCursor = Cursor.getSystem("hand")
  self.arrowCursor = Cursor.getSystem("arrow")

  self.levelFont = love.graphics.newFont(16)
  self.badgeFont = love.graphics.newFont(12)
  self.scoreFont = love.graphics.newFont(15)
  self.wordFont = love.graphics.newFont(20)

  self.level = 1
  self.players = 1
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.pairsFound = 0
  self.phase = "settings"
  self.cards = {}
  self.openCards = {}
  self.openIsMatch = false
  self.resolveTimer = 0
  self.revealTimer = 0
  self.finishTimer = 0
  return self
end

function MemoryGame:_buildDeck(faceUp)
  local words = LEVEL_WORDS[self.level] or LEVEL_WORDS[1]
  local deck = {}
  for pairId = 1, 12 do
    local word = words[pairId]
    for variant = 1, 2 do
      table.insert(deck, {
        pairId = pairId,
        variant = variant,
        word = word,
        kind = cardModeFor(self.level, variant),
        state = faceUp and 1 or 0,
        revealAnim = 1,
      })
    end
  end

  for i = #deck, 2, -1 do
    local j = love.math.random(1, i)
    deck[i], deck[j] = deck[j], deck[i]
  end

  self.cards = deck
end

function MemoryGame:_enterSettings()
  self.phase = "settings"
  self.openCards = {}
  self.openIsMatch = false
  self.resolveTimer = 0
  self.revealTimer = 0
  self.finishTimer = 0
  self.app.audio:stop()
  self:_buildDeck(true)

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
      self.app.audio:stop()
      self.app.scenes:switch("hub")
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
      self.app.audio:clearAndPlay("jantje", "nivinshp")
    end,
  })

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
        self:_buildDeck(true)
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
end

function MemoryGame:_helpVoForLevel()
  if self.level <= 2 then
    return "ontsphp1"
  elseif self.level <= 4 then
    return "ontsphp2"
  else
    return "ontsphp3"
  end
end

function MemoryGame:_startGame(players)
  self.phase = "playing"
  self.players = players
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.pairsFound = 0
  self.openCards = {}
  self.openIsMatch = false
  self.resolveTimer = 0
  self.revealTimer = 0
  self.finishTimer = 0
  self.app.audio:stop()
  self:_buildDeck(false)

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
      self.confirmDialog:open(function()
        self.app.audio:stop()
        self:_enterSettings()
      end)
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
      self.app.audio:clearAndPlay("jantje", self:_helpVoForLevel())
    end,
  })
end

function MemoryGame:_triggerOpnieuw()
  if self.phase ~= "playing" then
    return
  end
  self.app.audio:stop()
  self.openCards = {}
  self.resolveTimer = 0
  for _, card in ipairs(self.cards) do
    if card.state == 0 then
      card.state = 1
      card.revealAnim = 1
    end
  end
  self.phase = "revealing"
  self.revealTimer = REVEAL_DELAY

  local opZone = self.hotzones:getById("opnieuw")
  if opZone then
    opZone.enabled = false
  end
end

function MemoryGame:_resolveOpenPair()
  if #self.openCards ~= 2 then
    return
  end
  local c1 = self.cards[self.openCards[1]]
  local c2 = self.cards[self.openCards[2]]
  self.openCards = {}
  self.resolveTimer = 0

  if self.openIsMatch then
    c1.state = 2
    c2.state = 2
    self.app.audio:playSfx("bang")
    if self.pairsFound >= 12 then
      self.phase = "finishing"
      self.finishTimer = FINISH_DELAY
      self.app.audio:playSfx("gong")
    end
  else
    c1.state = 0
    c2.state = 0
  end
end

function MemoryGame:_cardIndexAt(vx, vy)
  for i = 1, 24 do
    local rx, ry = cardFrameOrigin(i)
    if vx >= rx and vx <= (rx + FRAME_W) and vy >= ry and vy <= (ry + FRAME_H) then
      return i
    end
  end
  return nil
end

function MemoryGame:enter(params)
  self.level = (params and params.level) or 1
  self:_enterSettings()
end

function MemoryGame:exit()
  self.confirmDialog:close()
  self.hotzones:clear()
  Cursor.set(self.arrowCursor)
end

function MemoryGame:update(dt)
  if self.confirmDialog:isOpen() then
    self.confirmDialog:update(dt)
    return
  end

  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)

  if self.phase == "playing" then
    for _, card in ipairs(self.cards) do
      if card.state == 1 and card.revealAnim < 1 then
        card.revealAnim = math.min(1, card.revealAnim + dt / 0.09)
      end
    end

    if #self.openCards == 2 and self.resolveTimer > 0 then
      self.resolveTimer = self.resolveTimer - dt
      if self.resolveTimer <= 0 then
        self:_resolveOpenPair()
      end
    end

    if not self.hotzones.hoveredId then
      local idx = self:_cardIndexAt(vx, vy)
      if idx and self.cards[idx] and self.cards[idx].state == 0 then
        Cursor.set(self.handCursor)
      else
        Cursor.set(self.arrowCursor)
      end
    end
  elseif self.phase == "revealing" then
    self.revealTimer = self.revealTimer - dt
    if self.revealTimer <= 0 then
      self:_enterSettings()
    end
  elseif self.phase == "finishing" then
    self.finishTimer = self.finishTimer - dt
    if self.finishTimer <= 0 then
      self.app.scenes:switch("highscore", {
        gameId = "memory",
        players = self.players,
        scores = { self.scores[1], self.scores[2] },
        returnTo = "memory",
        returnParams = { level = self.level },
      })
    end
  end
end

function MemoryGame:_drawCardFace(card, x, y, w, h)
  if card.kind == "picture" then
    local img = Assets.getImage("woorden", card.word)
    if img then
      love.graphics.setColor(1, 1, 1, 1)
      local iw, ih = img:getDimensions()
      love.graphics.draw(img, x, y, 0, w / iw, h / ih)
    else
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", x, y, w, h)
    end
  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0, 0, 192 / 255, 1)
    local textY = y + math.floor((h - self.wordFont:getHeight()) * 0.5)
    drawCenteredBold(self.wordFont, card.word, x, textY, w)
  end

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)
end

function MemoryGame:_drawSettings()
  local bg = Assets.getImage("screens", "mem_0")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  for i = 1, 24 do
    local cx, cy = cardFaceOrigin(i)
    self:_drawCardFace(self.cards[i], cx, cy, FACE_W, FACE_H)
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

function MemoryGame:_drawPlayerHud(panelX, playerIndex, isActive)
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

  love.graphics.setColor(0, 0, 0, 1)
  drawCenteredBold(self.scoreFont, tostring(self.scores[playerIndex] or 0), panelX + 131, 452, 40)
end

function MemoryGame:_drawPlaying()
  local bg = Assets.getImage("screens", "memory")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  for i = 1, 24 do
    local card = self.cards[i]
    if card.state ~= 2 then
      local rx, ry = cardFrameOrigin(i)
      local cx, cy = cardFaceOrigin(i)

      love.graphics.setColor(0, 0, 130 / 255, 1)
      love.graphics.rectangle("fill", rx, ry, FRAME_W, FRAME_H, FRAME_RADIUS, FRAME_RADIUS)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("line", rx + 0.5, ry + 0.5, FRAME_W - 1, FRAME_H - 1, FRAME_RADIUS, FRAME_RADIUS)

      if card.state == 0 then
        local backImg = Assets.getImage("ui", "mkaart")
        if backImg then
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(backImg, cx, cy)
        end
      elseif card.state == 1 then
        local s = 0.25 + 0.75 * card.revealAnim
        local w = math.max(1, math.floor(FACE_W * s + 0.5))
        local h = math.max(1, math.floor(FACE_H * s + 0.5))
        local fx = cx + math.floor((FACE_W - w) * 0.5)
        local fy = cy + math.floor((FACE_H - h) * 0.5)
        self:_drawCardFace(card, fx, fy, w, h)
      end
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

function MemoryGame:draw()
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

function MemoryGame:mousepressed(vx, vy, button)
  if self.confirmDialog:isOpen() then
    return self.confirmDialog:mousepressed(vx, vy, button)
  end

  if self.hotzones:mousepressed(vx, vy, button) then
    return true
  end

  if self.phase ~= "playing" or button ~= 1 then
    return false
  end

  local idx = self:_cardIndexAt(vx, vy)
  if not idx then
    return false
  end

  local card = self.cards[idx]
  if not card or card.state ~= 0 then
    return false
  end

  if #self.openCards == 2 then
    self:_resolveOpenPair()
    if self.phase ~= "playing" then
      return true
    end
  end

  card.state = 1
  card.revealAnim = 0
  table.insert(self.openCards, idx)

  if self.level <= 6 then
    self.app.audio:clearAndPlay("words", card.word)
  end

  if #self.openCards == 2 then
    local c1 = self.cards[self.openCards[1]]
    local c2 = self.cards[self.openCards[2]]
    if c1.pairId == c2.pairId then
      self.scores[self.activePlayer] = self.scores[self.activePlayer] + self.level * 5
      self.pairsFound = self.pairsFound + 1
      self.openIsMatch = true
      self.resolveTimer = MATCH_DELAY
    else
      if self.scores[self.activePlayer] > 0 then
        self.scores[self.activePlayer] = self.scores[self.activePlayer] - 1
      end
      if self.players == 2 then
        self.activePlayer = (self.activePlayer == 1) and 2 or 1
      end
      self.openIsMatch = false
      self.resolveTimer = (20 - (self.level - 1)) * 0.125
    end
  end

  return true
end

function MemoryGame:keypressed(key)
  if self.confirmDialog:isOpen() then
    return self.confirmDialog:keypressed(key)
  end

  if key == "escape" then
    if self.phase == "playing" or self.phase == "revealing" then
      self.confirmDialog:open(function()
        self.app.audio:stop()
        self:_enterSettings()
      end)
    elseif self.phase == "settings" then
      self.app.audio:stop()
      self.app.scenes:switch("hub")
    end
  end
end

return function(app)
  return MemoryGame.new(app)
end
