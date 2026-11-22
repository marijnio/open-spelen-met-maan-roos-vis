-- Mini-game 6: Luister maar (Turbowoord)

local Assets = require("src.core.assets")
local ConfirmDialog = require("src.core.confirm_dialog")
local Cursor = require("src.core.cursor")
local HotzoneManager = require("src.core.hotzone")

local TurbowoordGame = {}
TurbowoordGame.__index = TurbowoordGame

local LEVEL_ROUNDS = {
  [1] = {
    { audio = "maan", words = { "maan", "naam", "man" } },
    { audio = "sok", words = { "sok", "sop", "bos" } },
    { audio = "vis", words = { "vis", "wis", "vos" } },
    { audio = "ik", words = { "ik", "ki", "is" } },
    { audio = "roos", words = { "roos", "room", "poos" } },
    { audio = "pen", words = { "pen", "ben", "ren" } },
    { audio = "vis", words = { "vis", "mis", "fis" } },
    { audio = "sok", words = { "sok", "rok", "bok" } },
    { audio = "pen", words = { "pen", "den", "men" } },
    { audio = "ik", words = { "ik", "vis", "mis" } }
  },
  [2] = {
    { audio = "teen", words = { "teen", "been", "neet" } },
    { audio = "neus", words = { "neus", "reus", "meus" } },
    { audio = "buik", words = { "buik", "puik", "kiel" } },
    { audio = "oog", words = { "oog", "ook", "og" } },
    { audio = "aap", words = { "aap", "aan", "aab" } },
    { audio = "teen", words = { "teen", "peen", "neen" } },
    { audio = "neus", words = { "neus", "meus", "deuk" } },
    { audio = "buik", words = { "buik", "duik", "ruik" } },
    { audio = "oog", words = { "oog", "aag", "aap" } },
    { audio = "aap", words = { "aap", "paa", "oog" } }
  },
  [3] = {
    { audio = "doos", words = { "doos", "boos", "poos" } },
    { audio = "zeep", words = { "zeep", "peer", "zeer" } },
    { audio = "koek", words = { "koek", "boek", "kook" } },
    { audio = "eet", words = { "eet", "eed", "tee" } },
    { audio = "ijs", words = { "ijs", "eis", "ies" } },
    { audio = "poes", words = { "poes", "koes", "zoek" } },
    { audio = "doos", words = { "doos", "roos", "does" } },
    { audio = "eet", words = { "eet", "oet", "eeb" } },
    { audio = "koek", words = { "koek", "zoek", "koes" } },
    { audio = "zeep", words = { "zeep", "zeer", "zer" } }
  },
  [4] = {
    { audio = "roos", words = { "roos", "doos", "root" } },
    { audio = "aap", words = { "aap", "oop", "aab" } },
    { audio = "poes", words = { "poes", "boes", "poez" } },
    { audio = "maan", words = { "maan", "baan", "naam" } },
    { audio = "pen", words = { "pen", "ben", "ten" } },
    { audio = "buik", words = { "buik", "duik", "kuis" } },
    { audio = "reus", words = { "reus", "neus", "noes" } },
    { audio = "ijs", words = { "ijs", "ijz", "ijd" } },
    { audio = "zeep", words = { "zeep", "seep", "zeeb" } },
    { audio = "doos", words = { "doos", "boot", "doop" } }
  },
  [5] = {
    { audio = "huis", words = { "huis", "nuis", "heis" } },
    { audio = "bos", words = { "bos", "dos", "pos" } },
    { audio = "tak", words = { "tak", "lak", "kat" } },
    { audio = "hek", words = { "hek", "hok", "nek" } },
    { audio = "weg", words = { "weg", "veg", "wep" } },
    { audio = "hut", words = { "hut", "put", "het" } },
    { audio = "huis", words = { "huis", "muis", "nuis" } },
    { audio = "hek", words = { "hek", "bek", "ken" } },
    { audio = "weg", words = { "weg", "leg", "wig" } },
    { audio = "tak", words = { "tak", "kat", "pak" } }
  },
  [6] = {
    { audio = "vuur", words = { "vuur", "wuur", "uur" } },
    { audio = "jas", words = { "jas", "las", "sas" } },
    { audio = "bijl", words = { "bijl", "beil", "deil" } },
    { audio = "reus", words = { "reus", "neus", "deus" } },
    { audio = "riem", words = { "riem", "reim", "rien" } },
    { audio = "hout", words = { "hout", "nout", "houd" } },
    { audio = "vuur", words = { "vuur", "uur", "duur" } },
    { audio = "jas", words = { "jas", "das", "tas" } },
    { audio = "bijl", words = { "bijl", "beil", "pijl" } },
    { audio = "riem", words = { "riem", "kiem", "mier" } }
  },
  [7] = {
    { audio = "duif", words = { "duif", "buiv", "duiv" } },
    { audio = "geit", words = { "geit", "gijt", "teig" } },
    { audio = "uil", words = { "uil", "eil", "lui" } },
    { audio = "pauw", words = { "pauw", "pouw", "dauw" } },
    { audio = "ei", words = { "ei", "ij", "ie" } },
    { audio = "duif", words = { "duif", "fuif", "buif" } },
    { audio = "geit", words = { "geit", "giet", "geid" } },
    { audio = "uil", words = { "uil", "ui", "uit" } },
    { audio = "pauw", words = { "pauw", "gauw", "lauw" } },
    { audio = "ei", words = { "ei", "ui", "ie" } }
  },
  [8] = {
    { audio = "hek", words = { "hek", "nek", "heek" } },
    { audio = "hout", words = { "hout", "houd", "heek" } },
    { audio = "pauw", words = { "pauw", "puaw", "bouw" } },
    { audio = "huis", words = { "huis", "luis", "ruis" } },
    { audio = "weg", words = { "weg", "heg", "zeg" } },
    { audio = "vuur", words = { "vuur", "zuur", "huur" } },
    { audio = "reus", words = { "reus", "keus", "leus" } },
    { audio = "duif", words = { "duif", "duik", "buik" } },
    { audio = "geit", words = { "geit", "meid", "feit" } },
    { audio = "jas", words = { "jas", "klas", "pas" } }
  }
}

