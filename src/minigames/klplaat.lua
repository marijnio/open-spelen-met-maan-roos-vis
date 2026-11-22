-- Mini-game 4: Kleurplaat

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local KlplaatGame = {}
KlplaatGame.__index = KlplaatGame

local LEVELS = {
  [1] = { key = "a", word = "pen", letters = { "v", "m", "i", "s", "r", "p", "", "", "", "", "", "", "", "" } },
  [2] = { key = "b", word = "buik", letters = { "t", "aa", "n", "b", "s", "v", "k", "m", "ui", "i", "r", "p", "", "" } },
  [3] = { key = "c", word = "zeep", letters = { "d", "z", "oe", "ee", "i", "k", "m", "r", "v", "s", "ij", "p", "", "" } },
  [4] = { key = "d", word = "vis", letters = { "i", "v", "s", "r", "oo", "m", "p", "b", "n", "aa", "d", "oe", "t", "k" } },
  [5] = { key = "e", word = "hek", letters = { "o", "w", "i", "r", "u", "a", "p", "e", "h", "v", "s", "p", "m", "aa" } },
  [6] = { key = "f", word = "riem", letters = { "v", "uu", "i", "eu", "s", "ou", "p", "aa", "ie", "t", "b", "n", "m", "oe" } },
  [7] = { key = "g", word = "pauw", letters = { "f", "ei", "g", "au", "v", "i", "p", "s", "d", "t", "b", "n", "oo", "aa" } },
  [8] = { key = "h", word = "huis", letters = { "f", "eu", "w", "j", "i", "ei", "v", "uu", "a", "m", "oo", "s", "b", "t" } }
}

local function packRgb(r, g, b)
  return r * 65536 + g * 256 + b
end

local function makePaletteEntry(fillRgb, altRgb)
  return {
    r = fillRgb[1],
    g = fillRgb[2],
    b = fillRgb[3],
    rn = fillRgb[1] / 255,
    gn = fillRgb[2] / 255,
    bn = fillRgb[3] / 255,
    fillPacked = packRgb(fillRgb[1], fillRgb[2], fillRgb[3]),
    altPacked = packRgb(altRgb[1], altRgb[2], altRgb[3])
  }
end

-- Table 1 = brush/swatch colors; Table 2 = reference colors (dark shades use 153 in PIC_*1).
local PALETTE = {
  makePaletteEntry({ 255, 0, 0 }, { 255, 0, 0 }),
  makePaletteEntry({ 0, 255, 0 }, { 0, 255, 0 }),
  makePaletteEntry({ 255, 255, 0 }, { 255, 255, 0 }),
  makePaletteEntry({ 0, 0, 255 }, { 0, 0, 255 }),
  makePaletteEntry({ 255, 0, 255 }, { 255, 0, 255 }),
  makePaletteEntry({ 0, 255, 255 }, { 0, 255, 255 }),
  makePaletteEntry({ 255, 255, 255 }, { 255, 255, 255 }),
  makePaletteEntry({ 128, 0, 0 }, { 153, 0, 0 }),
  makePaletteEntry({ 0, 128, 0 }, { 0, 153, 0 }),
  makePaletteEntry({ 128, 128, 0 }, { 153, 153, 0 }),
  makePaletteEntry({ 0, 0, 128 }, { 0, 0, 153 }),
  makePaletteEntry({ 128, 0, 128 }, { 153, 0, 153 }),
  makePaletteEntry({ 0, 128, 128 }, { 0, 153, 153 }),
  makePaletteEntry({ 128, 128, 128 }, { 153, 153, 128 })
}

local PAINT_CURSOR_BITMAP = {
  "..............................#.",
  ".............................##.",
  "............................##..",
  "...........................##...",
  "..........................#O#...",
  ".........................#O#....",
  "........................#O#.....",
  ".......................#O#......",
  "......................#O#.......",
  ".....................#O#........",
  "....................#O#.........",
  "...................#O#..........",
  "..................#O#...........",
  ".................#O#............",
  "................#O#.............",
  "...............#O#..............",
  "..............#OO#..............",
  ".............#OO#...............",
  "............#OO#................",
  "...........#OO#.................",
  "..........#OO#..................",
  ".........#OO#...................",
  "........#OO#....................",
  ".....####O#.....................",
  "....######......................",
  "...######.......................",
  "..#######.......................",
  "..######........................",
  ".#####..........................",
  ".##.............................",
  ".#..............................",
  "................................"
}

