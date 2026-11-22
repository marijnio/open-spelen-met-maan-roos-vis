-- Mini-game 2: Woordje plaatje (Electro)

local Assets = require("src.core.assets")
local Cursor = require("src.core.cursor")
local HotzoneManager = require("src.core.hotzone")

local ElectroGame = {}
ElectroGame.__index = ElectroGame

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
local CELL_W = 104
local CELL_H = 96
local FRAME_W = 100
local FRAME_H = 92
local FRAME_RADIUS = 10
local FACE_W = 90
local FACE_H = 80

local GRID_X = 10
local GRID_Y = 202
local TOP_FRAME_X = 268
local TOP_FRAME_Y = 66
local TOP_FACE_X = 273
local TOP_FACE_Y = 72

local BAR_Y = 412
local BAR_H = 68

local TOP_FRAME_COLOR = { 128 / 255, 128 / 255, 0 }
local GRID_FRAME_COLOR = { 0, 128 / 255, 0 }

local TIMER_MAX = 10
local TIMER_TICK_INTERVAL = 1.0
local NEXT_CARD_DELAY = 1.0
local WRONG_DELAY = 0.5
local REVEAL_DELAY = 1.0
local FINISH_DELAY = 2.0
local REVEAL_ANIM_DURATION = 0.09

local function cardFrameOrigin(index)
  local zero = index - 1
  local col = zero % COLS
  local row = math.floor(zero / COLS)
  return GRID_X + col * CELL_W, GRID_Y + row * CELL_H
end

local function cardFaceOrigin(index)
  local zero = index - 1
  local col = zero % COLS
  local row = math.floor(zero / COLS)
  return (GRID_X + 5) + col * CELL_W, (GRID_Y + 6) + row * CELL_H
end

local function topKindForLevel(level)
  return (level <= 2) and "picture" or "word"
end

local function gridKindForLevel(level)
  return (level <= 4) and "picture" or "word"
end

local function drawCenteredBold(font, text, x, y, w)
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
  love.graphics.printf(text, x + 1, y, w, "center")
end

local function pointInRect(px, py, rx, ry, rw, rh)
  return px >= rx and px <= (rx + rw) and py >= ry and py <= (ry + rh)
end

local function scaledFaceRect(cx, cy, anim)
  local s = 0.25 + 0.75 * anim
  local w = math.max(1, math.floor(FACE_W * s + 0.5))
  local h = math.max(1, math.floor(FACE_H * s + 0.5))
  local fx = cx + math.floor((FACE_W - w) * 0.5)
  local fy = cy + math.floor((FACE_H - h) * 0.5)
  return fx, fy, w, h
end

function ElectroGame.new(app)
  local self = setmetatable({}, ElectroGame)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.handlesEscape = true

  self.handCursor = Cursor.getSystem("hand")
  self.arrowCursor = Cursor.getSystem("arrow")

  self.levelFont = love.graphics.newFont(16)
  self.badgeFont = love.graphics.newFont(12)
  self.scoreFont = love.graphics.newFont(15)
  self.wordFont = love.graphics.newFont(22)

  self.level = 1
  self.players = 1
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.foundCount = 0
  self.phase = "settings"
  self.cards = {}
  self.targetWord = nil
  self.topShowing = true
  self.topRevealAnim = 1
  self.delayTimer = 0
  self.revealTimer = 0
  self.finishTimer = 0
  return self
end

function ElectroGame:_syncHover()
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:syncHover(vx, vy)
end

function ElectroGame:_helpVoForLevel()
  if self.level <= 2 then
    return "wplsphp1"
  elseif self.level <= 4 then
    return "wplsphp2"
  else
    return "wplsphp3"
  end
end