local PERM_TABLE = {
  { 1, 2, 3 },
  { 3, 2, 1 },
  { 1, 3, 2 }
}

local EAR_X = 284
local EAR_Y = 44
local EAR_W = 60
local EAR_H = 60

local TILE_SIZE = 180
local TILE_X_START = 30
local TILE_X_STEP = 200
local TILE_Y = 180

local TILE_STRIP_W = 540
local TILE_STRIP_H = 180

local BAR_Y = 412
local BAR_H = 68

local ROUNDS_PER_LEVEL = 10
local TIMER_MAX = 100
local TIMER_TICK_INTERVAL = 0.375
local TILE_REVEAL_INTERVAL = 0.30
local FINISH_DELAY = 2.50
local EAR_HOVER_DWELL = 1.125
local WRONG_PENALTY = 10

local function drawCenteredBold(font, text, x, y, w)
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
  love.graphics.printf(text, x + 1, y, w, "center")
end

local function pointInRect(px, py, rx, ry, rw, rh)
  return px >= rx and px < (rx + rw) and py >= ry and py < (ry + rh)
end

function TurbowoordGame.new(app)
  local self = setmetatable({}, TurbowoordGame)
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
  self.wordFont = love.graphics.newFont(44)

  self.tileQuads = {}
  for i = 1, 3 do
    self.tileQuads[i] = love.graphics.newQuad(
      (i - 1) * TILE_SIZE,
      0,
      TILE_SIZE,
      TILE_SIZE,
      TILE_STRIP_W,
      TILE_STRIP_H
    )
  end

  self.level = 1
  self.players = 1
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.roundIndex = 1
  self.slotToWord = { 1, 2, 3 }
  self.visibleTileCount = 3
  self.phase = "settings"
  self.phaseTimer = 0
  self.earHoverTime = 0
  self.earHoverSpoken = false

  return self
end

function TurbowoordGame:_currentRound()
  local rounds = LEVEL_ROUNDS[self.level] or LEVEL_ROUNDS[1]
  return rounds[self.roundIndex]
end

function TurbowoordGame:_prepareRound()
  local row = love.math.random(1, 3)
  local offset = love.math.random(0, 2)
  local perm = PERM_TABLE[row]
  for slot = 1, 3 do
    local idx = ((offset + slot - 1) % 3) + 1
    self.slotToWord[slot] = perm[idx]
  end
end

function TurbowoordGame:_syncHover()
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:syncHover(vx, vy)
end

function TurbowoordGame:_setOpnieuwEnabled(enabled)
  local opZone = self.hotzones:getById("opnieuw")
  if opZone then
    opZone.enabled = enabled
  end
end

function TurbowoordGame:_addBaseChromeHotzones(onHelpClick, onTerugClick)
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
    end
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
    onClick = onHelpClick
  })
end