local PIC_X = 8
local PIC_Y = 4
local PIC_W = 520
local PIC_H = 392

local SAMPLE_X = 544
local SAMPLE_Y = 6
local SAMPLE_W = 88
local SAMPLE_H = 66

local PREVIEW_X = 545
local PREVIEW_Y = 174
local PREVIEW_W = 87
local PREVIEW_H = 21

local PAL_X_LEFT = 542
local PAL_X_RIGHT = 590
local PAL_Y_START = 203
local PAL_Y_STEP = 28
local PAL_W = 44
local PAL_H = 23

local BAR_Y = 412
local BAR_H = 68

local CLOCK_RECT_1P = { x = 330, y = 416, w = 45, h = 60 }
local CLOCK_RECTS_2P = {
  { x = 210, y = 416, w = 45, h = 60 },
  { x = 394, y = 416, w = 45, h = 60 }
}

local TIMER_MAX = 100
local SAMPLE_HOVER_DWELL = 1.0
local REGION_POINTS = 10
local BONUS_WAIT_DELAY = 1.0
local FINISH_GONG_DELAY = 1.5
local FINISH_SHOW_DELAY = 1.5
local REVEAL_DELAY = 1.5

local BLACK_PACKED = 0
local DEFAULT_GREY_PACKED = packRgb(204, 204, 204)

local function pointInRect(px, py, rx, ry, rw, rh)
  return px >= rx and px < (rx + rw) and py >= ry and py < (ry + rh)
end

local function drawCenteredBold(font, text, x, y, w)
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
  love.graphics.printf(text, x + 1, y, w, "center")
end

local function paletteRect(slot)
  local zero = slot - 1
  local col = math.floor(zero / 7)
  local row = zero % 7
  local x = (col == 0) and PAL_X_LEFT or PAL_X_RIGHT
  local y = PAL_Y_START + row * PAL_Y_STEP
  return x, y, PAL_W, PAL_H
end

local function previewDurationForLevel(level)
  return 2.5 - (level - 1) * 0.1
end

local function timerTickIntervalForLevel(level)
  return (level - 1 + 8) * 0.125
end

local function pixelToPackedRgb(data, x, y)
  local r, g, b = data:getPixel(x, y)
  local ri = math.floor(r * 255 + 0.5)
  local gi = math.floor(g * 255 + 0.5)
  local bi = math.floor(b * 255 + 0.5)
  return packRgb(ri, gi, bi)
end

function KlplaatGame.new(app)
  local self = setmetatable({}, KlplaatGame)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.handlesEscape = true

  self.handCursor = love.mouse.getSystemCursor("hand")
  self.arrowCursor = love.mouse.getSystemCursor("arrow")
  local okWait, waitCur = pcall(love.mouse.getSystemCursor, "wait")
  self.waitCursor = (okWait and waitCur) or self.arrowCursor
  self.paintCursor = self:_createPaintCursor()

  self.levelFont = love.graphics.newFont(16)
  self.badgeFont = love.graphics.newFont(12)
  self.scoreFont = love.graphics.newFont(15)
  self.letterFont = love.graphics.newFont(14)

  local totalPixels = PIC_W * PIC_H
  self.refPixels = {}
  self.canvasPixels = {}
  self.visitMark = {}
  for i = 1, totalPixels do
    self.refPixels[i] = 0
    self.canvasPixels[i] = 0
    self.visitMark[i] = 0
  end
  self.visitGen = 0
  self.stackX = {}
  self.stackY = {}

  self.canvasData = nil
  self.canvasImage = nil
  self.greyColor = DEFAULT_GREY_PACKED

  self.level = 1
  self.players = 1
  self.activePlayer = 1
  self.scores = { 0, 0 }
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.selectedColor = nil
  self.selfMode = false
  self.completed = false
  self.phase = "settings"
  self.phaseTimer = 0
  self.sampleHoverTime = 0
  self.sampleHoverSpoken = false

  return self