function ElectroGame:_buildCards(animate)
  local words = LEVEL_WORDS[self.level] or LEVEL_WORDS[1]
  local deck = {}
  for i = 1, 12 do
    table.insert(deck, {
      word = words[i],
      state = 1,
      revealAnim = animate and 0 or 1,
    })
  end

  for i = #deck, 2, -1 do
    local j = love.math.random(1, i)
    deck[i], deck[j] = deck[j], deck[i]
  end

  self.cards = deck
end

function ElectroGame:_pickNextTarget()
  local remaining = {}
  for i = 1, #self.cards do
    if self.cards[i].state == 1 then
      table.insert(remaining, i)
    end
  end

  if #remaining == 0 then
    self.targetWord = nil
    return
  end

  local pick = remaining[love.math.random(1, #remaining)]
  self.targetWord = self.cards[pick].word
  self.timers[self.activePlayer] = TIMER_MAX
  self.timerAccum = 0
end

function ElectroGame:_addBaseChromeHotzones(helpVoProvider, onTerug)
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

function ElectroGame:_enterSettings()
  self.phase = "settings"
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.foundCount = 0
  self.delayTimer = 0
  self.revealTimer = 0
  self.finishTimer = 0
  self.app.audio:stop()

  self:_buildCards(false)
  self:_pickNextTarget()
  self.topShowing = true
  self.topRevealAnim = 1

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
        self:_buildCards(false)
        self:_pickNextTarget()
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

function ElectroGame:_startGame(players)
  self.phase = "playing"
  self.players = players
  self.activePlayer = love.math.random(1, players)
  self.scores = { 0, 0 }
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.foundCount = 0
  self.delayTimer = 0
  self.revealTimer = 0
  self.finishTimer = 0
  self.app.audio:stop()

  self:_buildCards(true)
  self:_pickNextTarget()
  self.topShowing = true
  self.topRevealAnim = 0

  self.hotzones:clear()
  self:_addBaseChromeHotzones(function()
    return self:_helpVoForLevel()
  end, function()
    self:_enterSettings()
  end)

  self:_syncHover()

  if self.targetWord then
    self.app.audio:clearAndPlay("words", self.targetWord)
  end
end

function ElectroGame:_triggerOpnieuw()
  if self.phase ~= "playing" and self.phase ~= "next_delay" and self.phase ~= "wrong_delay" then
    return
  end

  self.app.audio:stop()

  if self.foundCount < 6 then
    for _, card in ipairs(self.cards) do
      if card.state == 1 and card.word ~= self.targetWord then
        card.state = 2
      end
    end
    self.topShowing = true
    self.topRevealAnim = 1
    self.phase = "revealing"
    self.revealTimer = REVEAL_DELAY

    local opZone = self.hotzones:getById("opnieuw")
    if opZone then
      opZone.enabled = false
    end
  else
    self:_enterSettings()
  end
end

function ElectroGame:_isInTopTile(vx, vy)
  return pointInRect(vx, vy, TOP_FRAME_X, TOP_FRAME_Y, FRAME_W, FRAME_H)
end

function ElectroGame:_cardIndexAt(vx, vy)
  for i = 1, 12 do
    local rx, ry = cardFrameOrigin(i)
    if pointInRect(vx, vy, rx, ry, FRAME_W, FRAME_H) then
      return i
    end
  end
  return nil
end

function ElectroGame:enter(params)
  local lvl = tonumber(params and params.level) or 1
  self.level = math.max(1, math.min(8, math.floor(lvl)))
  self:_enterSettings()
end

function ElectroGame:exit()
  self.hotzones:clear()
  Cursor.set(self.arrowCursor)
end

function ElectroGame:update(dt)
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)

  if self.phase ~= "settings" then
    for _, card in ipairs(self.cards) do
      if card.state == 1 and card.revealAnim < 1 then
        card.revealAnim = math.min(1, card.revealAnim + dt / REVEAL_ANIM_DURATION)
      end
    end
    if self.topShowing and self.topRevealAnim < 1 then
      self.topRevealAnim = math.min(1, self.topRevealAnim + dt / REVEAL_ANIM_DURATION)
    end
  end

  if self.phase == "playing" then
    self.timerAccum = self.timerAccum + dt
    while self.timerAccum >= TIMER_TICK_INTERVAL do
      self.timerAccum = self.timerAccum - TIMER_TICK_INTERVAL
      if self.timers[self.activePlayer] > 0 then
        self.timers[self.activePlayer] = self.timers[self.activePlayer] - 1
      end
    end

    if not self.hotzones.hoveredId then
      local onTop = self.topShowing and self:_isInTopTile(vx, vy)
      local idx = self:_cardIndexAt(vx, vy)
      local onCard = idx and self.cards[idx] and self.cards[idx].state == 1
      Cursor.set((onTop or onCard) and self.handCursor or self.arrowCursor)
    end
  else
    if not self.hotzones.hoveredId and self.phase ~= "settings" then
      Cursor.set(self.arrowCursor)
    end

    if self.phase == "next_delay" then
      self.delayTimer = self.delayTimer - dt
      if self.delayTimer <= 0 then
        self.delayTimer = 0
        self.phase = "playing"
        self.topShowing = true
        self.topRevealAnim = 0
        self.timerAccum = 0
        if self.level <= 6 and self.targetWord then
          self.app.audio:clearAndPlay("words", self.targetWord)
        end
      end
    elseif self.phase == "wrong_delay" then
      self.delayTimer = self.delayTimer - dt
      if self.delayTimer <= 0 then
        self.delayTimer = 0
        self.phase = "playing"
        if self.players == 2 then
          self.activePlayer = (self.activePlayer == 1) and 2 or 1
          self.timers[self.activePlayer] = TIMER_MAX
          self.timerAccum = 0
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
          gameId = "electro",
          players = self.players,
          scores = { self.scores[1], self.scores[2] },
          returnTo = "electro",
          returnParams = { level = math.min(8, self.level + 1) },
        })
      end
    end
  end