function TurbowoordGame:_enterSettings()
  self.phase = "settings"
  self.roundIndex = 1
  self.visibleTileCount = 3
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.phaseTimer = 0
  self.earHoverTime = 0
  self.earHoverSpoken = false
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
      end
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
    end
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
    end
  })

  self:_syncHover()
end

function TurbowoordGame:_startRoundReveal()
  self.phase = "revealing_tiles"
  self.visibleTileCount = 0
  self.phaseTimer = TILE_REVEAL_INTERVAL
  self.timerAccum = 0
  self.earHoverTime = 0
  self.earHoverSpoken = false
end

function TurbowoordGame:_startGame(players)
  self.players = players
  self.activePlayer = love.math.random(1, players)
  self.scores = { 0, 0 }
  self.timers = { TIMER_MAX, (players == 2) and TIMER_MAX or 0 }
  self.timerAccum = 0
  self.roundIndex = 1
  self.earHoverTime = 0
  self.earHoverSpoken = false
  self.app.audio:stop()

  self.hotzones:clear()
  self:_addBaseChromeHotzones(
    function()
      local round = self:_currentRound()
      if round then
        self.app.audio:playSequence(
          {
            { "jantje", "luisphp1" },
            { "words", round.audio }
          }, { gap = 0.25 }
        )
      else
        self.app.audio:clearAndPlay("jantje", "luisphp1")
      end
    end, function()
      self.confirmDialog:open(function()
        self.app.audio:stop()
        self:_enterSettings()
      end)
    end
  )

  self:_syncHover()
  self:_prepareRound()
  self:_startRoundReveal()
end

function TurbowoordGame:_switchTurnOrTimeout()
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

function TurbowoordGame:_enterFinishing()
  self:_setOpnieuwEnabled(false)
  self.phase = "finishing"
  self.phaseTimer = FINISH_DELAY
  self.app.audio:playSfx("gong")
end

function TurbowoordGame:enter(params)
  local lvl = tonumber(params and params.level) or 1
  self.level = math.max(1, math.min(8, math.floor(lvl)))
  self:_enterSettings()
end

function TurbowoordGame:exit()
  self.confirmDialog:close()
  self.hotzones:clear()
  Cursor.set(self.arrowCursor)
end

function TurbowoordGame:_tileSlotAt(vx, vy)
  for slot = 1, self.visibleTileCount do
    local tx = TILE_X_START + (slot - 1) * TILE_X_STEP
    if pointInRect(vx, vy, tx, TILE_Y, TILE_SIZE, TILE_SIZE) then
      return slot
    end
  end
  return nil
end

function TurbowoordGame:_updateCursor(vx, vy)
  if self.hotzones.hoveredId then
    return
  end
  if self.phase == "playing" then
    local onInteractive = pointInRect(vx, vy, EAR_X, EAR_Y, EAR_W, EAR_H)
        or (self:_tileSlotAt(vx, vy) ~= nil)
    Cursor.set(onInteractive and self.handCursor or self.arrowCursor)
  elseif self.phase == "settings" then
    Cursor.set(self.arrowCursor)
  else
    Cursor.set(self.waitCursor)
  end
end

function TurbowoordGame:update(dt)
  if self.confirmDialog:isOpen() then
    self.confirmDialog:update(dt)
    return
  end

  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)

  if self.phase == "revealing_tiles" then
    self.phaseTimer = self.phaseTimer - dt
    while self.phaseTimer <= 0 and self.visibleTileCount < 3 do
      self.visibleTileCount = self.visibleTileCount + 1
      if self.visibleTileCount >= 3 then
        self.phase = "playing"
        self.phaseTimer = 0
        self.timerAccum = 0
        self.earHoverTime = 0
        self.earHoverSpoken = pointInRect(vx, vy, EAR_X, EAR_Y, EAR_W, EAR_H)
        local round = self:_currentRound()
        if round then
          self.app.audio:clearAndPlay("words", round.audio)
        end
        break
      else
        self.phaseTimer = self.phaseTimer + TILE_REVEAL_INTERVAL
      end
    end
  elseif self.phase == "playing" then
    if not self.app.isTouchMode and not self.hotzones.hoveredId and pointInRect(vx, vy, EAR_X, EAR_Y, EAR_W, EAR_H) then
      if not self.earHoverSpoken then
        self.earHoverTime = self.earHoverTime + dt
        if self.earHoverTime >= EAR_HOVER_DWELL and not self.app.audio:isPlaying() then
          self.earHoverSpoken = true
          self.app.audio:clearAndPlay("jantje", "luisherh")
        end
      end
    else
      self.earHoverTime = 0
      self.earHoverSpoken = false
    end

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
  elseif self.phase == "timeout_finish" then
    if not self.app.audio:isPlaying() then
      self:_enterFinishing()
    end
  elseif self.phase == "finishing" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self.app.scenes:switch(
        "highscore", {
          gameId = "turbowoord",
          players = self.players,
          scores = { self.scores[1], self.scores[2] },
          returnTo = "turbowoord",
          returnParams = { level = math.min(8, self.level + 1) }
        }
      )
    end
  end

  self:_updateCursor(vx, vy)