end

function KlplaatGame:_createPaintCursor()
  local ok, data = pcall(love.image.newImageData, 32, 32)
  if not ok or not data then
    return self.handCursor
  end
  for y = 0, 31 do
    local row = PAINT_CURSOR_BITMAP[y + 1] or ""
    for x = 0, 31 do
      local ch = row:sub(x + 1, x + 1)
      if ch == "#" then
        data:setPixel(x, y, 0, 0, 0, 1)
      elseif ch == "O" then
        data:setPixel(x, y, 1, 1, 1, 1)
      else
        data:setPixel(x, y, 0, 0, 0, 0)
      end
    end
  end
  local okCur, cur = pcall(love.mouse.newCursor, data, 1, 30)
  if okCur and cur then
    return cur
  end
  return self.handCursor
end

function KlplaatGame:_currentLevel()
  return LEVELS[self.level] or LEVELS[1]
end

function KlplaatGame:_syncHover()
  local vx, vy = self.app.viewport:screenToVirtual(love.mouse.getPosition())
  self.hotzones:syncHover(vx, vy)
end

function KlplaatGame:_setOpnieuwEnabled(enabled)
  local opZone = self.hotzones:getById("opnieuw")
  if opZone then
    opZone.enabled = enabled
  end
end

function KlplaatGame:_addBaseChromeHotzones(onHelpClick)
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

function KlplaatGame:_releaseCanvas()
  if self.canvasImage then
    self.canvasImage:release()
    self.canvasImage = nil
  end
  self.canvasData = nil
end

function KlplaatGame:_loadLevelCanvas()
  local lvlData = self:_currentLevel()
  local refSrc = Assets.getImageData("klplaat", "pic_" .. lvlData.key .. "1")
  local greySrc = Assets.getImageData("klplaat", "pic_" .. lvlData.key .. "_")
  if not refSrc or not greySrc then
    self:_releaseCanvas()
    return false
  end

  local cloned = greySrc:clone()
  self.canvasData = cloned

  if self.canvasImage and self.canvasImage:getWidth() == PIC_W and self.canvasImage:getHeight() == PIC_H then
    self.canvasImage:replacePixels(cloned)
  else
    if self.canvasImage then
      self.canvasImage:release()
    end
    self.canvasImage = love.graphics.newImage(cloned)
    self.canvasImage:setFilter(Assets.filterMode, Assets.filterMode)
  end

  local idx = 1
  for y = 0, PIC_H - 1 do
    for x = 0, PIC_W - 1 do
      self.refPixels[idx] = pixelToPackedRgb(refSrc, x, y)
      self.canvasPixels[idx] = pixelToPackedRgb(cloned, x, y)
      idx = idx + 1
    end
  end

  local sampleGrey = self.canvasPixels[2 * PIC_W + 2 + 1]
  self.greyColor = (sampleGrey ~= BLACK_PACKED) and sampleGrey or DEFAULT_GREY_PACKED
  return true
end