end

function ElectroGame:_drawCardBack(x, y)
  local backImg = Assets.getImage("ui", "ekaart")
  if backImg then
    love.graphics.setColor(1, 1, 1, 1)
    local iw, ih = backImg:getDimensions()
    love.graphics.draw(backImg, x, y, 0, FACE_W / iw, FACE_H / ih)
  else
    love.graphics.setColor(0, 153 / 255, 51 / 255, 1)
    love.graphics.rectangle("fill", x, y, FACE_W, FACE_H)
  end
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, FACE_W - 1, FACE_H - 1)
end

function ElectroGame:_drawCardFace(word, kind, x, y, w, h)
  if kind == "picture" then
    local img = Assets.getImage("woorden", word)
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
    love.graphics.setColor(0, 0, 1, 1)
    local textY = y + math.floor((h - self.wordFont:getHeight()) * 0.5)
    drawCenteredBold(self.wordFont, word, x, textY, w)
  end

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)
end

function ElectroGame:_drawTileFrame(rx, ry, fillColor)
  love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], 1)
  love.graphics.rectangle("fill", rx, ry, FRAME_W, FRAME_H, FRAME_RADIUS, FRAME_RADIUS)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", rx + 0.5, ry + 0.5, FRAME_W - 1, FRAME_H - 1, FRAME_RADIUS, FRAME_RADIUS)
end

function ElectroGame:_drawTopTile()
  self:_drawTileFrame(TOP_FRAME_X, TOP_FRAME_Y, TOP_FRAME_COLOR)
  self:_drawCardBack(TOP_FACE_X, TOP_FACE_Y)

  if self.topShowing and self.targetWord then
    local anim = (self.phase == "settings") and 1 or self.topRevealAnim
    local fx, fy, w, h = scaledFaceRect(TOP_FACE_X, TOP_FACE_Y, anim)
    self:_drawCardFace(self.targetWord, topKindForLevel(self.level), fx, fy, w, h)
  end