end

function TurbowoordGame:_drawEar()
  local img = Assets.getImage("ui", "ear_8")
  if img then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, EAR_X, EAR_Y)
  else
    love.graphics.setColor(1, 1, 160 / 255, 1)
    love.graphics.rectangle("fill", EAR_X, EAR_Y, EAR_W, EAR_H)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", EAR_X + 0.5, EAR_Y + 0.5, EAR_W - 1, EAR_H - 1)
  end
end

function TurbowoordGame:_drawTile(slot)
  local tx = TILE_X_START + (slot - 1) * TILE_X_STEP
  local ty = TILE_Y
  local wordIdx = self.slotToWord[slot] or slot
  local round = self:_currentRound()
  local word = round and round.words[wordIdx] or ""

  local img = Assets.getImage("turbowrd", "pic_a0")
  local quad = self.tileQuads[wordIdx]
  if img and quad then
    love.graphics.setColor(1, 1, 1, 1)
    local iw, ih = img:getDimensions()
    if iw == TILE_STRIP_W and ih == TILE_STRIP_H then
      love.graphics.draw(img, quad, tx, ty)
    else
      local cellW = iw / 3
      local fallbackQuad = love.graphics.newQuad((wordIdx - 1) * cellW, 0, cellW, ih, iw, ih)
      love.graphics.draw(img, fallbackQuad, tx, ty, 0, TILE_SIZE / cellW, TILE_SIZE / ih)
    end
  else
    love.graphics.setColor(1, 90 / 255, 46 / 255, 1)
    love.graphics.rectangle("fill", tx, ty, TILE_SIZE, TILE_SIZE)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", tx + 0.5, ty + 0.5, TILE_SIZE - 1, TILE_SIZE - 1)
  end

  if word ~= "" then
    local font = self.wordFont
    love.graphics.setFont(font)
    local tw = font:getWidth(word)
    local th = font:getHeight()
    local maxW = TILE_SIZE - 16
    local sx = (tw > maxW and tw > 0) and (maxW / tw) or 1
    local drawX = tx + math.floor((TILE_SIZE - tw * sx) * 0.5)
    local drawY = ty + math.floor((TILE_SIZE - th) * 0.5)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(word, drawX, drawY, 0, sx, 1)
  end
end

function TurbowoordGame:_drawPlayerHud(panelX, playerIndex, isActive)
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

function TurbowoordGame:_drawSettings()
  local bg = Assets.getImage("screens", "mem_0")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(200 / 255, 1, 200 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  self:_drawEar()
  for slot = 1, 3 do
    self:_drawTile(slot)
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

function TurbowoordGame:_drawPlaying()
  local bg = Assets.getImage("screens", "turbow")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(192 / 255, 240 / 255, 248 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  self:_drawEar()
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

function TurbowoordGame:draw()
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

function TurbowoordGame:mousepressed(vx, vy, button)
  if self.confirmDialog:isOpen() then
    return self.confirmDialog:mousepressed(vx, vy, button)
  end

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

  if pointInRect(vx, vy, EAR_X, EAR_Y, EAR_W, EAR_H) then
    self.earHoverSpoken = true
    self.earHoverTime = 0
    self.app.audio:clearAndPlay("words", round.audio)
    return true
  end

  local slot = self:_tileSlotAt(vx, vy)
  if not slot then
    return false
  end

  if self.slotToWord[slot] == 1 then
    self.scores[self.activePlayer] = self.scores[self.activePlayer]
        + self.timers[self.activePlayer]
        + (self.level - 1)
    self.app.audio:clearAndPlay("words", round.audio)
    self.phase = "correct_speak"
  else
    self.scores[self.activePlayer] = math.max(0, self.scores[self.activePlayer] - WRONG_PENALTY)
    self.app.audio:playSfx("fout2")
    self:_switchTurnOrTimeout()
  end

  return true
end

function TurbowoordGame:keypressed(key)
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
  return TurbowoordGame.new(app)
end