-- Border-bounded scanline flood fill (stops at BLACK_PACKED only) so 1px grey
-- bridges inside guide letters flow through automatically, matching GDI FloodFill.
function KlplaatGame:_floodFill(startX, startY, pal)
  if not self.canvasData or not self.canvasImage then
    return false
  end
  if startX < 0 or startX >= PIC_W or startY < 0 or startY >= PIC_H then
    return false
  end

  local startIdx = startY * PIC_W + startX + 1
  local startColor = self.canvasPixels[startIdx]
  if startColor == BLACK_PACKED or startColor == pal.fillPacked then
    return false
  end

  self.visitGen = self.visitGen + 1
  local gen = self.visitGen
  local pixels = self.canvasPixels
  local mark = self.visitMark
  local stackX = self.stackX
  local stackY = self.stackY
  local data = self.canvasData
  local fillPacked = pal.fillPacked
  local rn, gn, bn = pal.rn, pal.gn, pal.bn

  local sp = 1
  stackX[1] = startX
  stackY[1] = startY

  while sp > 0 do
    local sx = stackX[sp]
    local sy = stackY[sp]
    sp = sp - 1

    local rowBase = sy * PIC_W + 1
    if mark[rowBase + sx] ~= gen and pixels[rowBase + sx] ~= BLACK_PACKED then
      local lx = sx
      while lx > 0 do
        local nIdx = rowBase + (lx - 1)
        if pixels[nIdx] == BLACK_PACKED or mark[nIdx] == gen then
          break
        end
        lx = lx - 1
      end

      local rx = sx
      while rx < PIC_W - 1 do
        local nIdx = rowBase + (rx + 1)
        if pixels[nIdx] == BLACK_PACKED or mark[nIdx] == gen then
          break
        end
        rx = rx + 1
      end

      for cx = lx, rx do
        local idx = rowBase + cx
        mark[idx] = gen
        pixels[idx] = fillPacked
        data:setPixel(cx, sy, rn, gn, bn, 1)
      end

      for dy = -1, 1, 2 do
        local ny = sy + dy
        if ny >= 0 and ny < PIC_H then
          local nRowBase = ny * PIC_W + 1
          local inSpan = false
          for cx = lx, rx do
            local nIdx = nRowBase + cx
            local paintable = (pixels[nIdx] ~= BLACK_PACKED) and (mark[nIdx] ~= gen)
            if paintable and not inSpan then
              sp = sp + 1
              stackX[sp] = cx
              stackY[sp] = ny
              inSpan = true
            elseif not paintable then
              inSpan = false
            end
          end
        end
      end
    end
  end

  self.canvasImage:replacePixels(data)
  return true
end

function KlplaatGame:_isPictureComplete()
  if not self.canvasData then
    return false
  end
  local grey = self.greyColor
  local pixels = self.canvasPixels
  for y = 1, PIC_H - 2 do
    local rowBase = y * PIC_W + 1
    for x = 1, PIC_W - 2 do
      if pixels[rowBase + x] == grey then
        return false
      end
    end
  end
  return true
end

function KlplaatGame:_selectColor(slot, playAudio)
  if slot < 1 or slot > #PALETTE then
    return
  end
  self.selectedColor = slot
  if playAudio then
    local letter = self:_currentLevel().letters[slot]
    if letter and letter ~= "" then
      self.app.audio:clearAndPlay("words", letter)
    end
  end
end

function KlplaatGame:_enterSettings()
  self.phase = "settings"
  self.timers = { 0, 0 }
  self.timerAccum = 0
  self.phaseTimer = 0
  self.selectedColor = nil
  self.selfMode = false
  self.completed = false
  self.sampleHoverTime = 0
  self.sampleHoverSpoken = false
  self.app.audio:stop()

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

function KlplaatGame:_startGame(players)
  self.players = players
  self.activePlayer = love.math.random(1, players)
  self.scores = { 0, 0 }
  self.timers = { TIMER_MAX, (players == 2) and TIMER_MAX or 0 }
  self.timerAccum = 0
  self.selectedColor = nil
  self.selfMode = false
  self.completed = false
  self.sampleHoverTime = 0
  self.sampleHoverSpoken = false
  self.app.audio:stop()

  self:_loadLevelCanvas()

  self.hotzones:clear()
  self:_addBaseChromeHotzones(function()
    self.app.audio:clearAndPlay("jantje", "klpsphp1")
  end)

  self.hotzones:add({
    id = "opnieuw",
    label = "Opnieuw",
    x = 572,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "opnieuw" },
    hoverImage = { "ui", "opnieu2" },
    hoverVo = { "jantje", "opnieuw" },
    onClick = function()
      self:_triggerOpnieuw()
    end
  })

  -- Sync hover immediately so start_1p -> opnieuw at (572, 416) does not trigger hoverVo.
  self:_syncHover()

  local lvlData = self:_currentLevel()
  self.phase = "preview"
  self.phaseTimer = previewDurationForLevel(self.level)
  self.app.audio:clearAndPlay("words", lvlData.word)