end

function ElectroGame:_drawSettings()
  local bg = Assets.getImage("screens", "mem_0")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  self:_drawTopTile()

  local gridKind = gridKindForLevel(self.level)
  for i = 1, 12 do
    local cx, cy = cardFaceOrigin(i)
    self:_drawCardFace(self.cards[i].word, gridKind, cx, cy, FACE_W, FACE_H)
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

function ElectroGame:_drawPlayerHud(panelX, playerIndex, isActive)
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

  local percent = (self.timers[playerIndex] or 0) * 10
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

function ElectroGame:_drawPlaying()
  local bg = Assets.getImage("screens", "electro")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  self:_drawTopTile()

  local gridKind = gridKindForLevel(self.level)
  for i = 1, 12 do
    local card = self.cards[i]
    if card.state ~= 2 then
      local rx, ry = cardFrameOrigin(i)
      local cx, cy = cardFaceOrigin(i)
      self:_drawTileFrame(rx, ry, GRID_FRAME_COLOR)
      self:_drawCardBack(cx, cy)

      local fx, fy, w, h = scaledFaceRect(cx, cy, card.revealAnim)
      self:_drawCardFace(card.word, gridKind, fx, fy, w, h)
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

function ElectroGame:draw()
  if self.phase == "settings" then
    self:_drawSettings()
  else
    self:_drawPlaying()
  end

  love.graphics.setColor(1, 1, 1, 1)
  self.hotzones:draw(self.app.debugHotzones)
end

function ElectroGame:mousepressed(vx, vy, button)
  if self.hotzones:mousepressed(vx, vy, button) then
    return true
  end

  if self.phase ~= "playing" or button ~= 1 then
    return false
  end

  if self.topShowing and self.targetWord and self:_isInTopTile(vx, vy) then
    self.app.audio:clearAndPlay("words", self.targetWord)
    return true
  end

  local idx = self:_cardIndexAt(vx, vy)
  if not idx then
    return false
  end

  local card = self.cards[idx]
  if not card or card.state ~= 1 then
    return false
  end

  if card.word == self.targetWord then
    self.app.audio:stop()
    self.app.audio:playSfx("bang")
    card.state = 2
    self.scores[self.activePlayer] = self.scores[self.activePlayer] + self.timers[self.activePlayer] + (self.level - 1)
    self.foundCount = self.foundCount + 1
    self.topShowing = false

    if self.players == 2 then
      self.activePlayer = (self.activePlayer == 1) and 2 or 1
      self.timers[self.activePlayer] = TIMER_MAX
    end

    if self.foundCount >= 12 then
      self.phase = "finishing"
      self.finishTimer = FINISH_DELAY
      local opZone = self.hotzones:getById("opnieuw")
      if opZone then
        opZone.enabled = false
      end
      self.app.audio:playSfx("gong")
    else
      self:_pickNextTarget()
      self.phase = "next_delay"
      self.delayTimer = NEXT_CARD_DELAY
    end
  else
    if self.level >= 3 and self.level <= 6 then
      self.app.audio:playSequence({ { "sfx", "fout2" }, { "words", card.word } }, { gap = 0.05 })
    else
      self.app.audio:stop()
      self.app.audio:playSfx("fout2")
    end

    self.scores[self.activePlayer] = math.max(0, self.scores[self.activePlayer] - self.timers[self.activePlayer])
    self.phase = "wrong_delay"
    self.delayTimer = WRONG_DELAY
  end

  return true
end

function ElectroGame:keypressed(key)
  if key == "escape" then
    self.app.audio:stop()
    if self.phase == "playing" or self.phase == "next_delay" or self.phase == "wrong_delay" or self.phase == "revealing" then
      self:_enterSettings()
    elseif self.phase == "settings" then
      self.app.scenes:switch("hub")
    end
  end
end

return function(app)
  return ElectroGame.new(app)
end