end

function KlplaatGame:_triggerOpnieuw()
  if (self.phase ~= "preview" and self.phase ~= "playing") or self.completed then
    return
  end
  self.app.audio:stop()
  self:_setOpnieuwEnabled(false)
  self.phase = "revealing"
  self.phaseTimer = REVEAL_DELAY
end

function KlplaatGame:_enterFinishing()
  self:_setOpnieuwEnabled(false)
  self.phase = "finishing_gong"
  self.phaseTimer = FINISH_GONG_DELAY
  self.app.audio:playSfx("gong")
end

function KlplaatGame:_completeLevel()
  self.completed = true
  self:_setOpnieuwEnabled(false)
  if not self.selfMode and self.players == 1 then
    self.scores[1] = self.scores[1] + self.timers[1]
    self.phase = "bonus_wait"
    self.phaseTimer = BONUS_WAIT_DELAY
  else
    self:_enterFinishing()
  end
end

function KlplaatGame:_switchTurnOrTimeout()
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

function KlplaatGame:_paletteSlotAt(vx, vy)
  for slot = 1, #PALETTE do
    local x, y, w, h = paletteRect(slot)
    if pointInRect(vx, vy, x, y, w, h) then
      return slot
    end
  end
  return nil
end

function KlplaatGame:_isInClock(vx, vy)
  if self.players == 1 then
    local r = CLOCK_RECT_1P
    return pointInRect(vx, vy, r.x, r.y, r.w, r.h)
  end
  for _, r in ipairs(CLOCK_RECTS_2P) do
    if pointInRect(vx, vy, r.x, r.y, r.w, r.h) then
      return true
    end
  end
  return false
end

function KlplaatGame:_updateCursor(vx, vy)
  if self.hotzones.hoveredId then
    return
  end
  if self.phase == "playing" then
    if pointInRect(vx, vy, PIC_X, PIC_Y, PIC_W, PIC_H) then
      love.mouse.setCursor(self.paintCursor)
    elseif pointInRect(vx, vy, SAMPLE_X, SAMPLE_Y, SAMPLE_W, SAMPLE_H)
        or self:_paletteSlotAt(vx, vy) ~= nil
        or self:_isInClock(vx, vy) then
      love.mouse.setCursor(self.handCursor)
    else
      love.mouse.setCursor(self.arrowCursor)
    end
  elseif self.phase == "settings" then
    love.mouse.setCursor(self.arrowCursor)
  else
    love.mouse.setCursor(self.waitCursor)
  end
end

function KlplaatGame:enter(params)
  local lvl = tonumber(params and params.level) or 1
  self.level = math.max(1, math.min(8, math.floor(lvl)))
  self:_enterSettings()
end

function KlplaatGame:exit()
  self.hotzones:clear()
  self:_releaseCanvas()
  love.mouse.setCursor(self.arrowCursor)
end

function KlplaatGame:update(dt)
  local vx, vy = self.app.viewport:screenToVirtual(love.mouse.getPosition())
  self.hotzones:update(vx, vy)

  if self.phase == "preview" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self.phase = "playing"
      self.phaseTimer = 0
      self.timerAccum = 0
      self.sampleHoverTime = 0
      self.sampleHoverSpoken = pointInRect(vx, vy, SAMPLE_X, SAMPLE_Y, SAMPLE_W, SAMPLE_H)
      self:_selectColor(1, true)
    end
  elseif self.phase == "playing" then
    if not self.hotzones.hoveredId and pointInRect(vx, vy, SAMPLE_X, SAMPLE_Y, SAMPLE_W, SAMPLE_H) then
      if not self.sampleHoverSpoken then
        self.sampleHoverTime = self.sampleHoverTime + dt
        if self.sampleHoverTime >= SAMPLE_HOVER_DWELL and not self.app.audio:isPlaying() then
          self.sampleHoverSpoken = true
          self.app.audio:clearAndPlay("jantje", "klpzelf")
        end
      end
    else
      self.sampleHoverTime = 0
      self.sampleHoverSpoken = false
    end

    if not self.selfMode then
      local tickInterval = timerTickIntervalForLevel(self.level)
      self.timerAccum = self.timerAccum + dt
      while self.timerAccum >= tickInterval do
        self.timerAccum = self.timerAccum - tickInterval
        if self.timers[self.activePlayer] > 0 then
          self.timers[self.activePlayer] = self.timers[self.activePlayer] - 1
        end
        if self.timers[self.activePlayer] <= 0 then
          self.timers[self.activePlayer] = 0
          self:_switchTurnOrTimeout()
          break
        end
      end
    end
  elseif self.phase == "bonus_wait" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self:_enterFinishing()
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
  elseif self.phase == "finishing_gong" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self.phase = "finishing_show"
      self.phaseTimer = FINISH_SHOW_DELAY
    end
  elseif self.phase == "finishing_show" then
    self.phaseTimer = self.phaseTimer - dt
    if self.phaseTimer <= 0 then
      self.app.scenes:switch(
        "highscore", {
          gameId = "klplaat",
          players = self.players,
          scores = { self.scores[1], self.scores[2] },
          returnTo = "klplaat",
          returnParams = { level = math.min(8, self.level + 1) }
        }
      )
    end
  end

  self:_updateCursor(vx, vy)
end

function KlplaatGame:_drawOutlinedLetter(text, x, y, w, h)
  if not text or text == "" then
    return
  end
  local font = self.letterFont
  love.graphics.setFont(font)
  local tw = font:getWidth(text)
  local th = font:getHeight()
  local tx = x + math.floor((w - tw) * 0.5)
  local ty = y + math.floor((h - th) * 0.5)

  love.graphics.setColor(1, 1, 0, 1)
  love.graphics.print(text, tx - 1, ty)
  love.graphics.print(text, tx + 1, ty)
  love.graphics.print(text, tx, ty - 1)
  love.graphics.print(text, tx, ty + 1)

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(text, tx, ty)
end

function KlplaatGame:_drawSwatch(x, y, w, h, pal, letter)
  love.graphics.setColor(pal.rn, pal.gn, pal.bn, 1)
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)

  local x1 = x + 1.5
  local y1 = y + 1.5
  local x2 = x + w - 1.5
  local y2 = y + h - 1.5
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.line(x1, y2, x1, y1, x2, y1)
  love.graphics.setColor(128 / 255, 128 / 255, 128 / 255, 1)
  love.graphics.line(x2, y1 + 1, x2, y2, x1 + 1, y2)

  self:_drawOutlinedLetter(letter, x + 2, y + 2, w - 4, h - 4)
end

function KlplaatGame:_drawSample()
  local lvlData = self:_currentLevel()
  local key = "spic_" .. lvlData.key .. (self.selfMode and "_" or "1")
  local img = Assets.getImage("klplaat", key)
  if img then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, SAMPLE_X, SAMPLE_Y)
  else
    love.graphics.setColor(204 / 255, 204 / 255, 204 / 255, 1)
    love.graphics.rectangle("fill", SAMPLE_X, SAMPLE_Y, SAMPLE_W, SAMPLE_H)
  end
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", SAMPLE_X + 0.5, SAMPLE_Y + 0.5, SAMPLE_W - 1, SAMPLE_H - 1)
end

function KlplaatGame:_drawPlayerHud(panelX, playerIndex, isActive)
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

function KlplaatGame:_drawSettings()
  local bg = Assets.getImage("screens", "mem_0")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  else
    love.graphics.setColor(200 / 255, 1, 200 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)
  end

  local lvlData = self:_currentLevel()
  local previewImg = Assets.getImage("klplaat", "pic_" .. lvlData.key .. "1")
  if previewImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(previewImg, PIC_X, PIC_Y)
  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", PIC_X, PIC_Y, PIC_W, PIC_H)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", PIC_X + 0.5, PIC_Y + 0.5, PIC_W - 1, PIC_H - 1)
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

function KlplaatGame:_drawPlaying()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, 640, BAR_Y)

  local lvlData = self:_currentLevel()
  local showColored = (self.phase == "preview" or self.phase == "revealing" or self.phase == "finishing_show")
  if showColored then
    local picImg = Assets.getImage("klplaat", "pic_" .. lvlData.key .. "1")
    if picImg then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(picImg, PIC_X, PIC_Y)
    end
  elseif self.canvasImage then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvasImage, PIC_X, PIC_Y)
  end

  self:_drawSample()

  for slot = 1, #PALETTE do
    local x, y, w, h = paletteRect(slot)
    self:_drawSwatch(x, y, w, h, PALETTE[slot], lvlData.letters[slot])
  end

  if self.selectedColor then
    local pal = PALETTE[self.selectedColor]
    if pal then
      self:_drawSwatch(
        PREVIEW_X,
        PREVIEW_Y,
        PREVIEW_W,
        PREVIEW_H,
        pal,
        lvlData.letters[self.selectedColor]
      )
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

function KlplaatGame:draw()
  if self.phase == "settings" then
    self:_drawSettings()
  else
    self:_drawPlaying()
  end

  love.graphics.setColor(1, 1, 1, 1)
  self.hotzones:draw(self.app.debugHotzones)
end

function KlplaatGame:mousepressed(vx, vy, button)
  if self.hotzones:mousepressed(vx, vy, button) then
    return true
  end

  if self.phase ~= "playing" or button ~= 1 then
    return false
  end

  if pointInRect(vx, vy, SAMPLE_X, SAMPLE_Y, SAMPLE_W, SAMPLE_H) then
    self.selfMode = not self.selfMode
    self.timerAccum = 0
    self.sampleHoverSpoken = true
    self.app.audio:playSfx("klik")
    return true
  end

  local palSlot = self:_paletteSlotAt(vx, vy)
  if palSlot then
    self:_selectColor(palSlot, true)
    return true
  end

  if pointInRect(vx, vy, PIC_X, PIC_Y, PIC_W, PIC_H) then
    local pal = self.selectedColor and PALETTE[self.selectedColor]
    if not pal then
      return false
    end

    local imgX = math.floor(vx - PIC_X)
    local imgY = math.floor(vy - PIC_Y)
    if imgX < 0 or imgX >= PIC_W or imgY < 0 or imgY >= PIC_H then
      return false
    end

    local idx = imgY * PIC_W + imgX + 1
    local currentColor = self.canvasPixels[idx]
    if currentColor == BLACK_PACKED then
      return true
    end

    if not self.selfMode then
      local refColor = self.refPixels[idx]
      if refColor == BLACK_PACKED then
        return true
      end
      if refColor == pal.fillPacked or refColor == pal.altPacked then
        if currentColor == self.greyColor then
          self.scores[self.activePlayer] = self.scores[self.activePlayer] + REGION_POINTS
        end
        if self:_floodFill(imgX, imgY, pal) and self:_isPictureComplete() then
          self:_completeLevel()
        end
      else
        self.app.audio:playSfx("fout2")
        self.scores[self.activePlayer] = math.max(0, self.scores[self.activePlayer] - 1)
        if self.players == 2 then
          local other = (self.activePlayer == 1) and 2 or 1
          if self.timers[other] > 0 then
            self.activePlayer = other
            self.timerAccum = 0
          end
        end
      end
    else
      self:_floodFill(imgX, imgY, pal)
    end
    return true
  end

  if self:_isInClock(vx, vy) then
    if self:_isPictureComplete() then
      self:_completeLevel()
    else
      self.app.audio:playSfx("fout2")
    end
    return true
  end

  return false
end

function KlplaatGame:keypressed(key)
  if key == "escape" then
    self.app.audio:stop()
    if self.phase == "settings" then
      self.app.scenes:switch("hub")
    elseif self.phase == "preview" or self.phase == "playing" or self.phase == "revealing" then
      self:_enterSettings()
    end
  end
end

return function(app)
  return KlplaatGame.new(app)
end